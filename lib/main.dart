import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latentspace/core/database/database_service.dart';
import 'core/providers/database_providers.dart';

void main() async {
  //Required because we are executing asynchronous code before runApp()
  WidgetsFlutterBinding.ensureInitialized();

  // Boot up the database and enforce PRAGMA foreign_keys = ON immidiately
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('LatentSpace Database Initialized Successfully!'),
        ),
      ),
    );
  }
}