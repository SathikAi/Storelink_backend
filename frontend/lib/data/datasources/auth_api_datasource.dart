import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../models/user_model.dart';
import '../models/business_model.dart';
import '../models/auth_tokens_model.dart';

class AuthApiDatasource {
  final Dio _dio;

  AuthApiDatasource(this._dio);

  Future<Map<String, dynamic>> register({
    required String phone,
    required String password,
    required String fullName,
    String? email,
    required String businessName,
    required String businessPhone,
    String? businessEmail,
  }) async {
    final response = await _dio.post(
      '${ApiConstants.baseUrl}${ApiConstants.authRegister}',
      data: {
        'phone': phone,
        'password': password,
        'full_name': fullName,
        'email': email,
        'business_name': businessName,
        'business_phone': businessPhone,
        'business_email': businessEmail,
      },
    );

    if (response.statusCode == 201 && response.data['success']) {
      return response.data['data'] as Map<String, dynamic>;
    } else {
      throw Exception(response.data['detail'] ?? 'Registration failed');
    }
  }

  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final response = await _dio.post(
      '${ApiConstants.baseUrl}${ApiConstants.authLogin}',
      data: {
        'phone': phone,
        'password': password,
      },
    );

    if (response.statusCode == 200 && response.data['success']) {
      return response.data['data'] as Map<String, dynamic>;
    } else {
      throw Exception(response.data['detail'] ?? 'Login failed');
    }
  }

  Future<void> sendOtp({
    required String phone,
    required String purpose,
  }) async {
    final response = await _dio.post(
      '${ApiConstants.baseUrl}${ApiConstants.authOtpSend}',
      data: {
        'phone': phone,
        'purpose': purpose,
      },
    );

    if (response.statusCode != 200 || !response.data['success']) {
      throw Exception(response.data['detail'] ?? 'Failed to send OTP');
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otpCode,
    required String purpose,
  }) async {
    final response = await _dio.post(
      '${ApiConstants.baseUrl}${ApiConstants.authOtpVerify}',
      data: {
        'phone': phone,
        'otp_code': otpCode,
        'purpose': purpose,
      },
    );

    if (response.statusCode == 200 && response.data['success']) {
      return response.data['data'] as Map<String, dynamic>;
    } else {
      throw Exception(response.data['detail'] ?? 'OTP verification failed');
    }
  }

  Future<Map<String, dynamic>> getCurrentUser(String token) async {
    final response = await _dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.authMe}',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    if (response.statusCode == 200 && response.data['success']) {
      return response.data['data'] as Map<String, dynamic>;
    } else {
      throw Exception(response.data['detail'] ?? 'Failed to get user data');
    }
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await _dio.post(
      '${ApiConstants.baseUrl}${ApiConstants.authRefresh}',
      data: {
        'refresh_token': refreshToken,
      },
    );

    if (response.statusCode == 200 && response.data['success']) {
      return response.data['data'] as Map<String, dynamic>;
    } else {
      throw Exception(response.data['detail'] ?? 'Token refresh failed');
    }
  }
}
