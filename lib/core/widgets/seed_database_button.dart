import 'package:flutter/material.dart';
import 'package:latentspace/core/database/database_seeder.dart';

/// Development widget to seed database with sample data
/// Add this button to your debug/dev screen
class SeedDatabaseButton extends StatefulWidget {
  final VoidCallback? onSeedComplete;

  const SeedDatabaseButton({
    Key? key,
    this.onSeedComplete,
  }) : super(key: key);

  @override
  State<SeedDatabaseButton> createState() => _SeedDatabaseButtonState();
}

class _SeedDatabaseButtonState extends State<SeedDatabaseButton> {
  bool _isSeeding = false;

  Future<void> _seedDatabase() async {
    setState(() => _isSeeding = true);

    try {
      final seeder = DatabaseSeeder();
      await seeder.seedAll();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Database seeded successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        widget.onSeedComplete?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Seeding failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSeeding = false);
      }
    }
  }

  Future<void> _reseedDatabase() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Reseed'),
        content: const Text(
          'This will DELETE all existing data and create fresh sample data. '
          'Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete & Reseed'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSeeding = true);

    try {
      final seeder = DatabaseSeeder();
      await seeder.reseedAll();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Database reseeded successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        widget.onSeedComplete?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Reseeding failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSeeding = false);
      }
    }
  }

  Future<void> _clearDatabase() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Clear'),
        content: const Text(
          'This will DELETE all data from the database. '
          'This action cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSeeding = true);

    try {
      final seeder = DatabaseSeeder();
      await seeder.clearAll();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Database cleared successfully!'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        widget.onSeedComplete?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Clearing failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSeeding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.biotech, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Database Seeder',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Populate the database with sample data for testing and development.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isSeeding ? null : _seedDatabase,
              icon: _isSeeding
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_circle_outline),
              label: Text(_isSeeding ? 'Seeding...' : 'Seed Database'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _isSeeding ? null : _reseedDatabase,
              icon: const Icon(Icons.refresh, color: Colors.orange),
              label: const Text('Clear & Reseed'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _isSeeding ? null : _clearDatabase,
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: const Text('Clear All Data'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple floating action button version for quick access
class SeedDatabaseFAB extends StatefulWidget {
  final VoidCallback? onSeedComplete;

  const SeedDatabaseFAB({
    Key? key,
    this.onSeedComplete,
  }) : super(key: key);

  @override
  State<SeedDatabaseFAB> createState() => _SeedDatabaseFABState();
}

class _SeedDatabaseFABState extends State<SeedDatabaseFAB> {
  bool _isSeeding = false;

  Future<void> _seedDatabase() async {
    setState(() => _isSeeding = true);

    try {
      final seeder = DatabaseSeeder();
      await seeder.seedAll();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Database seeded!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSeedComplete?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSeeding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: _isSeeding ? null : _seedDatabase,
      icon: _isSeeding
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.biotech),
      label: Text(_isSeeding ? 'Seeding...' : 'Seed DB'),
      backgroundColor: _isSeeding ? Colors.grey : Colors.blue,
    );
  }
}
