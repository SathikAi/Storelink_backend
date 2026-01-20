import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';
import 'presentation/screens/business/business_profile_screen.dart';
import 'presentation/screens/reports/reports_screen.dart';
import 'presentation/screens/products/products_list_screen.dart';
import 'presentation/screens/customers/customers_list_screen.dart';
import 'presentation/screens/orders/orders_list_screen.dart';
import 'presentation/screens/categories/categories_list_screen.dart';
import 'presentation/screens/inventory/inventory_list_screen.dart';
import 'presentation/providers/auth_provider.dart';

class StoreLinkApp extends StatelessWidget {
  const StoreLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StoreLink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/business-profile': (context) => const BusinessProfileScreen(),
        '/reports': (context) => const ReportsScreen(),
        '/products': (context) => const ProductsListScreen(),
        '/customers': (context) => const CustomersListScreen(),
        '/orders': (context) => const OrdersListScreen(),
        '/categories': (context) => const CategoriesListScreen(),
        '/inventory': (context) => const InventoryListScreen(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.status == AuthStatus.loading ||
            authProvider.status == AuthStatus.initial) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (authProvider.status == AuthStatus.authenticated) {
          return const DashboardScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
