import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/api_constants.dart';

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
    String? referralCode,
  }) async {
    try {
      final body = {
        'phone': phone,
        'password': password,
        'full_name': fullName,
        'email': email,
        'business_name': businessName,
        'business_phone': businessPhone,
        'business_email': businessEmail,
        if (referralCode != null && referralCode.isNotEmpty)
          'referral_code': referralCode.trim().toUpperCase(),
      };
      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.authRegister}',
        data: body,
      );
      if (response.statusCode == 201 && response.data['success']) {
        return response.data['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response.data['detail'] ?? 'Registration failed');
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data != null) {
        // 422 Pydantic detail is a list or string
        if (data['detail'] is List) {
          final msgs = (data['detail'] as List)
              .map((d) => d['msg']?.toString() ?? '')
              .where((m) => m.isNotEmpty)
              .join(', ');
          throw Exception(msgs.isNotEmpty ? msgs : 'Registration failed');
        }
        throw Exception(data['detail']?.toString() ?? 'Registration failed');
      }
      throw Exception('[${e.type.name}] ${e.message ?? e.error ?? 'Connection failed'}');
    }
  }

  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    try {
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
    } on DioException catch (e) {
      debugPrint('DioException type: ${e.type}');
      debugPrint('DioException message: ${e.message}');
      debugPrint('DioException error: ${e.error}');
      debugPrint('DioException url: ${e.requestOptions.uri}');
      final data = e.response?.data;
      if (data != null) {
        if (data['detail'] is List) {
          final msgs = (data['detail'] as List)
              .map((d) => d['msg']?.toString() ?? '')
              .where((m) => m.isNotEmpty)
              .join(', ');
          throw Exception(msgs.isNotEmpty ? msgs : 'Login failed');
        }
        throw Exception(data['detail']?.toString() ?? 'Login failed');
      }
      throw Exception('[${e.type.name}] ${e.message ?? e.error ?? 'Connection failed'}');
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

  Future<Map<String, dynamic>> googleAuth(String supabaseToken) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/auth/google',
        data: {'supabase_token': supabaseToken},
      );
      if (response.statusCode == 200 && response.data['success']) {
        return response.data['data'] as Map<String, dynamic>;
      }
      throw Exception(response.data['detail'] ?? 'Google auth failed');
    } on DioException catch (e) {
      final data = e.response?.data;
      throw Exception(data?['detail']?.toString() ?? 'Connection failed');
    }
  }

  Future<Map<String, dynamic>> googleCompleteRegistration({
    required String supabaseToken,
    required String phone,
    required String businessName,
    String? businessPhone,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/auth/google/complete',
        data: {
          'supabase_token': supabaseToken,
          'phone': phone,
          'business_name': businessName,
          'business_phone': businessPhone ?? phone,
        },
      );
      if (response.statusCode == 201 && response.data['success']) {
        return response.data['data'] as Map<String, dynamic>;
      }
      throw Exception(response.data['detail'] ?? 'Registration failed');
    } on DioException catch (e) {
      final data = e.response?.data;
      throw Exception(data?['detail']?.toString() ?? 'Connection failed');
    }
  }

  Future<void> resetPassword({
    required String phone,
    required String newPassword,
    required String otpCode,
  }) async {
    final response = await _dio.post(
      '${ApiConstants.baseUrl}/auth/reset-password',
      data: {
        'phone': phone,
        'new_password': newPassword,
        'otp_code': otpCode,
      },
    );

    if (response.statusCode != 200 || !response.data['success']) {
      throw Exception(response.data['detail'] ?? 'Password reset failed');
    }
  }
}
