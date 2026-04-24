import 'package:flutter/material.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/customer_repository.dart';

class CustomerProvider with ChangeNotifier {
  final CustomerRepository _repository;

  CustomerProvider(this._repository);

  final List<CustomerModel> _customers = [];
  CustomerModel? _currentCustomer;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  String? _searchQuery;
  bool? _filterIsActive;

  List<CustomerModel> get customers => _customers;
  CustomerModel? get currentCustomer => _currentCustomer;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  bool get hasMore => _hasMore;
  String? get searchQuery => _searchQuery;

  Future<void> loadCustomers({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _customers.clear();
      _hasMore = true;
      _isLoading = false; // reset so refresh always proceeds
    }

    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      const pageSize = 50;
      final newCustomers = await _repository.getCustomers(
        page: _currentPage,
        pageSize: pageSize,
        search: _searchQuery,
        isActive: _filterIsActive,
      );

      _customers.addAll(newCustomers);
      if (newCustomers.length < pageSize) {
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

  Future<void> searchCustomers(String query) async {
    _searchQuery = query.isEmpty ? null : query;
    await loadCustomers(refresh: true);
  }

  void setFilters({bool? isActive}) {
    _filterIsActive = isActive;
    loadCustomers(refresh: true);
  }

  void clearFilters() {
    _filterIsActive = null;
    loadCustomers(refresh: true);
  }

  Future<void> loadCustomer(String uuid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentCustomer = await _repository.getCustomer(uuid);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCustomer(CustomerCreateRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final customer = await _repository.createCustomer(request);
      _customers.insert(0, customer);
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

  Future<bool> updateCustomer(String uuid, CustomerUpdateRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final customer = await _repository.updateCustomer(uuid, request);
      final index = _customers.indexWhere((c) => c.uuid == uuid);
      if (index != -1) {
        _customers[index] = customer;
      }
      _currentCustomer = customer;
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

  Future<bool> deleteCustomer(String uuid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.deleteCustomer(uuid);
      _customers.removeWhere((c) => c.uuid == uuid);
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
