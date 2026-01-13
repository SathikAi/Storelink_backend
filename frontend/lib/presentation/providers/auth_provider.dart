import 'package:flutter/foundation.dart';
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
  String? _error;

  AuthProvider(this._authRepository);

  AuthStatus get status => _status;
  UserEntity? get user => _user;
  BusinessEntity? get business => _business;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> checkAuthStatus() async {
    _status = AuthStatus.loading;
    notifyListeners();

    final isAuth = await _authRepository.isAuthenticated();
    if (isAuth) {
      final result = await _authRepository.getCurrentUser();
      if (result != null) {
        _user = result.user;
        _business = result.business;
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

      _user = result.user;
      _business = result.business;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
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

      _user = result.user;
      _business = result.business;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
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
      _error = e.toString();
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

      _user = result.user;
      _business = result.business;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _user = null;
    _business = null;
    _status = AuthStatus.unauthenticated;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
