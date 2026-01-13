import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/di/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final serviceLocator = ServiceLocator();
  await serviceLocator.init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: serviceLocator.authProvider),
        ChangeNotifierProvider.value(value: serviceLocator.dashboardProvider),
      ],
      child: const StoreLinkApp(),
    ),
  );
}
