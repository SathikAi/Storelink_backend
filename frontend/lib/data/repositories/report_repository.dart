import '../datasources/report_api_datasource.dart';
import '../models/report_model.dart';

class ReportRepository {
  final ReportApiDatasource _apiDatasource;

  ReportRepository(this._apiDatasource);

  Future<SalesReportModel> getSalesReport({
    required String startDate,
    required String endDate,
  }) async {
    return await _apiDatasource.getSalesReport(
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<ProductReportModel> getProductReport({
    required String startDate,
    required String endDate,
  }) async {
    return await _apiDatasource.getProductReport(
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<CustomerReportModel> getCustomerReport({
    required String startDate,
    required String endDate,
  }) async {
    return await _apiDatasource.getCustomerReport(
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<FileDownloadResult> exportPDF({
    required String reportType,
    required String startDate,
    required String endDate,
  }) async {
    return await _apiDatasource.exportPDF(
      reportType: reportType,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<FileDownloadResult> exportCSV({
    required String reportType,
    required String startDate,
    required String endDate,
  }) async {
    return await _apiDatasource.exportCSV(
      reportType: reportType,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
