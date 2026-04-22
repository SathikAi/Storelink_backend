import 'package:dio/dio.dart';
import '../../core/services/token_service.dart';
import '../../core/constants/api_constants.dart';
import '../models/business_model.dart';
import 'dart:typed_data';

class BusinessApiDatasource {
  final Dio _dio;
  final TokenService _tokenService;

  BusinessApiDatasource(this._dio, this._tokenService);

  Future<BusinessModel> getProfile() async {
    final token = await _tokenService.getAccessToken();

    final response = await _dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.businessProfile}',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    // Backend returns BusinessResponse: { success, message, data: {...} }
    return BusinessModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<BusinessModel> updateProfile(BusinessUpdateRequest request) async {
    final token = await _tokenService.getAccessToken();

    final response = await _dio.put(
      '${ApiConstants.baseUrl}${ApiConstants.businessProfile}',
      data: request.toJson(),
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    return BusinessModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<BusinessModel> uploadLogo(Uint8List imageBytes, String filename) async {
    final token = await _tokenService.getAccessToken();

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        imageBytes,
        filename: filename,
      ),
    });

    final response = await _dio.post(
      '${ApiConstants.baseUrl}${ApiConstants.businessLogo}',
      data: formData,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    // Backend now returns BusinessResponse: { success, message, data: {...} }
    return BusinessModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<BusinessModel> uploadBanner(Uint8List imageBytes, String filename) async {
    final token = await _tokenService.getAccessToken();

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        imageBytes,
        filename: filename,
      ),
    });

    final response = await _dio.post(
      '${ApiConstants.baseUrl}${ApiConstants.businessBanner}',
      data: formData,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    return BusinessModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<BusinessModel> uploadImages(List<Uint8List> imagesBytes, List<String> filenames) async {
    final token = await _tokenService.getAccessToken();

    final formData = FormData();
    for (int i = 0; i < imagesBytes.length; i++) {
      formData.files.add(MapEntry(
        'files',
        MultipartFile.fromBytes(
          imagesBytes[i],
          filename: filenames[i],
        ),
      ));
    }

    final response = await _dio.post(
      '${ApiConstants.baseUrl}${ApiConstants.businessImages}',
      data: formData,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    return BusinessModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getStats() async {
    final token = await _tokenService.getAccessToken();

    final response = await _dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.businessStats}',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    return response.data as Map<String, dynamic>;
  }
}
