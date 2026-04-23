import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/business_entity.dart';

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
  bool get isPro => _business?.plan.toUpperCase() == 'PAID';

  Future<void> checkAuthStatus() async {
    _status = AuthStatus.loading;
    notifyListeners();

    final isAuth = await _authRepository.isAuthenticated();
    if (isAuth) {
      final result = await _authRepository.getCurrentUser();
      if (result != null) {
        _user = result.user;
        _business = result.business;
        _accessToken = await _authRepository.getAccessToken();
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } else {
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
