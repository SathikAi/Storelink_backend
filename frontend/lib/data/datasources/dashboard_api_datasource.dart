import 'package:dio/dio.dart';
import '../../core/services/token_service.dart';
import '../../core/constants/api_constants.dart';

class DashboardApiDatasource {
  final Dio _dio;
  final TokenService _tokenService;

  DashboardApiDatasource(this._dio, this._tokenService);

  Future<Map<String, dynamic>> getDashboardStats({
    String? fromDate,
    String? toDate,
  }) async {
    final token = await _tokenService.getAccessToken();
    final queryParams = <String, dynamic>{};
    if (fromDate != null) queryParams['from_date'] = fromDate;
    if (toDate != null) queryParams['to_date'] = toDate;

    final response = await _dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.dashboardStats}',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    if (response.statusCode == 200 && response.data['success']) {
      return response.data['data'] as Map<String, dynamic>;
    } else {
      throw Exception(response.data['detail'] ?? 'Failed to fetch dashboard stats');
    }
  }
}
