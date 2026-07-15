import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {

  // Prevents multiple database instances from being created.
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'latent.db');

    print('DATABASE PATH: $path');

    return await openDatabase(
      path,
      version: 1,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
    );
  }

  // Enforce referential integrity on every connection
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // Execute your schema upon initial creation
  Future<void> _onCreate(Database db, int version) async {
    // 1. Core Action Ledger: The central nervous system
    await db.execute('''
      CREATE TABLE core_ai_actions (
        action_id TEXT PRIMARY KEY,
        raw_user_input TEXT NOT NULL,
        inferred_domain TEXT NOT NULL,
        execution_strategy TEXT NOT NULL,
        json_payload TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%f', 'now')),
        
        -- Hallucination Defenses & Status States
        CHECK(length(action_id) = 36),
        CHECK(inferred_domain IN ('FINANCE', 'TO-DO', 'REMINDER', 'NOTE', 'PLANNING')),
        CHECK(execution_strategy IN ('SINGLE_PASS', 'MULTI_STEP')),
        CHECK(status IN ('PENDING', 'COMPLETED', 'FAILED', 'APPROVED', 'REJECTED', 'VALIDATING', 'IN_PROGRESS', 'TRASHED')),
        CHECK(json_valid(json_payload) = 1)
      );
    ''');

    // 2. Domain Materials: Finance Ledger
    await db.execute('''
      CREATE TABLE domain_finance_ledger (
        finance_id INTEGER PRIMARY KEY AUTOINCREMENT,
        action_id TEXT NOT NULL UNIQUE,
        transaction_type TEXT NOT NULL,
        amount_cents INTEGER NOT NULL,
        currency TEXT NOT NULL DEFAULT 'PHP',
        primary_category TEXT NOT NULL,
        sub_category TEXT NOT NULL,
        transaction_date TEXT NOT NULL,
        
        FOREIGN KEY (action_id) REFERENCES core_ai_actions(action_id) ON DELETE CASCADE,
        CHECK(transaction_type IN ('EXPENSE', 'INCOME'))
      );
    ''');

    // 3. Domain Materials: Administrative Tasks
    await db.execute('''
      CREATE TABLE domain_admin_tasks (
        task_id INTEGER PRIMARY KEY AUTOINCREMENT,
        action_id TEXT NOT NULL UNIQUE,
        title TEXT NOT NULL,
        description TEXT,
        due_date TEXT,
        is_recurring INTEGER NOT NULL DEFAULT 0,
        completion_status INTEGER NOT NULL DEFAULT 0,
        
        FOREIGN KEY (action_id) REFERENCES core_ai_actions(action_id) ON DELETE CASCADE,
        CHECK(is_recurring IN (0, 1)),
        CHECK(completion_status IN (0, 1))
      );
    ''');

    // 4. Memory Store: Contextual Metadata (RAG)
    await db.execute('''
      CREATE TABLE user_context_memory (
        memory_id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        entity_key TEXT NOT NULL,
        entity_value TEXT NOT NULL,
        last_accessed TEXT NOT NULL,
        
        CHECK(json_valid(entity_value) = 1)
      );
    ''');

    // 5. Agent Orchestration: Action Dependencies (DAG Queue)
    await db.execute('''
      CREATE TABLE action_dependencies (
        dependency_id INTEGER PRIMARY KEY AUTOINCREMENT,
        parent_action_id TEXT NOT NULL,
        child_action_id TEXT NOT NULL,
        execution_order INTEGER NOT NULL,
        is_blocking INTEGER NOT NULL DEFAULT 1,
        
        FOREIGN KEY (parent_action_id) REFERENCES core_ai_actions(action_id) ON DELETE CASCADE,
        FOREIGN KEY (child_action_id) REFERENCES core_ai_actions(action_id) ON DELETE CASCADE,
        CHECK(is_blocking IN (0, 1))
      );
    ''');

    // 6. High-Performance Indexing
    await db.execute('''
      CREATE INDEX idx_pending_actions 
      ON core_ai_actions(action_id) 
      WHERE status = 'PENDING';
    ''');
  }
}