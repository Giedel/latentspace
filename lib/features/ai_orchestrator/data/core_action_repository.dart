import 'package:sqflite/sqflite.dart';
import 'package:latentspace/core/database/database_service.dart';
import 'package:latentspace/core/database/base_repository.dart';
import 'package:latentspace/features/models/core_ai_action.dart';

class CoreActionRepository implements BaseRepository<CoreAiAction> {
  final DatabaseService _dbService = DatabaseService();
  final String _tableName = 'core_ai_actions';

  @override
  Future<void> insert(CoreAiAction action) async {
    final db = await _dbService.database;
    await db.insert(
      _tableName,
      action.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<CoreAiAction?> getById(String id) async {
    final db = await _dbService.database;
    final maps = await db.query(
      _tableName,
      where: 'action_id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return CoreAiAction.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<List<CoreAiAction>> getAll() async {
    final db = await _dbService.database;
    final maps = await db.query(_tableName, orderBy: 'created_at DESC');
    return maps.map((map) => CoreAiAction.fromMap(map)).toList();
  }

  @override
  Future<void> update(CoreAiAction action) async {
    final db = await _dbService.database;
    await db.update(
      _tableName,
      action.toMap(),
      where: 'action_id = ?',
      whereArgs: [action.actionId],
    );
  }

  @override
  Future<void> delete(String id) async {
    final db = await _dbService.database;
    await db.delete(
      _tableName,
      where: 'action_id = ?',
      whereArgs: [id],
    );
  }
}