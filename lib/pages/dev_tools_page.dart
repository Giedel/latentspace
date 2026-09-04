import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latentspace/core/widgets/seed_database_button.dart';
import 'package:latentspace/core/database/database_service.dart';

/// Development tools page with database seeding controls
/// Only accessible in debug mode
class DevToolsPage extends StatefulWidget {
  const DevToolsPage({Key? key}) : super(key: key);

  @override
  State<DevToolsPage> createState() => _DevToolsPageState();
}

class _DevToolsPageState extends State<DevToolsPage> {
  final _dbService = DatabaseService();
  Map<String, int> _recordCounts = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRecordCounts();
  }

  Future<void> _loadRecordCounts() async {
    setState(() => _isLoading = true);

    try {
      final db = await _dbService.database;

      final counts = <String, int>{};
      
      // Count records in each table
      final tables = [
        'core_ai_actions',
        'domain_finance_ledger',
        'domain_admin_tasks',
        'user_context_memory',
        'action_dependencies',
      ];

      for (final table in tables) {
        final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
        counts[table] = result.first['count'] as int;
      }

      setState(() => _recordCounts = counts);
    } catch (e) {
      debugPrint('Error loading record counts: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show in debug mode
    if (!kDebugMode) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dev Tools')),
        body: const Center(
          child: Text('Dev tools only available in debug mode'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('🛠️ Development Tools'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecordCounts,
            tooltip: 'Refresh counts',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Database Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.storage, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Database Statistics',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ..._buildRecordCountWidgets(),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Seeder Controls
          SeedDatabaseButton(
            onSeedComplete: () {
              _loadRecordCounts();
            },
          ),

          const SizedBox(height: 16),

          // Information Card
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'About Database Seeding',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '• Seed Database: Adds sample data without deleting existing records\n'
                    '• Clear & Reseed: Deletes all data and creates fresh samples\n'
                    '• Clear All: Removes all data from the database\n\n'
                    'Sample data includes:\n'
                    '• 6 AI Actions (various domains and statuses)\n'
                    '• 6 Finance Transactions (income & expenses)\n'
                    '• 6 Admin Tasks (completed & pending)\n'
                    '• 6 Context Memory entries\n'
                    '• 5 Action Dependencies',
                    style: TextStyle(height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRecordCountWidgets() {
    final tableNames = {
      'core_ai_actions': 'AI Actions',
      'domain_finance_ledger': 'Finance Ledger',
      'domain_admin_tasks': 'Admin Tasks',
      'user_context_memory': 'Context Memory',
      'action_dependencies': 'Dependencies',
    };

    return _recordCounts.entries.map((entry) {
      final displayName = tableNames[entry.key] ?? entry.key;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              displayName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: entry.value > 0 ? Colors.green.shade100 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${entry.value}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: entry.value > 0 ? Colors.green.shade700 : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
