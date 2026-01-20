import 'package:dio/dio.dart';
import '../../core/services/token_service.dart';
import '../../core/constants/api_constants.dart';
import '../models/category_model.dart';

class CategoryApiDatasource {
  final Dio _dio;
  final TokenService _tokenService;

  CategoryApiDatasource(this._dio, this._tokenService);

  Future<List<CategoryModel>> getCategories({
    int page = 1,
    int pageSize = 50,
    bool? isActive,
  }) async {
    final token = await _tokenService.getAccessToken();
    final response = await _dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.categories}',
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (isActive != null) 'is_active': isActive,
      },
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    final List<dynamic> data = response.data['data'];
    return data.map((json) => CategoryModel.fromJson(json)).toList();
  }

  Future<CategoryModel> getCategory(String uuid) async {
    final token = await _tokenService.getAccessToken();
    final response = await _dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.categories}/$uuid',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    return CategoryModel.fromJson(response.data['data']);
  }

  Future<CategoryModel> createCategory(CategoryCreateRequest request) async {
    final token = await _tokenService.getAccessToken();
    final response = await _dio.post(
      '${ApiConstants.baseUrl}${ApiConstants.categories}',
      data: request.toJson(),
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    return CategoryModel.fromJson(response.data['data']);
  }

  Future<CategoryModel> updateCategory(
    String uuid,
    CategoryUpdateRequest request,
  ) async {
    final token = await _tokenService.getAccessToken();
    final response = await _dio.put(
      '${ApiConstants.baseUrl}${ApiConstants.categories}/$uuid',
      data: request.toJson(),
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    return CategoryModel.fromJson(response.data['data']);
  }

  Future<void> deleteCategory(String uuid) async {
    final token = await _tokenService.getAccessToken();
    await _dio.delete(
      '${ApiConstants.baseUrl}${ApiConstants.categories}/$uuid',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
  }
}
