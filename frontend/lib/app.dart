import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';
import 'presentation/screens/business/business_profile_screen.dart';
import 'presentation/screens/reports/reports_screen.dart';
import 'presentation/screens/products/products_list_screen.dart';
import 'presentation/screens/customers/customers_list_screen.dart';
import 'presentation/screens/orders/orders_list_screen.dart';
import 'presentation/screens/categories/categories_list_screen.dart';
import 'presentation/screens/inventory/inventory_list_screen.dart';
import 'presentation/screens/business/upgrade_plan_screen.dart';
import 'presentation/screens/store/store_home_screen.dart';
import 'presentation/screens/store/store_product_screen.dart';
import 'presentation/screens/store/store_cart_screen.dart';
import 'presentation/screens/store/store_checkout_screen.dart';
import 'presentation/screens/store/order_confirmation_screen.dart';
import 'presentation/screens/store/order_status_screen.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/store_provider.dart';
import 'data/models/store_models.dart';

class StoreLinkApp extends StatelessWidget {
  const StoreLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'StoreLink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    // ── Auth / Business owner routes ──────────────────────────────────────
    GoRoute(path: '/', builder: (_, __) => const AuthWrapper()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
    GoRoute(path: '/business-profile', builder: (_, __) => const BusinessProfileScreen()),
    GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
    GoRoute(path: '/products', builder: (_, __) => const ProductsListScreen()),
    GoRoute(path: '/customers', builder: (_, __) => const CustomersListScreen()),
    GoRoute(path: '/orders', builder: (_, __) => const OrdersListScreen()),
    GoRoute(path: '/categories', builder: (_, __) => const CategoriesListScreen()),
    GoRoute(path: '/inventory', builder: (_, __) => const InventoryListScreen()),
    GoRoute(path: '/upgrade', builder: (_, __) => const UpgradePlanScreen()),

    // ── Customer store routes (public, no auth needed) ────────────────────
    ShellRoute(
      builder: (context, state, child) {
        return ChangeNotifierProvider(
          create: (_) => StoreProvider(),
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/store/:businessUuid',
          builder: (context, state) {
            final uuid = state.pathParameters['businessUuid']!;
            return StoreHomeScreen(businessUuid: uuid);
          },
          routes: [
            GoRoute(
              path: 'product/:productUuid',
              builder: (context, state) {
                return StoreProductScreen(
                  businessUuid: state.pathParameters['businessUuid']!,
                  productUuid: state.pathParameters['productUuid']!,
                );
              },
            ),
            GoRoute(
              path: 'cart',
              builder: (context, state) {
                return StoreCartScreen(
                  businessUuid: state.pathParameters['businessUuid']!,
                );
              },
            ),
            GoRoute(
              path: 'checkout',
              builder: (context, state) {
                return StoreCheckoutScreen(
                  businessUuid: state.pathParameters['businessUuid']!,
                );
              },
            ),
            GoRoute(
              path: 'confirmed',
              builder: (context, state) {
                final order = state.extra as StoreOrderResult;
                return OrderConfirmationScreen(
                  businessUuid: state.pathParameters['businessUuid']!,
                  order: order,
                );
              },
            ),
            GoRoute(
              path: 'order/:orderNumber',
              builder: (context, state) {
                return OrderStatusScreen(
                  businessUuid: state.pathParameters['businessUuid']!,
                  orderNumber: state.pathParameters['orderNumber']!,
                );
              },
            ),
          ],
        ),
      ],
    ),
  ],
);

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Show loading splash while checking
        if (authProvider.status == AuthStatus.loading ||
            authProvider.status == AuthStatus.initial) {
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6C63FF), Color(0xFF3B3ACF)],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          );
        }

        // Redirect after frame so go_router navigation stack is ready
        if (!_navigated) {
          _navigated = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (authProvider.status == AuthStatus.authenticated) {
              context.go('/dashboard');
            } else {
              context.go('/login');
            }
          });
        }

        // Blank while redirect happens
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
