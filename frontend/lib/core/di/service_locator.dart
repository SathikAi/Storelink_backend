import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/auth_api_datasource.dart';
import '../../data/datasources/dashboard_api_datasource.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/dashboard_provider.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  late final Dio _dio;
  late final SharedPreferences _prefs;
  late final AuthApiDatasource _authApiDatasource;
  late final AuthRepository _authRepository;
  late final AuthProvider _authProvider;
  late final DashboardApiDatasource _dashboardApiDatasource;
  late final DashboardRepository _dashboardRepository;
  late final DashboardProvider _dashboardProvider;

  Future<void> init() async {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));

    _prefs = await SharedPreferences.getInstance();

    _authApiDatasource = AuthApiDatasource(_dio);
    _authRepository = AuthRepository(_authApiDatasource, _prefs);
    _authProvider = AuthProvider(_authRepository);

    _dashboardApiDatasource = DashboardApiDatasource(_dio);
    _dashboardRepository = DashboardRepository(_dashboardApiDatasource);
    _dashboardProvider = DashboardProvider(_dashboardRepository);
  }

  AuthProvider get authProvider => _authProvider;
  DashboardProvider get dashboardProvider => _dashboardProvider;
}
