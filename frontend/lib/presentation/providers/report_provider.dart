import 'package:flutter/foundation.dart';
import '../../data/models/report_model.dart';
import '../../data/repositories/report_repository.dart';
import '../../data/datasources/report_api_datasource.dart';

class ReportProvider with ChangeNotifier {
  final ReportRepository _repository;

  ReportProvider(this._repository);

  SalesReportModel? _salesReport;
  ProductReportModel? _productReport;
  CustomerReportModel? _customerReport;
  bool _isLoading = false;
  String? _error;

  SalesReportModel? get salesReport => _salesReport;
  ProductReportModel? get productReport => _productReport;
  CustomerReportModel? get customerReport => _customerReport;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSalesReport({
    required String startDate,
    required String endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _salesReport = await _repository.getSalesReport(
        startDate: startDate,
        endDate: endDate,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadProductReport({
    required String startDate,
    required String endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _productReport = await _repository.getProductReport(
        startDate: startDate,
        endDate: endDate,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCustomerReport({
    required String startDate,
    required String endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _customerReport = await _repository.getCustomerReport(
        startDate: startDate,
        endDate: endDate,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<FileDownloadResult?> exportPDF({
    required String reportType,
    required String startDate,
    required String endDate,
  }) async {
    try {
      return await _repository.exportPDF(
        reportType: reportType,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<FileDownloadResult?> exportCSV({
    required String reportType,
    required String startDate,
    required String endDate,
  }) async {
    try {
      return await _repository.exportCSV(
        reportType: reportType,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
