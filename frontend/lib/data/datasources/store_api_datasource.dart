import 'package:dio/dio.dart';
import '../models/store_models.dart';
import '../../core/constants/api_constants.dart';

class StoreApiDatasource {
  final Dio _dio;

  StoreApiDatasource()
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ));

  Future<StoreInfo> getStoreInfo(String businessUuid) async {
    try {
      final response = await _dio.get('/store/$businessUuid');
      return StoreInfo.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final message = e.response?.data?['detail'] ?? 'Failed to load store info';
      throw Exception(message);
    } catch (e) {
      throw Exception('Store loading failed');
    }
  }

  Future<List<StoreCategory>> getCategories(String businessUuid) async {
    try {
      final response = await _dio.get('/store/$businessUuid/categories');
      return (response.data as List<dynamic>)
          .map((e) => StoreCategory.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final message =
          e.response?.data?['detail'] ?? 'Failed to load categories';
      throw Exception(message);
    } catch (e) {
      throw Exception('Category loading failed');
    }
  }

  Future<List<StoreProduct>> getProducts(
    String businessUuid, {
    String? search,
    String? categoryUuid,
    int page = 1,
    int pageSize = 40,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
        if (search != null && search.isNotEmpty) 'search': search,
        if (categoryUuid != null) 'category_uuid': categoryUuid,
      };
      final response = await _dio.get(
        '/store/$businessUuid/products',
        queryParameters: queryParams,
      );
      return (response.data as List<dynamic>)
          .map((e) => StoreProduct.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final message = e.response?.data?['detail'] ?? 'Failed to load products';
      throw Exception(message);
    } catch (e) {
      throw Exception('Product loading failed');
    }
  }

  Future<StoreOrderResult> placeOrder(
    String businessUuid, {
    required String customerName,
    required String customerPhone,
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    String? notes,
  }) async {
    final response = await _dio.post(
      '/store/$businessUuid/orders',
      data: {
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'items': items,
        'payment_method': paymentMethod,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    return StoreOrderResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<StoreOrderResult> getOrderStatus(
    String businessUuid,
    String orderNumber,
  ) async {
    final response =
        await _dio.get('/store/$businessUuid/orders/$orderNumber');
    return StoreOrderResult.fromJson(response.data as Map<String, dynamic>);
  }
}
