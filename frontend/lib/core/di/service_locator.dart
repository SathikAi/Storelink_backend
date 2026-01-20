import 'package:dio/dio.dart';
import '../services/token_service.dart';
import '../../data/datasources/auth_api_datasource.dart';
import '../../data/datasources/dashboard_api_datasource.dart';
import '../../data/datasources/business_api_datasource.dart';
import '../../data/datasources/report_api_datasource.dart';
import '../../data/datasources/product_api_datasource.dart';
import '../../data/datasources/customer_api_datasource.dart';
import '../../data/datasources/order_api_datasource.dart';
import '../../data/datasources/admin_api_datasource.dart';
import '../../data/datasources/category_api_datasource.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/repositories/business_repository.dart';
import '../../data/repositories/report_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/dashboard_provider.dart';
import '../../presentation/providers/business_provider.dart';
import '../../presentation/providers/report_provider.dart';
import '../../presentation/providers/product_provider.dart';
import '../../presentation/providers/customer_provider.dart';
import '../../presentation/providers/order_provider.dart';
import '../../presentation/providers/admin_provider.dart';
import '../../presentation/providers/category_provider.dart';
import '../../presentation/providers/inventory_provider.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  late final Dio _dio;
  late final TokenService _tokenService;
  late final AuthApiDatasource _authApiDatasource;
  late final AuthRepository _authRepository;
  late final AuthProvider _authProvider;
  late final DashboardApiDatasource _dashboardApiDatasource;
  late final DashboardRepository _dashboardRepository;
  late final DashboardProvider _dashboardProvider;
  late final BusinessApiDatasource _businessApiDatasource;
  late final BusinessRepository _businessRepository;
  late final BusinessProvider _businessProvider;
  late final ReportApiDatasource _reportApiDatasource;
  late final ReportRepository _reportRepository;
  late final ReportProvider _reportProvider;
  late final ProductApiDatasource _productApiDatasource;
  late final ProductRepository _productRepository;
  late final ProductProvider _productProvider;
  late final CustomerApiDatasource _customerApiDatasource;
  late final CustomerRepository _customerRepository;
  late final CustomerProvider _customerProvider;
  late final OrderApiDatasource _orderApiDatasource;
  late final OrderRepository _orderRepository;
  late final OrderProvider _orderProvider;
  late final CategoryApiDatasource _categoryApiDatasource;
  late final CategoryRepository _categoryRepository;
  late final CategoryProvider _categoryProvider;
  late final InventoryProvider _inventoryProvider;
  late final AdminApiDataSource _adminApiDataSource;
  late final AdminProvider _adminProvider;

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

    _tokenService = TokenService();

    _authApiDatasource = AuthApiDatasource(_dio);
    _authRepository = AuthRepository(_authApiDatasource, _tokenService);
    _authProvider = AuthProvider(_authRepository);

    _dashboardApiDatasource = DashboardApiDatasource(_dio);
    _dashboardRepository = DashboardRepository(_dashboardApiDatasource);
    _dashboardProvider = DashboardProvider(_dashboardRepository);

    _businessApiDatasource = BusinessApiDatasource(_dio);
    _businessRepository = BusinessRepository(_businessApiDatasource);
    _businessProvider = BusinessProvider(_businessRepository);

    _reportApiDatasource = ReportApiDatasource(_dio);
    _reportRepository = ReportRepository(_reportApiDatasource);
    _reportProvider = ReportProvider(_reportRepository);

    _productApiDatasource = ProductApiDatasource(_dio);
    _productRepository = ProductRepository(_productApiDatasource);
    _productProvider = ProductProvider(_productRepository);

    _customerApiDatasource = CustomerApiDatasource(_dio);
    _customerRepository = CustomerRepository(_customerApiDatasource);
    _customerProvider = CustomerProvider(_customerRepository);

    _orderApiDatasource = OrderApiDatasource(_dio);
    _orderRepository = OrderRepository(_orderApiDatasource);
    _orderProvider = OrderProvider(_orderRepository);

    _categoryApiDatasource = CategoryApiDatasource(_dio);
    _categoryRepository = CategoryRepository(_categoryApiDatasource);
    _categoryProvider = CategoryProvider(_categoryRepository);

    _inventoryProvider = InventoryProvider(_productRepository);

    _adminApiDataSource = AdminApiDataSource(client: _dio);
    _adminProvider = AdminProvider(_adminApiDataSource);
  }

  AuthProvider get authProvider => _authProvider;
  DashboardProvider get dashboardProvider => _dashboardProvider;
  BusinessProvider get businessProvider => _businessProvider;
  ReportProvider get reportProvider => _reportProvider;
  ProductProvider get productProvider => _productProvider;
  CustomerProvider get customerProvider => _customerProvider;
  OrderProvider get orderProvider => _orderProvider;
  CategoryProvider get categoryProvider => _categoryProvider;
  InventoryProvider get inventoryProvider => _inventoryProvider;
  AdminProvider get adminProvider => _adminProvider;
}
