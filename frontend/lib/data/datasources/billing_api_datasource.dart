import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/token_service.dart';

class BillingApiDatasource {
  final Dio _dio;
  final TokenService _tokenService;

  BillingApiDatasource(this._dio, this._tokenService);

  /// Creates a Dodo Payments payment link for upgrading to the PAID plan.
  /// [planType] is either "monthly" or "yearly".
  /// Returns the payment URL string.
  Future<String> createUpgradePaymentLink({String planType = 'monthly'}) async {
    final token = await _tokenService.getAccessToken();
    final response = await _dio.post(
      '${ApiConstants.baseUrl}/billing/upgrade',
      data: {'plan_type': planType},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data['payment_url'] as String;
  }

  /// Returns current subscription status from /billing/status.
  Future<Map<String, dynamic>> getBillingStatus() async {
    final token = await _tokenService.getAccessToken();
    final response = await _dio.get(
      '${ApiConstants.baseUrl}/billing/status',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data as Map<String, dynamic>;
  }
}
