import 'package:flutter/foundation.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/category_repository.dart';

class CategoryProvider with ChangeNotifier {
  final CategoryRepository _repository;

  CategoryProvider(this._repository);

  final List<CategoryModel> _categories = [];
  CategoryModel? _currentCategory;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  bool? _filterIsActive;

  List<CategoryModel> get categories => _categories;
  CategoryModel? get currentCategory => _currentCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  Future<void> loadCategories({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _categories.clear();
      _hasMore = true;
      _isLoading = false; // reset so refresh always proceeds
    }

    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      const pageSize = 50;
      final newCategories = await _repository.getCategories(
        page: _currentPage,
        pageSize: pageSize,
        isActive: _filterIsActive,
      );

      _categories.addAll(newCategories);
      if (newCategories.length < pageSize) {
        _hasMore = false;
      } else {
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

  void setFilter({bool? isActive}) {
    _filterIsActive = isActive;
    loadCategories(refresh: true);
  }

  Future<void> loadCategory(String uuid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentCategory = await _repository.getCategory(uuid);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCategory(CategoryCreateRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.createCategory(request);
      await loadCategories(refresh: true);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateCategory(String uuid, CategoryUpdateRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _repository.updateCategory(uuid, request);
      
      // Update in list
      final index = _categories.indexWhere((c) => c.uuid == uuid);
      if (index != -1) {
        _categories[index] = updated;
      }
      
      // Update current
      if (_currentCategory?.uuid == uuid) {
        _currentCategory = updated;
      }
      
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteCategory(String uuid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.deleteCategory(uuid);
      _categories.removeWhere((c) => c.uuid == uuid);
      if (_currentCategory?.uuid == uuid) {
        _currentCategory = null;
      }
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
