import '../datasources/auth_api_datasource.dart';
import '../models/user_model.dart';
import '../models/business_model.dart';
import '../models/auth_tokens_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  final AuthApiDatasource _apiDatasource;
  final SharedPreferences _prefs;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  AuthRepository(this._apiDatasource, this._prefs);

  Future<AuthResult> register({
    required String phone,
    required String password,
    required String fullName,
    String? email,
    required String businessName,
    required String businessPhone,
    String? businessEmail,
  }) async {
    try {
      final data = await _apiDatasource.register(
        phone: phone,
        password: password,
        fullName: fullName,
        email: email,
        businessName: businessName,
        businessPhone: businessPhone,
        businessEmail: businessEmail,
      );

      final user = UserModel.fromJson(data['user']);
      final business = BusinessModel.fromJson(data['business']);
      final tokens = AuthTokensModel.fromJson(data['tokens']);

      await _saveTokens(tokens);

      return AuthResult(user: user, business: business, tokens: tokens);
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  Future<AuthResult> login({
    required String phone,
    required String password,
  }) async {
    try {
      final data = await _apiDatasource.login(
        phone: phone,
        password: password,
      );

      final user = UserModel.fromJson(data['user']);
      final business = data['business'] != null
          ? BusinessModel.fromJson(data['business'])
          : null;
      final tokens = AuthTokensModel.fromJson(data['tokens']);

      await _saveTokens(tokens);

      return AuthResult(user: user, business: business, tokens: tokens);
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<void> sendOtp({
    required String phone,
    required String purpose,
  }) async {
    try {
      await _apiDatasource.sendOtp(phone: phone, purpose: purpose);
    } catch (e) {
      throw Exception('Failed to send OTP: ${e.toString()}');
    }
  }

  Future<AuthResult> verifyOtp({
    required String phone,
    required String otpCode,
    required String purpose,
  }) async {
    try {
      final data = await _apiDatasource.verifyOtp(
        phone: phone,
        otpCode: otpCode,
        purpose: purpose,
      );

      final user = UserModel.fromJson(data['user']);
      final business = data['business'] != null
          ? BusinessModel.fromJson(data['business'])
          : null;
      final tokens = AuthTokensModel.fromJson(data['tokens']);

      await _saveTokens(tokens);

      return AuthResult(user: user, business: business, tokens: tokens);
    } catch (e) {
      throw Exception('OTP verification failed: ${e.toString()}');
    }
  }

  Future<AuthResult?> getCurrentUser() async {
    try {
      final token = await getAccessToken();
      if (token == null) return null;

      final data = await _apiDatasource.getCurrentUser(token);

      final user = UserModel.fromJson(data['user']);
      final business = data['business'] != null
          ? BusinessModel.fromJson(data['business'])
          : null;

      return AuthResult(user: user, business: business, tokens: null);
    } catch (e) {
      return null;
    }
  }

  Future<void> logout() async {
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
  }

  Future<String?> getAccessToken() async {
    return _prefs.getString(_accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return _prefs.getString(_refreshTokenKey);
  }

  Future<void> _saveTokens(AuthTokensModel tokens) async {
    await _prefs.setString(_accessTokenKey, tokens.accessToken);
    await _prefs.setString(_refreshTokenKey, tokens.refreshToken);
  }

  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null;
  }
}

class AuthResult {
  final UserModel user;
  final BusinessModel? business;
  final AuthTokensModel? tokens;

  AuthResult({
    required this.user,
    this.business,
    this.tokens,
  });
}
