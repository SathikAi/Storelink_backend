import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/business_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/entities/business_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../core/services/debug_log_service.dart';

// Returns true if user registered within the last 30 days (free trial window).
bool _isInTrialPeriod(DateTime registeredAt) {
  return DateTime.now().difference(registeredAt).inDays < 30;
}

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
}

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthStatus _status = AuthStatus.initial;
  UserEntity? _user;
  BusinessEntity? _business;
  String? _accessToken;
  String? _error;
  bool _processingGoogleCallback = false;
  Completer<Map<String, dynamic>>? _googleCallbackCompleter;
  StreamSubscription<AuthState>? _googleOAuthSub;

  AuthProvider(this._authRepository);

  AuthStatus get status => _status;
  UserEntity? get user => _user;
  BusinessEntity? get business => _business;
  String? get accessToken => _accessToken;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isProcessingGoogleCallback => _processingGoogleCallback;
  Future<Map<String, dynamic>>? get googleCallbackFuture => _googleCallbackCompleter?.future;

  /// True if on PAID plan OR within 30-day free trial from registration.
  bool get isPro {
    if (_business?.plan.toUpperCase() == 'PAID') return true;
    if (_user != null && _isInTrialPeriod(_user!.createdAt)) return true;
    return false;
  }

  bool get isOnTrial =>
      _business?.plan.toUpperCase() != 'PAID' &&
      _user != null &&
      _isInTrialPeriod(_user!.createdAt);

  int get trialDaysLeft => _user == null
      ? 0
      : (30 - DateTime.now().difference(_user!.createdAt).inDays).clamp(0, 30);

  Future<void> checkAuthStatus() async {
    _status = AuthStatus.loading;
    notifyListeners();

    final isAuth = await _authRepository.isAuthenticated();
    if (!isAuth) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      final result = await _authRepository.getCurrentUser();
      if (result != null) {
        _user = result.user;
        _business = result.business;
        _accessToken = await _authRepository.getAccessToken();
        _status = AuthStatus.authenticated;
      } else {
        // getCurrentUser returned null — either the token is invalid or it was a network error.
        // If the Dio interceptor cleared tokens (refresh also failed), isAuthenticated() returns false → logout.
        // If tokens still exist, this was a transient error → keep authenticated.
        final stillHasToken = await _authRepository.isAuthenticated();
        if (!stillHasToken) {
          _status = AuthStatus.unauthenticated;
        } else {
          _accessToken = await _authRepository.getAccessToken();
          _status = AuthStatus.authenticated;
        }
      }
    } on DioException catch (e) {
      // DioException that escaped getCurrentUser (shouldn't happen often, but guard anyway).
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.unknown) {
        _accessToken = await _authRepository.getAccessToken();
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> register({
    required String phone,
    required String password,
    required String fullName,
    String? email,
    required String businessName,
    required String businessPhone,
    String? businessEmail,
    String? referralCode,
  }) async {
    try {
      _status = AuthStatus.loading;
      _error = null;
      notifyListeners();

      final result = await _authRepository.register(
        phone: phone,
        password: password,
        fullName: fullName,
        email: email,
        businessName: businessName,
        businessPhone: businessPhone,
        businessEmail: businessEmail,
        referralCode: referralCode,
      );

      final token = result.tokens?.accessToken;
      if (token == null) {
        _error = 'Authentication failed: no token received';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
      _user = result.user;
      _business = result.business;
      _accessToken = token;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _friendlyError(e);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String phone,
    required String password,
  }) async {
    try {
      _status = AuthStatus.loading;
      _error = null;
      notifyListeners();

      final result = await _authRepository.login(
        phone: phone,
        password: password,
      );

      final token = result.tokens?.accessToken;
      if (token == null) {
        _error = 'Authentication failed: no token received';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
      _user = result.user;
      _business = result.business;
      _accessToken = token;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _friendlyError(e);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  /// Returns:
  ///   - `{'status': 'logged_in'}` → user existed, navigate to dashboard
  ///   - `{'status': 'needs_registration', 'email': ..., 'name': ..., 'token': ...}` → new user
  ///   - `{'status': 'error', 'message': ...}` → failure
  Future<Map<String, dynamic>> loginWithGoogle() async {
    _processingGoogleCallback = true;
    _googleCallbackCompleter = Completer<Map<String, dynamic>>();

    try {
      _status = AuthStatus.loading;
      _error = null;
      notifyListeners();

      final supabase = Supabase.instance.client;

      if (kIsWeb) {
        DebugLog.i('GoogleAuth', 'web: initiating OAuth redirect');
        await supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: '${const String.fromEnvironment('WEB_APP_URL', defaultValue: 'https://storelink.sbs')}/auth-callback',
        );
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        final result = {'status': 'redirect'};
        if (!_googleCallbackCompleter!.isCompleted) _googleCallbackCompleter!.complete(result);
        return result;
      }

      // Mobile: listen for auth session from Supabase (direct custom-scheme path).
      // supabase_flutter handles the PKCE exchange internally via app_links.
      // handleWebRedirectToken() can also complete _googleCallbackCompleter externally
      // when the web-to-app bridge delivers tokens via com.storelink.app://auth-callback?access_token=
      DebugLog.i('GoogleAuth', 'mobile: attaching auth listener');
      _googleOAuthSub = supabase.auth.onAuthStateChange.listen((data) {
        final isAuth = data.event == AuthChangeEvent.signedIn ||
            data.event == AuthChangeEvent.tokenRefreshed;
        if (isAuth && data.session != null) {
          DebugLog.i('GoogleAuth', 'oauth-event-received: ${data.event}');
          _processGoogleSession(data.session!);
        }
      });

      DebugLog.i('GoogleAuth', 'browser-launching');
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.storelink.app://auth-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      // Wait for the completer — completed by either:
      //   • _processGoogleSession (direct custom-scheme path: signedIn event fires)
      //   • handleWebRedirectToken (web-to-app bridge: access_token delivered via deep link)
      final result = await _googleCallbackCompleter!.future.timeout(
        const Duration(minutes: 3),
        onTimeout: () {
          DebugLog.i('GoogleAuth', 'loginWithGoogle: 3-min timeout');
          _status = AuthStatus.unauthenticated;
          notifyListeners();
          return {'status': 'cancelled'};
        },
      );
      return result;
    } catch (e) {
      DebugLog.i('GoogleAuth', 'loginWithGoogle error: $e');
      _error = _friendlyError(e);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      final result = {'status': 'error', 'message': _error};
      if (!(_googleCallbackCompleter?.isCompleted ?? true)) {
        _googleCallbackCompleter!.complete(result);
      }
      return result;
    } finally {
      _googleOAuthSub?.cancel();
      _googleOAuthSub = null;
      _processingGoogleCallback = false;
    }
  }

  /// Called by the onAuthStateChange listener (direct custom-scheme path).
  Future<void> _processGoogleSession(Session session) async {
    if (_googleCallbackCompleter?.isCompleted ?? true) return;
    try {
      DebugLog.i('GoogleAuth', 'backend-call-start (session path)');
      final data = await _authRepository.googleAuth(session.accessToken);
      DebugLog.i('GoogleAuth', 'backend-call-end: needs_registration=${data['needs_registration']}');
      final result = _buildGoogleResult(data, session.accessToken);
      _applyGoogleResult(data);
      if (!(_googleCallbackCompleter?.isCompleted ?? true)) {
        _googleCallbackCompleter!.complete(result);
      }
    } catch (e) {
      DebugLog.i('GoogleAuth', 'backend error: $e');
      _error = _friendlyError(e);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      if (!(_googleCallbackCompleter?.isCompleted ?? true)) {
        _googleCallbackCompleter!.complete({'status': 'error', 'message': _error});
      }
    }
  }

  /// Called by _GoogleAuthCallbackScreen when it receives access_token via the
  /// web-to-app bridge (com.storelink.app://auth-callback?access_token=xxx).
  /// Works whether or not loginWithGoogle() is still in flight.
  Future<Map<String, dynamic>> handleWebRedirectToken(String accessToken) async {
    DebugLog.i('GoogleAuth', 'handleWebRedirectToken: processingCallback=$_processingGoogleCallback');
    try {
      final data = await _authRepository.googleAuth(accessToken);
      final result = _buildGoogleResult(data, accessToken);
      _applyGoogleResult(data);
      // Complete the in-flight loginWithGoogle() if it's still waiting.
      if (!(_googleCallbackCompleter?.isCompleted ?? true)) {
        _googleCallbackCompleter!.complete(result);
      }
      return result;
    } catch (e) {
      _error = _friendlyError(e);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      final result = {'status': 'error', 'message': _error};
      if (!(_googleCallbackCompleter?.isCompleted ?? true)) {
        _googleCallbackCompleter!.complete(result);
      }
      return result;
    }
  }

  Map<String, dynamic> _buildGoogleResult(Map<String, dynamic> data, String fallbackToken) {
    if (data['needs_registration'] == true) {
      DebugLog.i('GoogleAuth', 'needs-registration-detected');
      return {
        'status': 'needs_registration',
        'email': data['google_email'] ?? '',
        'name': data['google_name'] ?? '',
        'token': data['supabase_token'] ?? fallbackToken,
      };
    }
    DebugLog.i('GoogleAuth', 'logged_in successfully');
    return {'status': 'logged_in'};
  }

  void _applyGoogleResult(Map<String, dynamic> data) {
    if (data['needs_registration'] == true) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    _user = data['user'] != null ? _parseUser(data) : null;
    _business = data['business'] != null ? _parseBusiness(data) : null;
    _accessToken = data['tokens']?['access_token'];
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<Map<String, dynamic>> loginWithGoogleToken(String supabaseToken) async {
    if (_processingGoogleCallback) {
      DebugLog.i('GoogleAuth', 'loginWithGoogleToken: callback in flight, awaiting completer');
      return await _googleCallbackCompleter!.future;
    }

    try {
      _status = AuthStatus.loading;
      _error = null;
      notifyListeners();

      final data = await _authRepository.googleAuth(supabaseToken);

      if (data['needs_registration'] == true) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return {
          'status': 'needs_registration',
          'email': data['google_email'] ?? '',
          'name': data['google_name'] ?? '',
          'token': supabaseToken,
        };
      }

      _user = data['user'] != null ? _parseUser(data) : null;
      _business = data['business'] != null ? _parseBusiness(data) : null;
      _accessToken = data['tokens']?['access_token'];
      _status = AuthStatus.authenticated;
      notifyListeners();
      return {'status': 'logged_in'};
    } catch (e) {
      _error = _friendlyError(e);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return {'status': 'error', 'message': _error};
    }
  }

  Future<bool> googleCompleteRegistration({
    required String supabaseToken,
    required String phone,
    required String businessName,
    String? businessPhone,
  }) async {
    try {
      _status = AuthStatus.loading;
      _error = null;
      notifyListeners();

      final result = await _authRepository.googleCompleteRegistration(
        supabaseToken: supabaseToken,
        phone: phone,
        businessName: businessName,
        businessPhone: businessPhone,
      );

      final token = result.tokens?.accessToken;
      if (token == null) {
        _error = 'Authentication failed: no token received';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
      _user = result.user;
      _business = result.business;
      _accessToken = token;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _friendlyError(e);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  UserEntity? _parseUser(Map<String, dynamic> data) {
    try {
      final u = data['user'] as Map<String, dynamic>;
      return UserEntity(
        uuid: u['uuid'] ?? '',
        phone: u['phone'] ?? '',
        email: u['email'],
        fullName: u['full_name'] ?? '',
        role: u['role'] ?? '',
        isActive: u['is_active'] ?? true,
        isVerified: u['is_verified'] ?? false,
        createdAt: DateTime.tryParse(u['created_at'] ?? '') ?? DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  BusinessModel? _parseBusiness(Map<String, dynamic> data) {
    try {
      return BusinessModel.fromJson(data['business'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<bool> sendOtp({
    required String phone,
    required String purpose,
  }) async {
    try {
      _error = null;
      await _authRepository.sendOtp(phone: phone, purpose: purpose);
      return true;
    } catch (e) {
      _error = _friendlyError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp({
    required String phone,
    required String otpCode,
    required String purpose,
  }) async {
    try {
      _status = AuthStatus.loading;
      _error = null;
      notifyListeners();

      final result = await _authRepository.verifyOtp(
        phone: phone,
        otpCode: otpCode,
        purpose: purpose,
      );

      final token = result.tokens?.accessToken;
      if (token == null) {
        _error = 'Authentication failed: no token received';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
      _user = result.user;
      _business = result.business;
      _accessToken = token;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _friendlyError(e);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _user = null;
    _business = null;
    _accessToken = null;
    _status = AuthStatus.unauthenticated;
    _error = null;
    notifyListeners();
  }

  Future<bool> resetPassword({
    required String phone,
    required String newPassword,
    required String otpCode,
  }) async {
    try {
      _status = AuthStatus.loading;
      _error = null;
      notifyListeners();

      await _authRepository.resetPassword(
        phone: phone,
        newPassword: newPassword,
        otpCode: otpCode,
      );

      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _friendlyError(e);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  /// Refresh the business data (e.g., after plan upgrade)
  Future<void> refreshBusiness() async {
    try {
      final result = await _authRepository.getCurrentUser();
      if (result != null) {
        _user = result.user;
        _business = result.business;
        notifyListeners();
      }
    } catch (_) {}
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _friendlyError(Object e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionError:
        case DioExceptionType.unknown:
          return 'Cannot connect to server. Check your internet connection and try again.';
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return 'Connection timed out. Please try again.';
        case DioExceptionType.badResponse:
          final status = e.response?.statusCode;
          final msg = e.response?.data?['detail'];
          if (msg != null && msg.toString().isNotEmpty) return msg.toString();
          if (status == 401) return 'Authentication failed. Please try again.';
          if (status == 400) return 'Invalid details. Please check and try again.';
          if (status == 409) return 'Account already exists with this phone number.';
          return 'Server error ($status). Please try again.';
        default:
          return 'Something went wrong. Please try again.';
      }
    }
    // Pass through specific error messages from our datasource (e.g. "Phone number already registered")
    final rawMsg = e.toString().replaceFirst('Exception: ', '');
    if (rawMsg.isNotEmpty && rawMsg != 'Exception' && !rawMsg.startsWith('type \'Null\'')) {
      return rawMsg;
    }
    return 'Something went wrong. Please try again.';
  }
}
