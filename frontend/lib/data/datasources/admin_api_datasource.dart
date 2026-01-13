import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../models/admin_models.dart';

class AdminApiDataSource {
  final http.Client client;

  AdminApiDataSource({required this.client});

  Future<Map<String, dynamic>> getBusinesses({
    required String token,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? plan,
    bool? isActive,
  }) async {
    var uri = Uri.parse('${ApiConstants.baseUrl}/admin/businesses')
        .replace(queryParameters: {
      'page': page.toString(),
      'page_size': pageSize.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (plan != null) 'plan': plan,
      if (isActive != null) 'is_active': isActive.toString(),
    });

    final response = await client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'];
    } else {
      throw Exception('Failed to load businesses: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getUsers({
    required String token,
    int page = 1,
    int pageSize = 20,
    String? search,
    String? role,
    bool? isActive,
  }) async {
    var uri = Uri.parse('${ApiConstants.baseUrl}/admin/users')
        .replace(queryParameters: {
      'page': page.toString(),
      'page_size': pageSize.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (role != null) 'role': role,
      if (isActive != null) 'is_active': isActive.toString(),
    });

    final response = await client.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'];
    } else {
      throw Exception('Failed to load users: ${response.body}');
    }
  }

  Future<PlatformStats> getPlatformStats({required String token}) async {
    final response = await client.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/stats'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return PlatformStats.fromJson(data['data']);
    } else {
      throw Exception('Failed to load platform stats: ${response.body}');
    }
  }

  Future<void> updateBusinessStatus({
    required String token,
    required String businessUuid,
    required bool isActive,
  }) async {
    final response = await client.patch(
      Uri.parse('${ApiConstants.baseUrl}/admin/businesses/$businessUuid/status'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'is_active': isActive}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update business status: ${response.body}');
    }
  }

  Future<void> updateBusinessPlan({
    required String token,
    required String businessUuid,
    required String plan,
    DateTime? planExpiryDate,
  }) async {
    final response = await client.patch(
      Uri.parse('${ApiConstants.baseUrl}/admin/businesses/$businessUuid/plan'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'plan': plan,
        if (planExpiryDate != null)
          'plan_expiry_date': planExpiryDate.toIso8601String().split('T')[0],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update business plan: ${response.body}');
    }
  }

  Future<void> updateUserStatus({
    required String token,
    required String userUuid,
    required bool isActive,
  }) async {
    final response = await client.patch(
      Uri.parse('${ApiConstants.baseUrl}/admin/users/$userUuid/status'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'is_active': isActive}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update user status: ${response.body}');
    }
  }
}
