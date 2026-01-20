import '../datasources/product_api_datasource.dart';
import '../models/product_model.dart';
import 'dart:typed_data';

class ProductRepository {
  final ProductApiDatasource _datasource;

  ProductRepository(this._datasource);

  Future<List<ProductModel>> getProducts({
    int page = 1,
    int pageSize = 20,
    String? search,
    int? categoryId,
    bool? isActive,
    bool? lowStock,
  }) async {
    return await _datasource.getProducts(
      page: page,
      pageSize: pageSize,
      search: search,
      categoryId: categoryId,
      isActive: isActive,
      lowStock: lowStock,
    );
  }

  Future<ProductModel> updateProductStock(
    String uuid,
    int quantityChange,
  ) async {
    return await _datasource.updateProductStock(uuid, quantityChange);
  }

  Future<ProductModel> getProduct(String uuid) async {
    return await _datasource.getProduct(uuid);
  }

  Future<ProductModel> createProduct(ProductCreateRequest request) async {
    return await _datasource.createProduct(request);
  }

  Future<ProductModel> updateProduct(
    String uuid,
    ProductUpdateRequest request,
  ) async {
    return await _datasource.updateProduct(uuid, request);
  }

  Future<void> deleteProduct(String uuid) async {
    return await _datasource.deleteProduct(uuid);
  }

  Future<ProductModel> uploadProductImage(
    String uuid,
    Uint8List imageBytes,
    String filename,
  ) async {
    return await _datasource.uploadProductImage(uuid, imageBytes, filename);
  }

  Future<ProductModel> toggleProductStatus(String uuid) async {
    return await _datasource.toggleProductStatus(uuid);
  }
}
