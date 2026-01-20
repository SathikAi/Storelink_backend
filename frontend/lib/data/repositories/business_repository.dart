import 'dart:typed_data';
import '../datasources/business_api_datasource.dart';
import '../models/business_model.dart';

class BusinessRepository {
  final BusinessApiDatasource _apiDatasource;

  BusinessRepository(this._apiDatasource);

  Future<BusinessModel> getProfile() async {
    return await _apiDatasource.getProfile();
  }

  Future<BusinessModel> updateProfile(BusinessUpdateRequest request) async {
    return await _apiDatasource.updateProfile(request);
  }

  Future<BusinessModel> uploadLogo(Uint8List imageBytes, String filename) async {
    return await _apiDatasource.uploadLogo(imageBytes, filename);
  }

  Future<Map<String, dynamic>> getStats() async {
    return await _apiDatasource.getStats();
  }
}
