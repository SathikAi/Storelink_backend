import 'package:dio/dio.dart';
import '../../core/services/token_service.dart';
import '../../core/constants/api_constants.dart';
import '../models/product_model.dart';
import 'dart:typed_data';

class ProductApiDatasource {
  final Dio _dio;
  final TokenService _tokenService;

  ProductApiDatasource(this._dio, this._tokenService);

  Future<List<ProductModel>> getProducts({
    int page = 1,
    int pageSize = 20,
    String? search,
    int? categoryId,
    bool? isActive,
    bool? lowStock,
  }) async {
    final token = await _tokenService.getAccessToken();

    final queryParams = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (categoryId != null) queryParams['category_id'] = categoryId;
    if (isActive != null) queryParams['is_active'] = isActive;
    if (lowStock != null) queryParams['low_stock'] = lowStock;

    final response = await _dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.products}',
      queryParameters: queryParams,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    final data = response.data['data'] as List;
    return data.map((json) => ProductModel.fromJson(json)).toList();
  }

  Future<ProductModel> updateProductStock(
    String uuid,
    int quantityChange,
  ) async {
    final token = await _tokenService.getAccessToken();

    final response = await _dio.patch(
      '${ApiConstants.baseUrl}${ApiConstants.products}/$uuid/stock',
      queryParameters: {'quantity_change': quantityChange},
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    return ProductModel.fromJson(response.data['data']);
  }

  Future<ProductModel> getProduct(String uuid) async {
    final token = await _tokenService.getAccessToken();

    final response = await _dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.products}/$uuid',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    return ProductModel.fromJson(response.data['data']);
  }

  Future<ProductModel> createProduct(ProductCreateRequest request) async {
    final token = await _tokenService.getAccessToken();

    final response = await _dio.post(
      '${ApiConstants.baseUrl}${ApiConstants.products}',
      data: request.toJson(),
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    return ProductModel.fromJson(response.data['data']);
  }

  Future<ProductModel> updateProduct(
    String uuid,
    ProductUpdateRequest request,
  ) async {
    final token = await _tokenService.getAccessToken();

    final response = await _dio.put(
      '${ApiConstants.baseUrl}${ApiConstants.products}/$uuid',
      data: request.toJson(),
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    return ProductModel.fromJson(response.data['data']);
  }

  Future<void> deleteProduct(String uuid) async {
    final token = await _tokenService.getAccessToken();

    await _dio.delete(
      '${ApiConstants.baseUrl}${ApiConstants.products}/$uuid',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
  }

  Future<ProductModel> uploadProductImage(
    String uuid,
    Uint8List imageBytes,
    String filename,
  ) async {
    final token = await _tokenService.getAccessToken();

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        imageBytes,
        filename: filename,
      ),
    });

    final response = await _dio.post(
      '${ApiConstants.baseUrl}${ApiConstants.products}/$uuid/image',
      data: formData,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    return ProductModel.fromJson(response.data['data']);
  }

  Future<ProductModel> toggleProductStatus(String uuid) async {
    final token = await _tokenService.getAccessToken();

    final response = await _dio.patch(
      '${ApiConstants.baseUrl}${ApiConstants.products}/$uuid/toggle',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    return ProductModel.fromJson(response.data['data']);
  }
}
