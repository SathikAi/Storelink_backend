import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/di/service_locator.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    final serviceLocator = ServiceLocator();
    await serviceLocator.init();
  
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: serviceLocator.authProvider),
          ChangeNotifierProvider.value(value: serviceLocator.dashboardProvider),
          ChangeNotifierProvider.value(value: serviceLocator.businessProvider),
          ChangeNotifierProvider.value(value: serviceLocator.reportProvider),
          ChangeNotifierProvider.value(value: serviceLocator.productProvider),
          ChangeNotifierProvider.value(value: serviceLocator.customerProvider),
          ChangeNotifierProvider.value(value: serviceLocator.orderProvider),
          ChangeNotifierProvider.value(value: serviceLocator.categoryProvider),
          ChangeNotifierProvider.value(value: serviceLocator.inventoryProvider),
          ChangeNotifierProvider.value(value: serviceLocator.adminProvider),
        ],
        child: const StoreLinkApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('Unhandled error: $error\n$stack');
  });
}
