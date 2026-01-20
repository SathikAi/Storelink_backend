import '../datasources/category_api_datasource.dart';
import '../models/category_model.dart';

class CategoryRepository {
  final CategoryApiDatasource _datasource;

  CategoryRepository(this._datasource);

  Future<List<CategoryModel>> getCategories({
    int page = 1,
    int pageSize = 50,
    bool? isActive,
  }) async {
    return _datasource.getCategories(
      page: page,
      pageSize: pageSize,
      isActive: isActive,
    );
  }

  Future<CategoryModel> getCategory(String uuid) async {
    return _datasource.getCategory(uuid);
  }

  Future<CategoryModel> createCategory(CategoryCreateRequest request) async {
    return _datasource.createCategory(request);
  }

  Future<CategoryModel> updateCategory(
    String uuid,
    CategoryUpdateRequest request,
  ) async {
    return _datasource.updateCategory(uuid, request);
  }

  Future<void> deleteCategory(String uuid) async {
    return _datasource.deleteCategory(uuid);
  }
}
