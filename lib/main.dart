import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latentspace/core/database/database_service.dart';
import 'package:latentspace/pages/dashboard_page.dart';
import 'package:latentspace/pages/main_layout.dart';
import 'core/theme/app_theme.dart';

void main() async {
  //Required because we are executing asynchronous code before runApp()
  WidgetsFlutterBinding.ensureInitialized();

  // Boot SQLite
  await DatabaseService().database;

  runApp(
    // ProviderScope is required to use Riverpod
    const ProviderScope(
      child: LatentSpaceApp(),
    )
  );
}

class LatentSpaceApp extends StatelessWidget {
  const LatentSpaceApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LatentSpace',
      debugShowCheckedModeBanner: false, // hides the debug banner in the top right corner
      theme: AppTheme.lightTheme,
      home:const MainLayout(),
    );
  }
}