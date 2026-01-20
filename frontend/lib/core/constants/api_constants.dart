class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/v1',
  );
  
  static String get uploadUrl => baseUrl.replaceAll('/v1', '/uploads');
  
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authOtpSend = '/auth/otp/send';
  static const String authOtpVerify = '/auth/otp/verify';
  static const String authRefresh = '/auth/refresh';
  static const String authMe = '/auth/me';
  
  static const String businessProfile = '/business/profile';
  static const String businessLogo = '/business/logo';
  static const String businessStats = '/business/stats';
  
  static const String dashboardStats = '/dashboard/stats';
  
  static const String categories = '/categories';
  static const String products = '/products';
  static const String customers = '/customers';
  static const String orders = '/orders';
  static const String reports = '/reports';
  static const String admin = '/admin';
}
