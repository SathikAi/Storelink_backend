import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
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
  bool _isPlanError = false;

  SalesReportModel? get salesReport => _salesReport;
  ProductReportModel? get productReport => _productReport;
  CustomerReportModel? get customerReport => _customerReport;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isPlanError => _isPlanError;

  bool _is403(Object e) {
    if (e is DioException && e.response?.statusCode == 403) return true;
    return false;
  }

  Future<void> loadSalesReport({
    required String startDate,
    required String endDate,
  }) async {
    _isLoading = true;
    _error = null;
    _isPlanError = false;
    notifyListeners();

    try {
      _salesReport = await _repository.getSalesReport(
        startDate: startDate,
        endDate: endDate,
      );
      _error = null;
    } catch (e) {
      if (_is403(e)) {
        _isPlanError = true;
      } else {
        _error = e.toString();
      }
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
    _isPlanError = false;
    notifyListeners();

    try {
      _productReport = await _repository.getProductReport(
        startDate: startDate,
        endDate: endDate,
      );
      _error = null;
    } catch (e) {
      if (_is403(e)) {
        _isPlanError = true;
      } else {
        _error = e.toString();
      }
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
    _isPlanError = false;
    notifyListeners();

    try {
      _customerReport = await _repository.getCustomerReport(
        startDate: startDate,
        endDate: endDate,
      );
      _error = null;
    } catch (e) {
      if (_is403(e)) {
        _isPlanError = true;
      } else {
        _error = e.toString();
      }
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
