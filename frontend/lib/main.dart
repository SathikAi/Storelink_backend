import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/di/service_locator.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Supabase.initialize(
      url: 'https://oviksvysiiktbgqllkzn.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im92aWtzdnlzaWlrdGJncWxsa3puIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY4NjkwNjksImV4cCI6MjA5MjQ0NTA2OX0.GkUUE534J8wdsOYhnt81IvZpiolDV3c186Kw1w211eU',
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );

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
