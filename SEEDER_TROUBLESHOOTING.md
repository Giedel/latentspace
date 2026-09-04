# 🔧 Database Seeder - Troubleshooting Guide

Common issues and their solutions when using the database seeder.

## 🚨 Common Errors

### 1. "Foreign key constraint failed"

**Error Message:**
```
SqliteException: FOREIGN KEY constraint failed
```

**Cause:**
- Database schema not initialized
- Parent records don't exist
- Foreign key enforcement not enabled

**Solutions:**

✅ **Solution 1: Reinitialize Database**
```dart
// Delete the app and reinstall to trigger onCreate
// Or manually delete database:
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

final path = join(await getDatabasesPath(), 'latent.db');
await deleteDatabase(path);
// Restart app
```

✅ **Solution 2: Check Schema Creation**
```dart
// Verify onCreate in database_service.dart has run
// Check console for "DATABASE PATH:" message
```

✅ **Solution 3: Verify Foreign Keys Enabled**
```dart
// In database_service.dart, _onConfigure should have:
await db.execute('PRAGMA foreign_keys = ON');
```

---

### 2. "Table doesn't exist"

**Error Message:**
```
SqliteException: no such table: core_ai_actions
```

**Cause:**
- Database not initialized
- Wrong database path
- onCreate not triggered

**Solutions:**

✅ **Solution 1: Force Database Recreation**
```bash
# Uninstall app completely
flutter clean
flutter pub get
flutter run
```

✅ **Solution 2: Check Database Version**
```dart
// In database_service.dart, increment version:
return await openDatabase(
  path,
  version: 2, // Changed from 1
  onUpgrade: (db, oldVersion, newVersion) async {
    // Add migration logic if needed
  },
  onCreate: _onCreate,
);
```

---

### 3. "Not enough actions for dependencies"

**Warning Message:**
```
⚠ Warning: Not enough actions for dependencies. Skipping.
```

**Cause:**
- Insufficient core_ai_actions records
- Database was cleared but not fully seeded

**Solutions:**

✅ **Solution: Reseed All Tables**
```dart
final seeder = DatabaseSeeder();
await seeder.reseedAll(); // Clears and creates fresh data
```

---

### 4. Data Not Appearing in UI

**Symptom:**
- Seeding shows success message
- But UI still shows empty lists

**Cause:**
- State not refreshed after seeding
- Using cached data
- Providers not reloading

**Solutions:**

✅ **Solution 1: Refresh State**
```dart
SeedDatabaseButton(
  onSeedComplete: () {
    setState(() {}); // For StatefulWidget
  },
);
```

✅ **Solution 2: Refresh Providers (Riverpod)**
```dart
SeedDatabaseButton(
  onSeedComplete: () {
    ref.refresh(coreActionProvider);
    ref.refresh(financeProvider);
    ref.refresh(taskProvider);
  },
);
```

✅ **Solution 3: Reload Data**
```dart
SeedDatabaseButton(
  onSeedComplete: () async {
    await context.read<CoreActionProvider>().loadActions();
    await context.read<FinanceProvider>().loadTransactions();
    await context.read<TaskProvider>().loadTasks();
  },
);
```

---

### 5. Seeder Button Not Showing

**Symptom:**
- Can't find seeder button in UI
- DevToolsPage shows "only available in debug mode"

**Cause:**
- Running in release mode
- Missing kDebugMode check
- Wrong import

**Solutions:**

✅ **Solution 1: Verify Debug Mode**
```dart
import 'package:flutter/foundation.dart';

// Check current mode
print('Debug mode: $kDebugMode'); // Should be true
```

✅ **Solution 2: Remove kDebugMode Temporarily**
```dart
// For testing only, remove the condition:
// if (kDebugMode)  // Remove this line
  SeedDatabaseButton(),
```

✅ **Solution 3: Check Build Configuration**
```bash
# Run in debug mode explicitly
flutter run --debug

# NOT release mode
# flutter run --release
```

---

### 6. JSON Decode Error

**Error Message:**
```
FormatException: Unexpected character
```

**Cause:**
- Invalid JSON in json_payload
- Encoding issue

**Solutions:**

✅ **Solution: Check JSON Encoding**
```dart
// Seeder already handles this correctly:
'json_payload': jsonEncode({
  'key': 'value',  // ✓ Correct
}),

// Not this:
'json_payload': '{"key": "value"}', // ✗ Wrong
```

---

### 7. Duplicate Records on Multiple Seeds

**Symptom:**
- Running seedAll() multiple times creates duplicates

**Cause:**
- seedAll() is additive, not replacing

**Solutions:**

✅ **Solution 1: Use reseedAll()**
```dart
// This clears first, then seeds
await DatabaseSeeder().reseedAll();
```

✅ **Solution 2: Clear Before Seeding**
```dart
final seeder = DatabaseSeeder();
await seeder.clearAll();
await seeder.seedAll();
```

✅ **Solution 3: Check Before Seeding**
```dart
final db = await DatabaseService().database;
final result = await db.rawQuery(
  'SELECT COUNT(*) as count FROM core_ai_actions'
);
final count = result.first['count'] as int;

if (count == 0) {
  await DatabaseSeeder().seedAll();
}
```

---

### 8. UUID Package Not Found

**Error Message:**
```
Error: Not found: 'package:uuid/uuid.dart'
```

**Cause:**
- UUID package not in pubspec.yaml
- Dependencies not installed

**Solutions:**

✅ **Solution 1: Check Dependencies**
```yaml
# In pubspec.yaml, should have:
dependencies:
  uuid: ^4.5.3
```

✅ **Solution 2: Install Dependencies**
```bash
flutter pub get
```

---

### 9. Confirmation Dialog Not Showing

**Symptom:**
- Clicking "Clear & Reseed" immediately deletes data
- No confirmation prompt

**Cause:**
- Using seedAll() instead of reseedAll()
- Custom implementation missing dialog

**Solutions:**

✅ **Solution: Use Provided Widgets**
```dart
// Use the provided SeedDatabaseButton widget
// It includes confirmation dialogs automatically
import 'package:latentspace/core/widgets/seed_database_button.dart';

SeedDatabaseButton(), // Has built-in confirmations
```

---

### 10. Loading Indicator Stuck

**Symptom:**
- Button shows "Seeding..." forever
- No error or success message

**Cause:**
- Exception not caught
- Widget unmounted during async operation

**Solutions:**

✅ **Solution 1: Check Console for Errors**
```bash
# Look for stack traces in console
# Fix any exceptions that appear
```

✅ **Solution 2: Add Error Handling**
```dart
try {
  await DatabaseSeeder().seedAll();
} catch (e) {
  print('Seeding error: $e');
  // Handle error
}
```

---

## 🔍 Debugging Tips

### Enable SQL Logging

```dart
// In database_service.dart
return await openDatabase(
  path,
  version: 1,
  onConfigure: (db) async {
    await db.execute('PRAGMA foreign_keys = ON');
    // Enable logging (development only)
    await db.execute('PRAGMA locking_mode = NORMAL');
  },
  onCreate: _onCreate,
);
```

### Check Database Contents

```dart
import 'package:latentspace/core/database/database_service.dart';

Future<void> inspectDatabase() async {
  final db = await DatabaseService().database;
  
  // Check table structure
  final tables = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='table'"
  );
  print('Tables: $tables');
  
  // Count records
  final counts = await db.rawQuery(
    'SELECT COUNT(*) as count FROM core_ai_actions'
  );
  print('Actions: ${counts.first['count']}');
  
  // View sample data
  final samples = await db.query('core_ai_actions', limit: 1);
  print('Sample: $samples');
}
```

### Verify Foreign Keys

```dart
Future<void> checkForeignKeys() async {
  final db = await DatabaseService().database;
  
  final result = await db.rawQuery('PRAGMA foreign_keys');
  print('Foreign keys enabled: $result'); // Should be [{foreign_keys: 1}]
}
```

---

## 📱 Platform-Specific Issues

### Web Platform

**Issue:** Different database path
**Solution:** Seeder handles this automatically via database_service.dart

```dart
if (kIsWeb) {
  databaseFactory = databaseFactoryFfiWeb;
  path = 'latent_web.db';
}
```

### iOS Platform

**Issue:** Database permissions
**Solution:** Already handled by sqflite package

### Android Platform

**Issue:** Database location
**Solution:** Uses standard Android app directory

---

## 🆘 Still Having Issues?

### Checklist Before Asking for Help

1. [ ] Flutter clean and reinstall
2. [ ] Check console for error messages
3. [ ] Verify dependencies installed
4. [ ] Confirm database schema created
5. [ ] Test in fresh app installation
6. [ ] Review error stack trace
7. [ ] Check database file exists

### Diagnostic Information to Provide

When reporting an issue, include:

```dart
import 'package:flutter/foundation.dart';

print('Flutter: ${kDebugMode ? "Debug" : "Release"}');
print('Platform: ${Platform.operatingSystem}');
print('Web: $kIsWeb');

final db = await DatabaseService().database;
print('Database path: ${await db.getPath()}');
print('Database version: ${await db.getVersion()}');
```

### Reset Everything

Last resort - complete reset:

```bash
# 1. Clean Flutter
flutter clean

# 2. Delete app from device/emulator
# (uninstall completely)

# 3. Reinstall dependencies
flutter pub get

# 4. Run app
flutter run

# 5. Try seeding again
```

---

## 💡 Pro Tips

1. **Always test in debug mode first**
2. **Use reseedAll() for clean slate**
3. **Check console after seeding**
4. **Verify data in UI immediately**
5. **Keep backup before clearing**
6. **Use DevToolsPage for visibility**
7. **Monitor record counts**

---

## ✅ Quick Reference

| Error | Quick Fix |
|-------|-----------|
| Foreign key failed | Reinstall app |
| Table doesn't exist | Flutter clean + run |
| Not enough actions | Use reseedAll() |
| Data not in UI | Refresh state/providers |
| Button not showing | Check kDebugMode |
| JSON error | Already handled in seeder |
| Duplicates | Use reseedAll() not seedAll() |
| UUID not found | flutter pub get |
| No confirmation | Use provided widgets |
| Stuck loading | Check console for errors |

---

**Need more help? Check the other documentation files:**
- `SEEDER_README.md` - API documentation
- `SEEDER_INTEGRATION_GUIDE.md` - Integration instructions
- `SEEDER_SUMMARY.md` - Complete overview
