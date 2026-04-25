import '../../core/services/token_service.dart';
import '../datasources/auth_api_datasource.dart';
import '../models/user_model.dart';
import '../models/business_model.dart';
import '../models/auth_tokens_model.dart';

class AuthRepository {
  final AuthApiDatasource _apiDatasource;
  final TokenService _tokenService;

  AuthRepository(this._apiDatasource, this._tokenService);

  Future<AuthResult> register({
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
      final data = await _apiDatasource.register(
        phone: phone,
        password: password,
        fullName: fullName,
        email: email,
        businessName: businessName,
        businessPhone: businessPhone,
        businessEmail: businessEmail,
        referralCode: referralCode,
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
      // Unwrap nested Exception messages to avoid "Login failed: Exception: ..."
      final msg = e.toString().replaceFirst('Exception: ', '');
      throw Exception(msg);
    }
  }

  Future<Map<String, dynamic>> googleAuth(String supabaseToken) async {
    final data = await _apiDatasource.googleAuth(supabaseToken);
    if (data['needs_registration'] != true && data['tokens'] != null) {
      final tokens = AuthTokensModel.fromJson(data['tokens']);
      await _saveTokens(tokens);
    }
    return data;
  }

  Future<AuthResult> googleCompleteRegistration({
    required String supabaseToken,
    required String phone,
    required String businessName,
    String? businessPhone,
  }) async {
    try {
      final data = await _apiDatasource.googleCompleteRegistration(
        supabaseToken: supabaseToken,
        phone: phone,
        businessName: businessName,
        businessPhone: businessPhone,
      );
      final user = UserModel.fromJson(data['user']);
      final business = BusinessModel.fromJson(data['business']);
      final tokens = AuthTokensModel.fromJson(data['tokens']);
      await _saveTokens(tokens);
      return AuthResult(user: user, business: business, tokens: tokens);
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      throw Exception(msg);
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
    await _tokenService.clearTokens();
  }

  Future<String?> getAccessToken() async {
    return await _tokenService.getAccessToken();
  }

  Future<String?> getRefreshToken() async {
    return await _tokenService.getRefreshToken();
  }

  Future<void> _saveTokens(AuthTokensModel tokens) async {
    await _tokenService.saveAccessToken(tokens.accessToken);
    await _tokenService.saveRefreshToken(tokens.refreshToken);
  }

  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null;
  }

  Future<void> resetPassword({
    required String phone,
    required String newPassword,
    required String otpCode,
  }) async {
    try {
      await _apiDatasource.resetPassword(
        phone: phone,
        newPassword: newPassword,
        otpCode: otpCode,
      );
    } catch (e) {
      throw Exception('Password reset failed: ${e.toString()}');
    }
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
