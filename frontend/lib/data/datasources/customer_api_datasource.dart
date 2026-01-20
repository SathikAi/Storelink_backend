import 'package:dio/dio.dart';
import '../../core/services/token_service.dart';
import '../../core/constants/api_constants.dart';
import '../models/customer_model.dart';

class CustomerApiDatasource {
  final Dio _dio;
  final TokenService _tokenService;

  CustomerApiDatasource(this._dio, this._tokenService);

  Future<List<CustomerModel>> getCustomers({
    int page = 1,
    int pageSize = 50,
    String? search,
    bool? isActive,
  }) async {
    final token = await _tokenService.getAccessToken();

    final queryParams = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (isActive != null) queryParams['is_active'] = isActive;

    final response = await _dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.customers}',
      queryParameters: queryParams,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    final data = response.data['data'] as List;
    return data.map((json) => CustomerModel.fromJson(json)).toList();
  }

  Future<CustomerModel> getCustomer(String uuid) async {
    final token = await _tokenService.getAccessToken();

    final response = await _dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.customers}/$uuid',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    return CustomerModel.fromJson(response.data['data']);
  }

  Future<CustomerModel> createCustomer(CustomerCreateRequest request) async {
    final token = await _tokenService.getAccessToken();

    final response = await _dio.post(
      '${ApiConstants.baseUrl}${ApiConstants.customers}',
      data: request.toJson(),
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    return CustomerModel.fromJson(response.data['data']);
  }

  Future<CustomerModel> updateCustomer(
    String uuid,
    CustomerUpdateRequest request,
  ) async {
    final token = await _tokenService.getAccessToken();

    final response = await _dio.put(
      '${ApiConstants.baseUrl}${ApiConstants.customers}/$uuid',
      data: request.toJson(),
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    return CustomerModel.fromJson(response.data['data']);
  }

  Future<void> deleteCustomer(String uuid) async {
    final token = await _tokenService.getAccessToken();

    await _dio.delete(
      '${ApiConstants.baseUrl}${ApiConstants.customers}/$uuid',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
  }
}
