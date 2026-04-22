import 'package:dio/dio.dart';
import '../models/affiliate_model.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/token_service.dart';

class AffiliateApiDatasource {
  final Dio _dio;
  final TokenService _tokenService;

  AffiliateApiDatasource(this._dio, this._tokenService);

  Future<AffiliateStats> getMyCode() async {
    final token = await _tokenService.getAccessToken();
    final response = await _dio.get(
      '${ApiConstants.baseUrl}/affiliate/my-code',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return AffiliateStats.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<bool> validateCode(String code) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/affiliate/validate',
        data: {'referral_code': code.toUpperCase()},
      );
      return (response.data as Map<String, dynamic>)['valid'] == true;
    } catch (_) {
      return false;
    }
  }
}
