import 'package:flutter/foundation.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';

class InventoryProvider with ChangeNotifier {
  final ProductRepository _repository;

  InventoryProvider(this._repository);

  final List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  String? _searchQuery;
  bool _filterLowStock = false;

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  String? get searchQuery => _searchQuery;
  bool get filterLowStock => _filterLowStock;

  Future<void> loadInventory({bool refresh = false}) async {
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
        lowStock: _filterLowStock ? true : null,
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

  Future<void> searchInventory(String query) async {
    _searchQuery = query.isEmpty ? null : query;
    await loadInventory(refresh: true);
  }

  void toggleLowStockFilter() {
    _filterLowStock = !_filterLowStock;
    loadInventory(refresh: true);
  }

  Future<bool> updateStock(String uuid, int quantityChange) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedProduct = await _repository.updateProductStock(uuid, quantityChange);
      final index = _products.indexWhere((p) => p.uuid == uuid);
      if (index != -1) {
        _products[index] = updatedProduct;
      }
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
}
