import 'database_service.dart';

class ActionDependency {
  final int? dependencyId;
  final String parentActionId;
  final String childActionId;
  final int executionOrder;
  final int isBlocking;

  ActionDependency({
    this.dependencyId,
    required this.parentActionId,
    required this.childActionId,
    required this.executionOrder,
    this.isBlocking = 1,
  });

  factory ActionDependency.fromMap(Map<String, dynamic> map) {
    return ActionDependency(
      dependencyId: (map['dependency_id'] as num?)?.toInt(),
      parentActionId: map['parent_action_id'].toString(),
      childActionId: map['child_action_id'].toString(),
      executionOrder: (map['execution_order'] as num).toInt(),
      isBlocking: (map['is_blocking'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (dependencyId != null) 'dependency_id': dependencyId,
      'parent_action_id': parentActionId,
      'child_action_id': childActionId,
      'execution_order': executionOrder,
      'is_blocking': isBlocking,
    };
  }
}

class ActionDependencyRepository {
  final DatabaseService _dbService = DatabaseService();

  Future<void> addDependency(ActionDependency dependency) async {
    final db = await _dbService.database;
    await db.insert('action_dependencies', dependency.toMap());
  }

  Future<List<ActionDependency>> getChildrenForParent(String parentActionId) async {
    final db = await _dbService.database;
    final maps = await db.query(
      'action_dependencies',
      where: 'parent_action_id = ?',
      whereArgs: [parentActionId],
      orderBy: 'execution_order ASC',
    );
    return maps.map((m) => ActionDependency.fromMap(m)).toList();
  }

  Future<List<ActionDependency>> getAllDependencies() async {
    final db = await _dbService.database;
    final maps = await db.query('action_dependencies', orderBy: 'execution_order ASC');
    return maps.map((m) => ActionDependency.fromMap(m)).toList();
  }
}
