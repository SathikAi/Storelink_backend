import 'package:dio/dio.dart';
import '../../core/services/token_service.dart';
import '../../core/constants/api_constants.dart';
import '../models/order_model.dart';

class OrderApiDatasource {
  final Dio _dio;
  final TokenService _tokenService;

  OrderApiDatasource(this._dio, this._tokenService);

  Future<List<OrderModel>> getOrders({
    int page = 1,
    int pageSize = 50,
    String? customerUuid,
    String? status,
    String? paymentStatus,
    String? search,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final token = await _tokenService.getAccessToken();

    final queryParams = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (customerUuid != null && customerUuid.isNotEmpty) {
      queryParams['customer_uuid'] = customerUuid;
    }
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (paymentStatus != null && paymentStatus.isNotEmpty) {
      queryParams['payment_status'] = paymentStatus;
    }
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (fromDate != null) {
      queryParams['from_date'] =
          '${fromDate.year}-${fromDate.month.toString().padLeft(2, '0')}-${fromDate.day.toString().padLeft(2, '0')}';
    }
    if (toDate != null) {
      queryParams['to_date'] =
          '${toDate.year}-${toDate.month.toString().padLeft(2, '0')}-${toDate.day.toString().padLeft(2, '0')}';
    }

    final response = await _dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.orders}',
      queryParameters: queryParams,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    final responseData = response.data;
    final List data = responseData['orders'] ?? responseData['data']?['orders'] ?? [];
    return data.map((json) => OrderModel.fromJson(json)).toList();
  }

  Future<OrderModel> getOrder(String uuid) async {
    final token = await _tokenService.getAccessToken();

    final response = await _dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.orders}/$uuid',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    return OrderModel.fromJson(response.data);
  }

  Future<OrderModel> createOrder(OrderCreateRequest request) async {
    final token = await _tokenService.getAccessToken();

    final response = await _dio.post(
      '${ApiConstants.baseUrl}${ApiConstants.orders}',
      data: request.toJson(),
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    return OrderModel.fromJson(response.data);
  }

  Future<OrderModel> updateOrder(
    String uuid,
    OrderUpdateRequest request,
  ) async {
    final token = await _tokenService.getAccessToken();

    final response = await _dio.patch(
      '${ApiConstants.baseUrl}${ApiConstants.orders}/$uuid',
      data: request.toJson(),
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    return OrderModel.fromJson(response.data);
  }

  Future<OrderModel> cancelOrder(String uuid) async {
    final token = await _tokenService.getAccessToken();

    final response = await _dio.post(
      '${ApiConstants.baseUrl}${ApiConstants.orders}/$uuid/cancel',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    return OrderModel.fromJson(response.data);
  }

  Future<void> deleteOrder(String uuid) async {
    final token = await _tokenService.getAccessToken();

    await _dio.delete(
      '${ApiConstants.baseUrl}${ApiConstants.orders}/$uuid',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
  }
}
