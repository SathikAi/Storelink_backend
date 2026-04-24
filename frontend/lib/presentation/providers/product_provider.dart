import 'dart:typed_data';
import 'package:dio/dio.dart';
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
      _isLoading = false; // reset so refresh always proceeds
    }

    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      const pageSize = 20;
      final newProducts = await _repository.getProducts(
        page: _currentPage,
        pageSize: pageSize,
        search: _searchQuery,
        categoryId: _filterCategoryId,
        isActive: _filterIsActive,
      );

      _products.addAll(newProducts);
      if (newProducts.length < pageSize) {
        _hasMore = false;
      } else {
        _currentPage++;
      }
      _error = null;
    } catch (e) {
      _error = _friendlyError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchProducts(String query) async {
    _searchQuery = query.isEmpty ? null : query;
    await loadProducts(refresh: true);
  }

  Future<void> setFilters({int? categoryId, bool? isActive}) async {
    _filterCategoryId = categoryId;
    _filterIsActive = isActive;
    await loadProducts(refresh: true);
  }

  Future<void> clearFilters() async {
    _filterCategoryId = null;
    _filterIsActive = null;
    await loadProducts(refresh: true);
  }

  Future<void> loadProduct(String uuid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentProduct = await _repository.getProduct(uuid);
      _error = null;
    } catch (e) {
      _error = _friendlyError(e);
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
      _currentProduct = product;
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _friendlyError(e);
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
      _error = _friendlyError(e);
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
      _error = _friendlyError(e);
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
      _error = _friendlyError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> uploadProductImages(
    String uuid,
    List<Uint8List> imagesBytes,
    List<String> filenames,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final product =
          await _repository.uploadProductImages(uuid, imagesBytes, filenames);
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
      _error = _friendlyError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String _friendlyError(Object e) {
    if (e is DioException) {
      final msg = e.response?.data?['detail'];
      if (msg != null) return msg.toString();
      final status = e.response?.statusCode;
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown) {
        return 'Cannot connect to server. Check your internet connection.';
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'Connection timed out. Please try again.';
      }
      if (status == 400) return 'Invalid details. Please check and try again.';
      if (status == 409) return 'A product with this SKU already exists.';
      if (status != null) return 'Server error ($status). Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  Future<bool> toggleProductStatus(String uuid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final product = await _repository.toggleProductStatus(uuid);
      final index = _products.indexWhere((p) => p.uuid == uuid);
      if (index != -1) {
        _products[index] = product;
      }
      _currentProduct = product;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _friendlyError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
