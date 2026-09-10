import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latentspace/core/database/database_service.dart';
import 'package:latentspace/core/providers/theme_provider.dart';
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

class LatentSpaceApp extends ConsumerWidget {
  const LatentSpaceApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeChoice = ref.watch(themeChoiceProvider);

    return MaterialApp(
      title: 'LatentSpace',
      debugShowCheckedModeBanner: false, // hides the debug banner in the top right corner
      theme: switch (themeChoice) {
        AppThemeChoice.ocean => AppTheme.oceanTheme,
        AppThemeChoice.forest => AppTheme.forestTheme,
        AppThemeChoice.sunset => AppTheme.sunsetTheme,
        _ => AppTheme.lightTheme,
      },
      darkTheme: AppTheme.darkTheme,
      themeMode: themeChoice == AppThemeChoice.system ? ThemeMode.system : ThemeMode.light,
      home:const MainLayout(),
    );
  }
}