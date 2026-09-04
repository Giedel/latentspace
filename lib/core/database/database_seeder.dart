import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'database_service.dart';

/// Database seeder for populating initial test/demo data
/// Populates all tables with at least 5 records each
class DatabaseSeeder {
  final DatabaseService _dbService = DatabaseService();
  final _uuid = const Uuid();

  /// Seeds all tables with sample data
  Future<void> seedAll() async {
    print('🌱 Starting database seeding...');
    
    await seedCoreAiActions();
    await seedFinanceLedger();
    await seedAdminTasks();
    await seedContextMemory();
    await seedActionDependencies();
    
    print('✅ Database seeding completed!');
  }

  /// Seeds core AI actions table with 5 sample actions
  Future<void> seedCoreAiActions() async {
    final db = await _dbService.database;
    print('Seeding core_ai_actions...');

    final actions = [
      {
        'action_id': _uuid.v4(),
        'raw_user_input': 'Add expense for groceries ₱2,500',
        'inferred_domain': 'FINANCE',
        'execution_strategy': 'SINGLE_PASS',
        'json_payload': jsonEncode({
          'type': 'expense',
          'amount': 2500,
          'category': 'Groceries',
          'description': 'Weekly grocery shopping'
        }),
        'status': 'COMPLETED',
        'created_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      },
      {
        'action_id': _uuid.v4(),
        'raw_user_input': 'Schedule meeting with team tomorrow at 2 PM',
        'inferred_domain': 'TO-DO',
        'execution_strategy': 'SINGLE_PASS',
        'json_payload': jsonEncode({
          'title': 'Team Meeting',
          'time': '2:00 PM',
          'date': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        }),
        'status': 'PENDING',
        'created_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
      },
      {
        'action_id': _uuid.v4(),
        'raw_user_input': 'Record salary income of ₱45,000',
        'inferred_domain': 'FINANCE',
        'execution_strategy': 'SINGLE_PASS',
        'json_payload': jsonEncode({
          'type': 'income',
          'amount': 45000,
          'category': 'Salary',
          'source': 'Monthly salary'
        }),
        'status': 'COMPLETED',
        'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      },
      {
        'action_id': _uuid.v4(),
        'raw_user_input': 'Plan vacation to Boracay next month',
        'inferred_domain': 'PLANNING',
        'execution_strategy': 'MULTI_STEP',
        'json_payload': jsonEncode({
          'destination': 'Boracay',
          'duration': '5 days',
          'month': 'August',
          'tasks': ['Book flights', 'Reserve hotel', 'Plan activities']
        }),
        'status': 'IN_PROGRESS',
        'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'action_id': _uuid.v4(),
        'raw_user_input': 'Create reminder to pay electricity bill',
        'inferred_domain': 'REMINDER',
        'execution_strategy': 'SINGLE_PASS',
        'json_payload': jsonEncode({
          'reminder': 'Pay electricity bill',
          'due_date': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
          'priority': 'high'
        }),
        'status': 'APPROVED',
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'action_id': _uuid.v4(),
        'raw_user_input': 'Note: Recipe for chicken adobo',
        'inferred_domain': 'NOTE',
        'execution_strategy': 'SINGLE_PASS',
        'json_payload': jsonEncode({
          'title': 'Chicken Adobo Recipe',
          'content': 'Ingredients: chicken, soy sauce, vinegar, garlic, bay leaves',
          'tags': ['cooking', 'filipino', 'recipe']
        }),
        'status': 'COMPLETED',
        'created_at': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
      },
    ];

    for (var action in actions) {
      await db.insert('core_ai_actions', action);
    }

    print('✓ Seeded ${actions.length} core AI actions');
  }

  /// Seeds finance ledger table with 6 sample transactions
  Future<void> seedFinanceLedger() async {
    final db = await _dbService.database;
    print('Seeding domain_finance_ledger...');

    // First, get action IDs from core_ai_actions with FINANCE domain
    final financeActions = await db.query(
      'core_ai_actions',
      where: 'inferred_domain = ?',
      whereArgs: ['FINANCE'],
    );

    if (financeActions.isEmpty) {
      print('⚠ Warning: No finance actions found. Skipping finance ledger seeding.');
      return;
    }

    final transactions = [
      {
        'action_id': financeActions[0]['action_id'],
        'transaction_type': 'EXPENSE',
        'amount_cents': 250000, // ₱2,500.00
        'currency': 'PHP',
        'primary_category': 'Food & Dining',
        'sub_category': 'Groceries',
        'transaction_date': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      },
      {
        'action_id': financeActions.length > 1 ? financeActions[1]['action_id'] : _uuid.v4(),
        'transaction_type': 'INCOME',
        'amount_cents': 4500000, // ₱45,000.00
        'currency': 'PHP',
        'primary_category': 'Salary',
        'sub_category': 'Monthly Income',
        'transaction_date': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      },
    ];

    // Add standalone transactions with their own actions
    final additionalTransactions = [
      {
        'transaction_type': 'EXPENSE',
        'amount_cents': 85000, // ₱850.00
        'currency': 'PHP',
        'primary_category': 'Transportation',
        'sub_category': 'Gas',
        'transaction_date': DateTime.now().subtract(const Duration(days: 4)).toIso8601String(),
        'raw_input': 'Gas refill ₱850',
      },
      {
        'transaction_type': 'EXPENSE',
        'amount_cents': 150000, // ₱1,500.00
        'currency': 'PHP',
        'primary_category': 'Shopping',
        'sub_category': 'Clothing',
        'transaction_date': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
        'raw_input': 'Bought new shirt ₱1,500',
      },
      {
        'transaction_type': 'INCOME',
        'amount_cents': 500000, // ₱5,000.00
        'currency': 'PHP',
        'primary_category': 'Freelance',
        'sub_category': 'Project Payment',
        'transaction_date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'raw_input': 'Freelance project payment ₱5,000',
      },
      {
        'transaction_type': 'EXPENSE',
        'amount_cents': 320000, // ₱3,200.00
        'currency': 'PHP',
        'primary_category': 'Utilities',
        'sub_category': 'Electricity',
        'transaction_date': DateTime.now().subtract(const Duration(hours: 12)).toIso8601String(),
        'raw_input': 'Monthly electricity bill ₱3,200',
      },
    ];

    // Create actions for additional transactions
    for (var transaction in additionalTransactions) {
      final actionId = _uuid.v4();
      
      // Create corresponding action
      await db.insert('core_ai_actions', {
        'action_id': actionId,
        'raw_user_input': transaction['raw_input'],
        'inferred_domain': 'FINANCE',
        'execution_strategy': 'SINGLE_PASS',
        'json_payload': jsonEncode({
          'type': transaction['transaction_type']!.toString().toLowerCase(),
          'amount': (transaction['amount_cents'] as int) / 100,
          'category': transaction['primary_category'],
        }),
        'status': 'COMPLETED',
        'created_at': transaction['transaction_date'],
      });

      // Insert finance ledger entry
      transactions.add({
        'action_id': actionId,
        'transaction_type': transaction['transaction_type']!.toString(),
        'amount_cents': transaction['amount_cents'] as int,
        'currency': transaction['currency']!.toString(),
        'primary_category': transaction['primary_category']!.toString(),
        'sub_category': transaction['sub_category']!.toString(),
        'transaction_date': transaction['transaction_date']!.toString(),
      });
    }

    for (var transaction in transactions) {
      await db.insert('domain_finance_ledger', transaction);
    }

    print('✓ Seeded ${transactions.length} finance transactions');
  }

  /// Seeds admin tasks table with 6 sample tasks
  Future<void> seedAdminTasks() async {
    final db = await _dbService.database;
    print('Seeding domain_admin_tasks...');

    // Get action IDs from core_ai_actions with TO-DO domain
    final todoActions = await db.query(
      'core_ai_actions',
      where: 'inferred_domain = ?',
      whereArgs: ['TO-DO'],
    );

    final tasks = <Map<String, dynamic>>[];

    // Use existing action if available
    if (todoActions.isNotEmpty) {
      tasks.add({
        'action_id': todoActions[0]['action_id'],
        'title': 'Team Meeting',
        'description': 'Discuss Q3 project deliverables and timeline',
        'due_date': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        'is_recurring': 0,
        'completion_status': 0,
      });
    }

    // Create standalone tasks with their own actions
    final additionalTasks = [
      {
        'title': 'Submit quarterly report',
        'description': 'Compile and submit Q2 financial report to management',
        'due_date': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        'is_recurring': 0,
        'completion_status': 0,
        'raw_input': 'Submit quarterly report by next week',
      },
      {
        'title': 'Weekly team sync',
        'description': 'Regular Monday morning team synchronization meeting',
        'due_date': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
        'is_recurring': 1,
        'completion_status': 0,
        'raw_input': 'Set up weekly team sync every Monday',
      },
      {
        'title': 'Code review for PR #234',
        'description': 'Review and approve pull request for new authentication feature',
        'due_date': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
        'is_recurring': 0,
        'completion_status': 0,
        'raw_input': 'Review PR #234 by Wednesday',
      },
      {
        'title': 'Update project documentation',
        'description': 'Update README and API documentation for v2.0 release',
        'due_date': DateTime.now().add(const Duration(days: 5)).toIso8601String(),
        'is_recurring': 0,
        'completion_status': 1,
        'raw_input': 'Update documentation for v2.0',
      },
      {
        'title': 'Backup database',
        'description': 'Monthly database backup to cloud storage',
        'due_date': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'is_recurring': 1,
        'completion_status': 0,
        'raw_input': 'Set monthly database backup reminder',
      },
    ];

    // Create actions for additional tasks
    for (var task in additionalTasks) {
      final actionId = _uuid.v4();
      
      // Create corresponding action
      await db.insert('core_ai_actions', {
        'action_id': actionId,
        'raw_user_input': task['raw_input'],
        'inferred_domain': 'TO-DO',
        'execution_strategy': 'SINGLE_PASS',
        'json_payload': jsonEncode({
          'title': task['title'],
          'description': task['description'],
          'due_date': task['due_date'],
        }),
        'status': task['completion_status'] == 1 ? 'COMPLETED' : 'PENDING',
        'created_at': DateTime.now().subtract(const Duration(hours: 12)).toIso8601String(),
      });

      // Insert admin task entry
      tasks.add({
        'action_id': actionId,
        'title': task['title']!.toString(),
        'description': task['description']!.toString(),
        'due_date': task['due_date']!.toString(),
        'is_recurring': task['is_recurring'] as int,
        'completion_status': task['completion_status'] as int,
      });
    }

    for (var task in tasks) {
      await db.insert('domain_admin_tasks', task);
    }

    print('✓ Seeded ${tasks.length} admin tasks');
  }

  /// Seeds context memory table with 5 sample memory entries
  Future<void> seedContextMemory() async {
    final db = await _dbService.database;
    print('Seeding user_context_memory...');

    final memories = [
      {
        'memory_id': _uuid.v4(),
        'entity_type': 'user_preference',
        'entity_key': 'default_currency',
        'entity_value': jsonEncode({
          'currency': 'PHP',
          'symbol': '₱',
          'locale': 'en_PH',
        }),
        'last_accessed': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'memory_id': _uuid.v4(),
        'entity_type': 'user_context',
        'entity_key': 'work_location',
        'entity_value': jsonEncode({
          'location': 'Manila, Philippines',
          'timezone': 'Asia/Manila',
          'office': 'Makati Office',
        }),
        'last_accessed': DateTime.now().subtract(const Duration(hours: 12)).toIso8601String(),
      },
      {
        'memory_id': _uuid.v4(),
        'entity_type': 'user_preference',
        'entity_key': 'notification_settings',
        'entity_value': jsonEncode({
          'email_notifications': true,
          'push_notifications': true,
          'reminder_time': '09:00',
          'quiet_hours': {'start': '22:00', 'end': '07:00'},
        }),
        'last_accessed': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
      },
      {
        'memory_id': _uuid.v4(),
        'entity_type': 'user_context',
        'entity_key': 'favorite_categories',
        'entity_value': jsonEncode({
          'expense': ['Food & Dining', 'Transportation', 'Shopping'],
          'income': ['Salary', 'Freelance', 'Investments'],
        }),
        'last_accessed': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
      },
      {
        'memory_id': _uuid.v4(),
        'entity_type': 'system_state',
        'entity_key': 'last_sync',
        'entity_value': jsonEncode({
          'timestamp': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
          'status': 'success',
          'records_synced': 42,
        }),
        'last_accessed': DateTime.now().toIso8601String(),
      },
      {
        'memory_id': _uuid.v4(),
        'entity_type': 'user_preference',
        'entity_key': 'ui_theme',
        'entity_value': jsonEncode({
          'mode': 'dark',
          'accent_color': '#6200EE',
          'font_size': 'medium',
        }),
        'last_accessed': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
      },
    ];

    for (var memory in memories) {
      await db.insert('user_context_memory', memory);
    }

    print('✓ Seeded ${memories.length} context memory entries');
  }

  /// Seeds action dependencies table with 5 sample dependencies
  Future<void> seedActionDependencies() async {
    final db = await _dbService.database;
    print('Seeding action_dependencies...');

    // Get action IDs for creating dependencies
    final actions = await db.query('core_ai_actions', limit: 10);

    if (actions.length < 2) {
      print('⚠ Warning: Not enough actions for dependencies. Skipping.');
      return;
    }

    final dependencies = [
      {
        'parent_action_id': actions[0]['action_id'],
        'child_action_id': actions[1]['action_id'],
        'execution_order': 1,
        'is_blocking': 1,
      },
      {
        'parent_action_id': actions[1]['action_id'],
        'child_action_id': actions[2]['action_id'],
        'execution_order': 2,
        'is_blocking': 1,
      },
      {
        'parent_action_id': actions[0]['action_id'],
        'child_action_id': actions[3]['action_id'],
        'execution_order': 3,
        'is_blocking': 0,
      },
    ];

    // Add more dependencies if enough actions exist
    if (actions.length >= 5) {
      dependencies.addAll([
        {
          'parent_action_id': actions[3]['action_id'],
          'child_action_id': actions[4]['action_id'],
          'execution_order': 1,
          'is_blocking': 1,
        },
        {
          'parent_action_id': actions[2]['action_id'],
          'child_action_id': actions[4]['action_id'],
          'execution_order': 2,
          'is_blocking': 0,
        },
      ]);
    }

    for (var dependency in dependencies) {
      await db.insert('action_dependencies', dependency);
    }

    print('✓ Seeded ${dependencies.length} action dependencies');
  }

  /// Clears all data from all tables
  Future<void> clearAll() async {
    final db = await _dbService.database;
    print('🗑️ Clearing all database tables...');

    await db.delete('action_dependencies');
    await db.delete('domain_admin_tasks');
    await db.delete('domain_finance_ledger');
    await db.delete('user_context_memory');
    await db.delete('core_ai_actions');

    print('✅ All tables cleared!');
  }

  /// Re-seeds the database (clear then seed)
  Future<void> reseedAll() async {
    await clearAll();
    await seedAll();
  }
}
