import 'package:flutter/foundation.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';

class ProductProvider with ChangeNotifier {
  final ProductRepository _repository;

  ProductProvider(this._repository);

  final List<ProductModel> _products = [];
  ProductModel? _currentProduct;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  String? _searchQuery;
  int? _filterCategoryId;
  bool? _filterIsActive;

  List<ProductModel> get products => _products;
  ProductModel? get currentProduct => _currentProduct;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  bool get hasMore => _hasMore;
  String? get searchQuery => _searchQuery;

  Future<void> loadProducts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _products.clear();
      _hasMore = true;
    }

    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newProducts = await _repository.getProducts(
        page: _currentPage,
        pageSize: 20,
        search: _searchQuery,
        categoryId: _filterCategoryId,
        isActive: _filterIsActive,
      );

      if (newProducts.isEmpty) {
        _hasMore = false;
      } else {
        _products.addAll(newProducts);
        _currentPage++;
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchProducts(String query) async {
    _searchQuery = query.isEmpty ? null : query;
    await loadProducts(refresh: true);
  }

  void setFilters({int? categoryId, bool? isActive}) {
    _filterCategoryId = categoryId;
    _filterIsActive = isActive;
    loadProducts(refresh: true);
  }

  void clearFilters() {
    _filterCategoryId = null;
    _filterIsActive = null;
    loadProducts(refresh: true);
  }

  Future<void> loadProduct(String uuid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentProduct = await _repository.getProduct(uuid);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createProduct(ProductCreateRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final product = await _repository.createProduct(request);
      _products.insert(0, product);
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct(String uuid, ProductUpdateRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final product = await _repository.updateProduct(uuid, request);
      final index = _products.indexWhere((p) => p.uuid == uuid);
      if (index != -1) {
        _products[index] = product;
      }
      _currentProduct = product;
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(String uuid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.deleteProduct(uuid);
      _products.removeWhere((p) => p.uuid == uuid);
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadProductImage(
    String uuid,
    Uint8List imageBytes,
    String filename,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final product =
          await _repository.uploadProductImage(uuid, imageBytes, filename);
      final index = _products.indexWhere((p) => p.uuid == uuid);
      if (index != -1) {
        _products[index] = product;
      }
      _currentProduct = product;
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleProductStatus(String uuid) async {
    try {
      final product = await _repository.toggleProductStatus(uuid);
      final index = _products.indexWhere((p) => p.uuid == uuid);
      if (index != -1) {
        _products[index] = product;
      }
      _currentProduct = product;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
