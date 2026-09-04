# 🚀 Database Seeder - Quick Start

## One-Minute Setup

### Step 1: Add the Button to Your App

```dart
import 'package:flutter/foundation.dart';
import 'package:latentspace/core/widgets/seed_database_button.dart';

// In any widget (e.g., your dashboard):
if (kDebugMode) 
  SeedDatabaseButton(
    onSeedComplete: () {
      setState(() {}); // Refresh your UI
    },
  ),
```

### Step 2: Run Your App

```bash
flutter run
```

### Step 3: Tap "Seed Database"

That's it! Your database now has sample data for all modules.

---

## What You Get

✅ **6 AI Actions** - Various domains and statuses  
✅ **6 Finance Transactions** - Income & expenses totaling ₱50K income, ₱7.5K expenses  
✅ **6 Admin Tasks** - Mix of pending and completed  
✅ **6 Context Memories** - User preferences and system state  
✅ **5 Action Dependencies** - Workflow relationships  

---

## Alternative: Full Dev Tools Page

```dart
import 'package:latentspace/pages/dev_tools_page.dart';

// Add to your navigation:
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const DevToolsPage()),
);
```

This gives you:
- Database statistics
- Seed controls
- Real-time record counts

---

## Programmatic Usage

```dart
import 'package:latentspace/core/database/database_seeder.dart';

// Seed all tables
await DatabaseSeeder().seedAll();

// Clear and reseed
await DatabaseSeeder().reseedAll();

// Clear all data
await DatabaseSeeder().clearAll();
```

---

## Sample Data Preview

### Finance Summary
- **Income**: ₱50,000
- **Expenses**: ₱7,550
- **Net**: +₱42,450

### Tasks
- 1 completed, 5 pending
- 2 recurring tasks

### AI Actions
- Domains: Finance, To-Do, Planning, Reminder, Note
- Statuses: Pending, Completed, In Progress, Approved

---

## Need More Info?

- **Full Documentation**: `lib/core/database/SEEDER_README.md`
- **Integration Guide**: `SEEDER_INTEGRATION_GUIDE.md`
- **Complete Overview**: `SEEDER_SUMMARY.md`

---

## Important Notes

⚠️ Always wrap seeder UI in `kDebugMode` checks  
⚠️ Remove seeder buttons before production  
⚠️ `reseedAll()` deletes all existing data  

---

**You're ready to go! Happy coding! 🎉**
