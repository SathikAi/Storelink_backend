import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/business_entity.dart';

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

  AuthProvider(this._authRepository);

  AuthStatus get status => _status;
  UserEntity? get user => _user;
  BusinessEntity? get business => _business;
  String? get accessToken => _accessToken;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

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
        // getCurrentUser returned null only when token is truly invalid (401).
        _status = AuthStatus.unauthenticated;
      }
    } on DioException catch (e) {
      // Network/timeout error — keep user authenticated with cached data.
      // They'll see an error when they try to load data, but won't be force-logged out.
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
    try {
      _status = AuthStatus.loading;
      _error = null;
      notifyListeners();

      final supabase = Supabase.instance.client;
      String? supabaseToken;

      if (kIsWeb) {
        // Web: use Supabase OAuth redirect
        await supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: '${const String.fromEnvironment('WEB_APP_URL', defaultValue: 'https://storelink.sbs')}/auth-callback',
        );
        // The page redirects — auth state handled in app router on return
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return {'status': 'redirect'};
      } else {
        // Mobile: Supabase web OAuth → opens system browser → deep link returns to app
        // Requires com.storelink.app://auth-callback in Supabase allowed redirect URLs
        final completer = Completer<Session?>();
        StreamSubscription<AuthState>? sub;
        sub = supabase.auth.onAuthStateChange.listen((data) {
          if (data.event == AuthChangeEvent.signedIn && data.session != null) {
            if (!completer.isCompleted) completer.complete(data.session);
            sub?.cancel();
          }
        });

        await supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'com.storelink.app://auth-callback',
        );

        // Wait for user to complete OAuth in browser and deep link to fire
        Session? session;
        try {
          session = await completer.future.timeout(const Duration(minutes: 3));
        } catch (_) {
          sub?.cancel();
          _status = AuthStatus.unauthenticated;
          notifyListeners();
          return {'status': 'cancelled'};
        }

        supabaseToken = session?.accessToken;
        if (supabaseToken == null) {
          _status = AuthStatus.unauthenticated;
          notifyListeners();
          return {'status': 'cancelled'};
        }
      }

      // Call our backend
      final data = await _authRepository.googleAuth(supabaseToken);

      if (data['needs_registration'] == true) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return {
          'status': 'needs_registration',
          'email': data['google_email'] ?? '',
          'name': data['google_name'] ?? '',
          'token': data['supabase_token'] ?? supabaseToken,
        };
      }

      // Existing user — log them in
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

  Future<Map<String, dynamic>> loginWithGoogleToken(String supabaseToken) async {
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

  BusinessEntity? _parseBusiness(Map<String, dynamic> data) {
    try {
      final b = data['business'] as Map<String, dynamic>;
      return BusinessEntity(
        uuid: b['uuid'] ?? '',
        businessName: b['business_name'] ?? '',
        plan: b['plan'] ?? 'FREE',
        isActive: b['is_active'] ?? true,
      );
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
          if (msg != null) return msg.toString();
          if (status == 401) return 'Invalid phone number or password.';
          if (status == 400) return 'Invalid details. Please check and try again.';
          if (status == 409) return 'Account already exists with this phone number.';
          return 'Server error ($status). Please try again.';
        default:
          return 'Something went wrong. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}
