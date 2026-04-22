import 'package:dio/dio.dart';
import '../../core/services/token_service.dart';
import '../../core/constants/api_constants.dart';

class DashboardApiDatasource {
  final Dio _dio;
  // ignore: unused_field
  final TokenService _tokenService;

  DashboardApiDatasource(this._dio, this._tokenService);

  Future<Map<String, dynamic>> getDashboardStats({
    String? fromDate,
    String? toDate,
  }) async {
    final queryParams = <String, dynamic>{};
    if (fromDate != null) queryParams['from_date'] = fromDate;
    if (toDate != null) queryParams['to_date'] = toDate;

    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.dashboardStats}',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200 && response.data['success']) {
        return response.data['data'] as Map<String, dynamic>;
      } else {
        throw Exception(response.data['detail'] ?? 'Failed to fetch dashboard stats');
      }
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401 || code == 403) {
        throw Exception('Session expired. Please log in again.');
      }
      final detail = e.response?.data?['detail'];
      throw Exception(detail?.toString() ?? 'Failed to load dashboard');
    }
  }
}
