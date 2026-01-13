import 'package:flutter/foundation.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../domain/entities/dashboard_entity.dart';

enum DashboardStatus {
  initial,
  loading,
  loaded,
  error,
}

class DashboardProvider extends ChangeNotifier {
  final DashboardRepository _dashboardRepository;

  DashboardStatus _status = DashboardStatus.initial;
  DashboardStatsEntity? _stats;
  String? _error;

  DashboardProvider(this._dashboardRepository);

  DashboardStatus get status => _status;
  DashboardStatsEntity? get stats => _stats;
  String? get error => _error;

  Future<void> loadDashboardStats({
    String? fromDate,
    String? toDate,
  }) async {
    try {
      _status = DashboardStatus.loading;
      _error = null;
      notifyListeners();

      _stats = await _dashboardRepository.getDashboardStats(
        fromDate: fromDate,
        toDate: toDate,
      );

      _status = DashboardStatus.loaded;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _status = DashboardStatus.error;
      notifyListeners();
    }
  }

  Future<void> refreshStats() async {
    await loadDashboardStats();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
