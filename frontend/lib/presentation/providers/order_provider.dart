import 'package:flutter/material.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/order_repository.dart';

class OrderProvider with ChangeNotifier {
  final OrderRepository _repository;

  OrderProvider(this._repository);

  final List<OrderModel> _orders = [];
  OrderModel? _currentOrder;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  String? _searchQuery;
  String? _filterStatus;
  String? _filterPaymentStatus;
  String? _filterCustomerUuid;
  DateTime? _filterFromDate;
  DateTime? _filterToDate;

  List<OrderModel> get orders => _orders;
  OrderModel? get currentOrder => _currentOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  bool get hasMore => _hasMore;
  String? get searchQuery => _searchQuery;

  Future<void> loadOrders({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _orders.clear();
      _hasMore = true;
    }

    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newOrders = await _repository.getOrders(
        page: _currentPage,
        pageSize: 50,
        search: _searchQuery,
        status: _filterStatus,
        paymentStatus: _filterPaymentStatus,
        customerUuid: _filterCustomerUuid,
        fromDate: _filterFromDate,
        toDate: _filterToDate,
      );

      if (newOrders.isEmpty) {
        _hasMore = false;
      } else {
        _orders.addAll(newOrders);
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

  Future<void> searchOrders(String query) async {
    _searchQuery = query.isEmpty ? null : query;
    await loadOrders(refresh: true);
  }

  void setFilters({
    String? status,
    String? paymentStatus,
    String? customerUuid,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    _filterStatus = status;
    _filterPaymentStatus = paymentStatus;
    _filterCustomerUuid = customerUuid;
    _filterFromDate = fromDate;
    _filterToDate = toDate;
    loadOrders(refresh: true);
  }

  void clearFilters() {
    _filterStatus = null;
    _filterPaymentStatus = null;
    _filterCustomerUuid = null;
    _filterFromDate = null;
    _filterToDate = null;
    loadOrders(refresh: true);
  }

  Future<void> loadOrder(String uuid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentOrder = await _repository.getOrder(uuid);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createOrder(OrderCreateRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final order = await _repository.createOrder(request);
      _orders.insert(0, order);
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

  Future<bool> updateOrder(String uuid, OrderUpdateRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final order = await _repository.updateOrder(uuid, request);
      final index = _orders.indexWhere((o) => o.uuid == uuid);
      if (index != -1) {
        _orders[index] = order;
      }
      _currentOrder = order;
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

  Future<bool> cancelOrder(String uuid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final order = await _repository.cancelOrder(uuid);
      final index = _orders.indexWhere((o) => o.uuid == uuid);
      if (index != -1) {
        _orders[index] = order;
      }
      _currentOrder = order;
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

  Future<bool> deleteOrder(String uuid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.deleteOrder(uuid);
      _orders.removeWhere((o) => o.uuid == uuid);
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
