# Database Seeder Integration Guide

This guide shows you how to integrate the database seeder into your Flutter app.

## 📁 Files Created

```
lib/
├── core/
│   ├── database/
│   │   ├── database_seeder.dart          # Main seeder class
│   │   └── SEEDER_README.md              # Detailed documentation
│   └── widgets/
│       └── seed_database_button.dart     # UI widgets for seeding
├── scripts/
│   └── seed_database.dart                # Standalone seeding script
└── pages/
    └── dev_tools_page.dart               # Full dev tools page with stats
```

## 🚀 Quick Start

### Option 1: Add Dev Tools Page to Your App (Recommended)

Add a navigation option to access the dev tools page:

```dart
// In your drawer, settings, or debug menu
ListTile(
  leading: const Icon(Icons.build),
  title: const Text('Dev Tools'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DevToolsPage(),
      ),
    );
  },
)
```

Or add a floating action button (debug mode only):

```dart
import 'package:flutter/foundation.dart';
import 'package:latentspace/pages/dev_tools_page.dart';

Scaffold(
  // ... your existing code
  floatingActionButton: kDebugMode 
    ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DevToolsPage(),
            ),
          );
        },
        child: const Icon(Icons.build),
      )
    : null,
)
```

### Option 2: Add Seeder Button to Existing Page

Import and use the button widget:

```dart
import 'package:flutter/foundation.dart';
import 'package:latentspace/core/widgets/seed_database_button.dart';

// In your widget tree
if (kDebugMode) 
  SeedDatabaseButton(
    onSeedComplete: () {
      // Refresh your data here
      setState(() {});
    },
  ),
```

### Option 3: Seed on App Start (Development)

Add to your `main.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:latentspace/core/database/database_seeder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Seed database on first run in debug mode
  if (kDebugMode) {
    final seeder = DatabaseSeeder();
    await seeder.seedAll();
  }
  
  runApp(const MyApp());
}
```

### Option 4: Manual Seeding via Code

Use the seeder programmatically:

```dart
import 'package:latentspace/core/database/database_seeder.dart';

// Seed all tables
final seeder = DatabaseSeeder();
await seeder.seedAll();

// Or seed individual tables
await seeder.seedCoreAiActions();
await seeder.seedFinanceLedger();
await seeder.seedAdminTasks();
await seeder.seedContextMemory();
await seeder.seedActionDependencies();
```

## 📋 Complete Dashboard Integration Example

Here's how to add the seeder to your dashboard with proper state refresh:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latentspace/core/widgets/seed_database_button.dart';
import 'package:latentspace/features/ai_orchestrator/providers/core_action_provider.dart';
import 'package:latentspace/features/finance_ledger/providers/finance_provider.dart';
import 'package:latentspace/features/user_tasks/providers/task_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: ListView(
        children: [
          // Your existing dashboard widgets
          // ...
          
          // Add seeder in debug mode only
          if (kDebugMode) 
            SeedDatabaseButton(
              onSeedComplete: () {
                // Refresh all providers after seeding
                ref.refresh(coreActionProvider);
                ref.refresh(financeProvider);
                ref.refresh(taskProvider);
              },
            ),
        ],
      ),
    );
  }
}
```

## 🎯 Sample Data Overview

The seeder creates the following data:

### Core AI Actions (6 records)
- Grocery expense entry
- Team meeting schedule
- Salary income record
- Vacation planning (multi-step)
- Electricity bill reminder
- Recipe note

### Finance Ledger (6 records)
- **Income**: ₱50,000 total
  - Salary: ₱45,000
  - Freelance: ₱5,000
- **Expenses**: ₱7,550 total
  - Groceries: ₱2,500
  - Gas: ₱850
  - Clothing: ₱1,500
  - Utilities: ₱3,200
- **Net**: +₱42,450

### Admin Tasks (6 records)
- Team meeting (pending)
- Quarterly report submission (pending)
- Weekly team sync (recurring)
- Code review (pending)
- Documentation update (completed)
- Database backup (recurring)

### Context Memory (6 records)
- Default currency preference
- Work location context
- Notification settings
- Favorite categories
- Last sync status
- UI theme preference

### Action Dependencies (5 records)
- Workflow chains with parent-child relationships
- Mix of blocking and non-blocking dependencies

## 🔧 Advanced Usage

### Conditional Seeding Based on Environment

```dart
import 'package:latentspace/core/database/database_seeder.dart';

Future<void> setupDatabase() async {
  final seeder = DatabaseSeeder();
  
  // Check if database is empty
  final db = await DatabaseService().database;
  final result = await db.rawQuery(
    'SELECT COUNT(*) as count FROM core_ai_actions'
  );
  final count = result.first['count'] as int;
  
  // Only seed if empty
  if (count == 0) {
    await seeder.seedAll();
    print('Database seeded with sample data');
  }
}
```

### Custom Seeding Logic

Extend the seeder for your specific needs:

```dart
class CustomDatabaseSeeder extends DatabaseSeeder {
  Future<void> seedMyCustomData() async {
    final db = await DatabaseService().database;
    
    // Add your custom seeding logic here
    await db.insert('my_table', {
      'field': 'value',
    });
  }
  
  @override
  Future<void> seedAll() async {
    await super.seedAll();
    await seedMyCustomData();
  }
}
```

## ⚠️ Important Notes

1. **Debug Mode Only**: Always wrap seeder UI in `kDebugMode` checks
2. **Foreign Keys**: The seeder respects all foreign key constraints
3. **Idempotent**: `seedAll()` can be called multiple times safely
4. **Destructive Operations**: `reseedAll()` and `clearAll()` delete data
5. **Production**: Remove seeder buttons before production release

## 🧪 Testing the Seeder

After integration, test the seeder:

1. Open your app
2. Navigate to the Dev Tools page or find the seeder button
3. Click "Seed Database"
4. Verify data appears in your app's UI
5. Check that all modules show the seeded data

## 🐛 Troubleshooting

### "Foreign key constraint failed"
- Ensure database schema is initialized
- Check that `onCreate` in `database_service.dart` has run

### "Table doesn't exist"
- Delete the app and reinstall to recreate the database
- Or manually delete the database file

### Data not appearing in UI
- Ensure you're refreshing state/providers after seeding
- Check that your data fetching logic is correct

### Seeder button not showing
- Verify you're in debug mode (`kDebugMode` is true)
- Check import paths are correct

## 📚 Additional Resources

- See `lib/core/database/SEEDER_README.md` for detailed API documentation
- Check `database_service.dart` for schema definitions
- Review repository classes for data access patterns

## 🎉 You're Done!

The seeder is now integrated into your app. Use it to quickly populate your database with test data during development.

For questions or issues, refer to the README files or check the inline documentation in the source files.
