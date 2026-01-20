import 'package:dio/dio.dart';
import '../../core/services/token_service.dart';
import '../../core/constants/api_constants.dart';
import '../models/admin_models.dart';

class AdminApiDataSource {
  final Dio client;
  final TokenService _tokenService;

  AdminApiDataSource({required this.client, required TokenService tokenService})
      : _tokenService = tokenService;

  Future<Map<String, dynamic>> getBusinesses({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? plan,
    bool? isActive,
  }) async {
    final token = await _tokenService.getAccessToken();
    try {
      final response = await client.get(
        '${ApiConstants.baseUrl}/admin/businesses',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (search != null && search.isNotEmpty) 'search': search,
          if (plan != null) 'plan': plan,
          if (isActive != null) 'is_active': isActive,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return response.data['data'];
    } catch (e) {
      throw Exception('Failed to load businesses: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getUsers({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? role,
    bool? isActive,
  }) async {
    final token = await _tokenService.getAccessToken();
    try {
      final response = await client.get(
        '${ApiConstants.baseUrl}/admin/users',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (search != null && search.isNotEmpty) 'search': search,
          if (role != null) 'role': role,
          if (isActive != null) 'is_active': isActive,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return response.data['data'];
    } catch (e) {
      throw Exception('Failed to load users: ${e.toString()}');
    }
  }

  Future<PlatformStats> getPlatformStats() async {
    final token = await _tokenService.getAccessToken();
    try {
      final response = await client.get(
        '${ApiConstants.baseUrl}/admin/stats',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return PlatformStats.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Failed to load platform stats: ${e.toString()}');
    }
  }

  Future<void> updateBusinessStatus({
    required String businessUuid,
    required bool isActive,
  }) async {
    final token = await _tokenService.getAccessToken();
    try {
      await client.patch(
        '${ApiConstants.baseUrl}/admin/businesses/$businessUuid/status',
        data: {'is_active': isActive},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } catch (e) {
      throw Exception('Failed to update business status: ${e.toString()}');
    }
  }

  Future<void> updateBusinessPlan({
    required String businessUuid,
    required String plan,
    DateTime? planExpiryDate,
  }) async {
    final token = await _tokenService.getAccessToken();
    try {
      await client.patch(
        '${ApiConstants.baseUrl}/admin/businesses/$businessUuid/plan',
        data: {
          'plan': plan,
          if (planExpiryDate != null)
            'plan_expiry_date': planExpiryDate.toIso8601String().split('T')[0],
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } catch (e) {
      throw Exception('Failed to update business plan: ${e.toString()}');
    }
  }

  Future<void> updateUserStatus({
    required String userUuid,
    required bool isActive,
  }) async {
    final token = await _tokenService.getAccessToken();
    try {
      await client.patch(
        '${ApiConstants.baseUrl}/admin/users/$userUuid/status',
        data: {'is_active': isActive},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } catch (e) {
      throw Exception('Failed to update user status: ${e.toString()}');
    }
  }
}
