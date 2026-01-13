import 'package:flutter/foundation.dart';
import '../../data/datasources/admin_api_datasource.dart';
import '../../data/models/admin_models.dart';

class AdminProvider with ChangeNotifier {
  final AdminApiDataSource _apiDataSource;
  String? _token;

  AdminProvider(this._apiDataSource);

  PlatformStats? _platformStats;
  List<AdminBusinessListItem> _businesses = [];
  List<AdminUserListItem> _users = [];
  PaginationMeta? _businessPagination;
  PaginationMeta? _userPagination;

  bool _isLoading = false;
  String? _error;

  PlatformStats? get platformStats => _platformStats;
  List<AdminBusinessListItem> get businesses => _businesses;
  List<AdminUserListItem> get users => _users;
  PaginationMeta? get businessPagination => _businessPagination;
  PaginationMeta? get userPagination => _userPagination;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setToken(String token) {
    _token = token;
  }

  Future<void> loadPlatformStats() async {
    if (_token == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _platformStats = await _apiDataSource.getPlatformStats(token: _token!);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadBusinesses({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? plan,
    bool? isActive,
  }) async {
    if (_token == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiDataSource.getBusinesses(
        token: _token!,
        page: page,
        pageSize: pageSize,
        search: search,
        plan: plan,
        isActive: isActive,
      );

      _businesses = (data['items'] as List)
          .map((item) => AdminBusinessListItem.fromJson(item))
          .toList();
      _businessPagination = PaginationMeta.fromJson(data['pagination']);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _businesses = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUsers({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? role,
    bool? isActive,
  }) async {
    if (_token == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiDataSource.getUsers(
        token: _token!,
        page: page,
        pageSize: pageSize,
        search: search,
        role: role,
        isActive: isActive,
      );

      _users = (data['items'] as List)
          .map((item) => AdminUserListItem.fromJson(item))
          .toList();
      _userPagination = PaginationMeta.fromJson(data['pagination']);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _users = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateBusinessStatus(String businessUuid, bool isActive) async {
    if (_token == null) return;

    try {
      await _apiDataSource.updateBusinessStatus(
        token: _token!,
        businessUuid: businessUuid,
        isActive: isActive,
      );
      await loadBusinesses();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateBusinessPlan(
    String businessUuid,
    String plan,
    DateTime? planExpiryDate,
  ) async {
    if (_token == null) return;

    try {
      await _apiDataSource.updateBusinessPlan(
        token: _token!,
        businessUuid: businessUuid,
        plan: plan,
        planExpiryDate: planExpiryDate,
      );
      await loadBusinesses();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateUserStatus(String userUuid, bool isActive) async {
    if (_token == null) return;

    try {
      await _apiDataSource.updateUserStatus(
        token: _token!,
        userUuid: userUuid,
        isActive: isActive,
      );
      await loadUsers();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
