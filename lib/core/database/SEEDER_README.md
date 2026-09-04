# Database Seeder

This seeder populates your SQLite database with sample data for testing and development.

## What Gets Seeded

The seeder creates sample data for all modules:

### 1. **Core AI Actions** (6 records)
- Mixed domains: FINANCE, TO-DO, PLANNING, REMINDER, NOTE
- Various statuses: PENDING, COMPLETED, IN_PROGRESS, APPROVED
- Both SINGLE_PASS and MULTI_STEP execution strategies

### 2. **Finance Ledger** (6 records)
- Both EXPENSE and INCOME transactions
- Categories: Groceries, Salary, Gas, Clothing, Freelance, Utilities
- Amounts in Philippine Peso (PHP)
- Linked to core AI actions

### 3. **Admin Tasks** (6 records)
- Mix of completed and pending tasks
- Both one-time and recurring tasks
- Various due dates
- Linked to core AI actions

### 4. **Context Memory** (6 records)
- User preferences (currency, theme, notifications)
- User context (location, favorite categories)
- System state (last sync info)

### 5. **Action Dependencies** (5 records)
- Parent-child relationships between actions
- Both blocking and non-blocking dependencies
- Execution order tracking

## Usage

### Option 1: Using the UI Widget

Add the seeder button to any development/debug screen:

```dart
import 'package:latentspace/core/widgets/seed_database_button.dart';

// Full card widget
SeedDatabaseButton(
  onSeedComplete: () {
    print('Seeding completed!');
    // Refresh your UI here
  },
)

// Or use the FAB version
SeedDatabaseFAB(
  onSeedComplete: () {
    // Refresh your data
  },
)
```

### Option 2: Using the Script

Run the seeder script directly:

```dart
import 'package:latentspace/scripts/seed_database.dart' as seeder;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await seeder.main();
}
```

### Option 3: Programmatic Usage

Use the seeder class in your code:

```dart
import 'package:latentspace/core/database/database_seeder.dart';

// Seed all tables (adds to existing data)
final seeder = DatabaseSeeder();
await seeder.seedAll();

// Clear and reseed (deletes all data first)
await seeder.reseedAll();

// Clear all data only
await seeder.clearAll();

// Seed individual tables
await seeder.seedCoreAiActions();
await seeder.seedFinanceLedger();
await seeder.seedAdminTasks();
await seeder.seedContextMemory();
await seeder.seedActionDependencies();
```

### Option 4: Call from main.dart (Development Only)

Add to your `main.dart` during development:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Only seed in debug mode
  if (kDebugMode) {
    final seeder = DatabaseSeeder();
    await seeder.seedAll();
  }
  
  runApp(const MyApp());
}
```

## Example Integration

Here's how to add a seeder button to your dashboard:

```dart
import 'package:flutter/foundation.dart';
import 'package:latentspace/core/widgets/seed_database_button.dart';

class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: ListView(
        children: [
          // Your existing dashboard widgets
          
          // Add seeder button only in debug mode
          if (kDebugMode) 
            SeedDatabaseButton(
              onSeedComplete: () {
                // Refresh your providers/state
                context.read<CoreActionProvider>().loadActions();
                context.read<FinanceProvider>().loadTransactions();
                context.read<TaskProvider>().loadTasks();
              },
            ),
        ],
      ),
    );
  }
}
```

## Features

✅ **Safe Seeding**: `seedAll()` adds data without deleting existing records  
✅ **Confirmation Dialogs**: UI buttons confirm before destructive operations  
✅ **Foreign Key Compliance**: All relationships properly maintained  
✅ **Realistic Data**: Sample data represents real-world scenarios  
✅ **Loading States**: UI buttons show progress indicators  
✅ **Error Handling**: Graceful error messages and recovery  

## Sample Data Overview

### Finance Transactions
- Total: 6 transactions
- Income: ₱50,000 (Salary ₱45,000 + Freelance ₱5,000)
- Expenses: ₱7,550 (Groceries ₱2,500 + Gas ₱850 + Clothing ₱1,500 + Utilities ₱3,200)
- Net: +₱42,450

### Tasks
- 6 tasks total
- 1 completed, 5 pending
- 2 recurring tasks (weekly sync, monthly backup)
- 4 one-time tasks

### Action Dependencies
- 5 dependency relationships
- Forms a workflow chain
- Mix of blocking and non-blocking dependencies

## Cleanup

To remove all seeded data:

```dart
final seeder = DatabaseSeeder();
await seeder.clearAll();
```

Or use the "Clear All Data" button in the UI widget.

## Best Practices

1. **Development Only**: Only use seeders in development/debug builds
2. **Check Before Seeding**: Verify if data already exists before seeding
3. **Use with Caution**: `reseedAll()` and `clearAll()` are destructive
4. **Refresh UI**: Call data refresh after seeding
5. **Remove Before Release**: Don't include seeder buttons in production builds

## Troubleshooting

### Foreign Key Constraint Failed
- Ensure the database schema is created (`onCreate` has run)
- Check that parent records exist before creating children

### Data Already Exists
- Use `reseedAll()` to clear and reseed
- Or use `clearAll()` first, then `seedAll()`

### Not Enough Actions for Dependencies
- The seeder checks for available actions
- Will skip dependency creation if insufficient actions exist

## Related Files

- `database_seeder.dart` - Main seeder class
- `seed_database.dart` - Standalone script
- `seed_database_button.dart` - UI widgets
- `database_service.dart` - Database initialization
