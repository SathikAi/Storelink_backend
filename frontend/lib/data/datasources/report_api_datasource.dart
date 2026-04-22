import 'package:dio/dio.dart';
import '../../core/services/token_service.dart';
import '../../core/constants/api_constants.dart';
import '../models/report_model.dart';
import 'dart:typed_data';

class FileDownloadResult {
  final Uint8List bytes;
  final String filename;

  const FileDownloadResult({
    required this.bytes,
    required this.filename,
  });
}

class ReportApiDatasource {
  final Dio _dio;
  final TokenService _tokenService;

  ReportApiDatasource(this._dio, this._tokenService);

  Future<SalesReportModel> getSalesReport({
    required String startDate,
    required String endDate,
  }) async {
    final token = await _tokenService.getAccessToken();

    final response = await _dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.reports}/sales',
      queryParameters: {
        'from_date': startDate,
        'to_date': endDate,
      },
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    return SalesReportModel.fromJson(response.data);
  }

  Future<ProductReportModel> getProductReport({
    required String startDate,
    required String endDate,
  }) async {
    final token = await _tokenService.getAccessToken();

    final response = await _dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.reports}/products',
      queryParameters: {
        'from_date': startDate,
        'to_date': endDate,
      },
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    return ProductReportModel.fromJson(response.data);
  }

  Future<CustomerReportModel> getCustomerReport({
    required String startDate,
    required String endDate,
  }) async {
    final token = await _tokenService.getAccessToken();

    final response = await _dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.reports}/customers',
      queryParameters: {
        'from_date': startDate,
        'to_date': endDate,
      },
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    return CustomerReportModel.fromJson(response.data);
  }

  Future<FileDownloadResult> exportPDF({
    required String reportType,
    required String startDate,
    required String endDate,
  }) async {
    final token = await _tokenService.getAccessToken();

    final response = await _dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.reports}/export/pdf',
      queryParameters: {
        'report_type': reportType,
        'from_date': startDate,
        'to_date': endDate,
      },
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        responseType: ResponseType.bytes,
      ),
    );

    final contentDisposition = response.headers['content-disposition']?.first ?? '';
    String filename = 'report.pdf';
    if (contentDisposition.isNotEmpty) {
      final filenameMatch = RegExp(r'filename="?([^"]+)"?').firstMatch(contentDisposition);
      if (filenameMatch != null) {
        filename = filenameMatch.group(1)!;
      }
    }

    return FileDownloadResult(
      bytes: response.data as Uint8List,
      filename: filename,
    );
  }

  Future<FileDownloadResult> exportCSV({
    required String reportType,
    required String startDate,
    required String endDate,
  }) async {
    final token = await _tokenService.getAccessToken();

    final response = await _dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.reports}/export/csv',
      queryParameters: {
        'report_type': reportType,
        'from_date': startDate,
        'to_date': endDate,
      },
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
        responseType: ResponseType.bytes,
      ),
    );

    final contentDisposition = response.headers['content-disposition']?.first ?? '';
    String filename = 'report.csv';
    if (contentDisposition.isNotEmpty) {
      final filenameMatch = RegExp(r'filename="?([^"]+)"?').firstMatch(contentDisposition);
      if (filenameMatch != null) {
        filename = filenameMatch.group(1)!;
      }
    }

    return FileDownloadResult(
      bytes: response.data as Uint8List,
      filename: filename,
    );
  }
}
