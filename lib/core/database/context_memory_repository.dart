import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'database_service.dart';

class UserContextMemory {
  final String memoryId;
  final String entityType;
  final String entityKey;
  final Map<String, dynamic> entityValue;
  final DateTime lastAccessed;

  UserContextMemory({
    required this.memoryId,
    required this.entityType,
    required this.entityKey,
    required this.entityValue,
    required this.lastAccessed,
  });

  factory UserContextMemory.fromMap(Map<String, dynamic> map) {
    return UserContextMemory(
      memoryId: map['memory_id'].toString(),
      entityType: map['entity_type'].toString(),
      entityKey: map['entity_key'].toString(),
      entityValue: Map<String, dynamic>.from(jsonDecode(map['entity_value'].toString())),
      lastAccessed: DateTime.parse(map['last_accessed'].toString()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memory_id': memoryId,
      'entity_type': entityType,
      'entity_key': entityKey,
      'entity_value': jsonEncode(entityValue),
      'last_accessed': lastAccessed.toIso8601String(),
    };
  }
}

class ContextMemoryRepository {
  final DatabaseService _dbService = DatabaseService();
  final _uuid = const Uuid();

  Future<List<UserContextMemory>> getAllMemory() async {
    final db = await _dbService.database;
    final maps = await db.query('user_context_memory', orderBy: 'last_accessed DESC');
    return maps.map((m) => UserContextMemory.fromMap(m)).toList();
  }

  Future<UserContextMemory?> getByKey(String key) async {
    final db = await _dbService.database;
    final maps = await db.query(
      'user_context_memory',
      where: 'entity_key = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      return UserContextMemory.fromMap(maps.first);
    }
    return null;
  }

  Future<void> saveContextMemory({
    required String entityType,
    required String entityKey,
    required Map<String, dynamic> entityValue,
  }) async {
    final db = await _dbService.database;
    final now = DateTime.now();

    final existing = await getByKey(entityKey);
    if (existing != null) {
      await db.update(
        'user_context_memory',
        {
          'entity_type': entityType,
          'entity_value': jsonEncode(entityValue),
          'last_accessed': now.toIso8601String(),
        },
        where: 'entity_key = ?',
        whereArgs: [entityKey],
      );
    } else {
      final memory = UserContextMemory(
        memoryId: _uuid.v4(),
        entityType: entityType,
        entityKey: entityKey,
        entityValue: entityValue,
        lastAccessed: now,
      );
      await db.insert('user_context_memory', memory.toMap());
    }
  }

  Future<void> deleteMemory(String memoryId) async {
    final db = await _dbService.database;
    await db.delete('user_context_memory', where: 'memory_id = ?', whereArgs: [memoryId]);
  }
}
