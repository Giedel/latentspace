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
    // core Ledger
    await db.execute(
      '''
      CREATE TABLE core_ai_actions (
        action_id TEXT PRIMARY KEY,
        raw_user_input TEXT NOT NULL,
        inferred_domain TEXT NOT NULL,
        execution_strategy TEXT NOT NULL,
        json_payload TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%d %H:%M:%f', 'now'))
      )
      ''',
    );

    // Finance Ledger
    await db.execute(
      '''
      CREATE TABLE domain_finance_ledger (
        finance_id INTEGER PRIMARY KEY AUTOINCREMENT,
          action_id TEXT NOT NULL UNIQUE,
          transaction_type TEXT NOT NULL,
          amount_cents INTEGER NOT NULL,
          currency TEXT NOT NULL DEFAULT 'PHP',
          primary_category TEXT NOT NULL,
          sub_category TEXT NOT NULL,
          transaction_date TEXT NOT NULL,
          FOREIGN KEY (action_id) REFERENCES core_ai_actions(action_id) ON DELETE CASCADE
      )
      ''',
    );

    // TO-DO:
    // Admin Tasks
    // Vector Tables
    // Dependencies
  }
}