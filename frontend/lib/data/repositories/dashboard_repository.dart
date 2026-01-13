import '../datasources/dashboard_api_datasource.dart';
import '../models/dashboard_model.dart';

class DashboardRepository {
  final DashboardApiDatasource _apiDatasource;

  DashboardRepository(this._apiDatasource);

  Future<DashboardStatsModel> getDashboardStats({
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final data = await _apiDatasource.getDashboardStats(
        fromDate: fromDate,
        toDate: toDate,
      );

      return DashboardStatsModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch dashboard stats: ${e.toString()}');
    }
  }
}
