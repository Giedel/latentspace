import 'package:flutter/material.dart';
import 'package:latentspace/core/database/database_seeder.dart';

/// Standalone script to seed the database
/// 
/// Usage:
/// 1. Call this from main.dart during development
/// 2. Or create a button in your UI to trigger seeding
/// 3. Or run as a one-time setup command
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final seeder = DatabaseSeeder();
  
  print('\n========================================');
  print('   DATABASE SEEDER');
  print('========================================\n');
  
  try {
    // Option 1: Seed all tables (keeps existing data)
    await seeder.seedAll();
    
    // Option 2: Clear and reseed (uncomment if needed)
    // await seeder.reseedAll();
    
    // Option 3: Clear all data only
    // await seeder.clearAll();
    
    print('\n========================================');
    print('   ✅ SEEDING SUCCESSFUL');
    print('========================================\n');
  } catch (e, stackTrace) {
    print('\n========================================');
    print('   ❌ SEEDING FAILED');
    print('========================================');
    print('Error: $e');
    print('Stack trace: $stackTrace');
  }
}
