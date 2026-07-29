import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database_service.dart';
import '../../ai_orchestrator/models/core_ai_action.dart';
import '../../ai_orchestrator/providers/core_action_provider.dart';
import '../models/admin_task.dart';

class TaskRepository {
  final DatabaseService _dbService = DatabaseService();
  final _uuid = const Uuid();

  /// Fetches tasks limited for the Dashboard
  Future<List<AdminTask>> getUpcomingTasks() async {
    final db = await _dbService.database;
    final maps = await db.query(
      'domain_admin_tasks',
      where: 'completion_status = 0',
      orderBy: 'due_date ASC',
      limit: 4,
    );
    return maps.map((map) => AdminTask.fromMap(map)).toList();
  }

  /// Fetches ALL tasks for the To-do Page
  Future<List<AdminTask>> getAllTasks() async {
    final db = await _dbService.database;
    final maps = await db.query(
      'domain_admin_tasks',
      orderBy: 'completion_status ASC, due_date ASC',
    );
    return maps.map((map) => AdminTask.fromMap(map)).toList();
  }

  /// Creates a task directly in DB
  Future<void> createTaskDirectly(String title, {String? dueDate, String? description}) async {
    final db = await _dbService.database;
    final actionId = _uuid.v4();
    final now = DateTime.now();

    final payload = {
      'title': title,
      'description': description ?? 'Manual task entry',
      'due_date': dueDate ?? now.add(const Duration(hours: 4)).toIso8601String(),
      'is_recurring': 0,
      'completion_status': 0,
    };

    // 1. Insert Core Action record
    final action = CoreAiAction(
      actionId: actionId,
      rawUserInput: title,
      inferredDomain: 'TO-DO',
      executionStrategy: 'SINGLE_PASS',
      jsonPayload: payload,
      status: 'COMPLETED',
      createdAt: now,
    );

    await db.insert('core_ai_actions', action.toMap());

    // 2. Insert Domain Admin Task record
    await db.insert('domain_admin_tasks', {
      'action_id': actionId,
      'title': title,
      'description': description,
      'due_date': payload['due_date'],
      'is_recurring': 0,
      'completion_status': 0,
    });
  }

  /// Updates task completion
  Future<void> updateTaskStatus(int taskId, int status) async {
    final db = await _dbService.database;
    await db.update('domain_admin_tasks', {'completion_status': status}, where: 'task_id = ?', whereArgs: [taskId]);
  }

  /// Edits task title
  Future<void> updateTaskTitle(int taskId, String newTitle) async {
    final db = await _dbService.database;
    await db.update('domain_admin_tasks', {'title': newTitle}, where: 'task_id = ?', whereArgs: [taskId]);
  }

  /// Deletes a task by targeting its root Core Action
  Future<void> deleteTaskByActionId(String actionId) async {
    final db = await _dbService.database;
    // 'ON DELETE CASCADE' schema rule automatically deletes task from domain_admin_tasks
    await db.delete('core_ai_actions', where: 'action_id = ?', whereArgs: [actionId]);
  }
}

// --- PROVIDERS ---

final taskRepositoryProvider = Provider<TaskRepository>((ref) => TaskRepository());

final upcomingTasksProvider = FutureProvider<List<AdminTask>>((ref) async {
  ref.watch(coreActionNotifierProvider); // Triggers updates from Dashboard AI approvals
  final repo = ref.read(taskRepositoryProvider);
  return repo.getUpcomingTasks();
});

/// Interactive state controller for the full Todos Page
class TodosNotifier extends StateNotifier<AsyncValue<List<AdminTask>>> {
  TodosNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadAllTasks();
  }

  final Ref ref;

  Future<void> loadAllTasks() async {
    try {
      final repo = ref.read(taskRepositoryProvider);
      final tasks = await repo.getAllTasks();
      if (!mounted) return;
      state = AsyncValue.data(tasks);
    } catch (e, stack) {
      if (!mounted) return;
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addTask(String title, {String? dueDate, String? description}) async {
    await ref.read(taskRepositoryProvider).createTaskDirectly(title, dueDate: dueDate, description: description);
    await loadAllTasks();
    ref.read(coreActionNotifierProvider.notifier).loadActions();
  }

  Future<void> toggleCompletion(AdminTask task) async {
    if (task.taskId == null) return;
    final newStatus = task.completionStatus == 0 ? 1 : 0;

    // Optimistic UI Update
    final currentState = state.value ?? [];
    state = AsyncValue.data(currentState.map((t) {
      if (t.taskId == task.taskId) {
        return AdminTask(
          taskId: t.taskId, actionId: t.actionId, title: t.title, description: t.description,
          dueDate: t.dueDate, isRecurring: t.isRecurring, completionStatus: newStatus,
        );
      }
      return t;
    }).toList());

    await ref.read(taskRepositoryProvider).updateTaskStatus(task.taskId!, newStatus);
    ref.read(coreActionNotifierProvider.notifier).loadActions();
  }

  Future<void> editTaskTitle(AdminTask task, String newTitle) async {
    if (task.taskId == null) return;

    final currentState = state.value ?? [];
    state = AsyncValue.data(currentState.map((t) {
      if (t.taskId == task.taskId) {
        return AdminTask(
          taskId: t.taskId, actionId: t.actionId, title: newTitle, description: t.description,
          dueDate: t.dueDate, isRecurring: t.isRecurring, completionStatus: t.completionStatus,
        );
      }
      return t;
    }).toList());

    await ref.read(taskRepositoryProvider).updateTaskTitle(task.taskId!, newTitle);
  }

  Future<void> deleteTask(AdminTask task) async {
    final currentState = state.value ?? [];
    state = AsyncValue.data(currentState.where((t) => t.actionId != task.actionId).toList());

    await ref.read(taskRepositoryProvider).deleteTaskByActionId(task.actionId);
    ref.read(coreActionNotifierProvider.notifier).loadActions();
  }

  void reorderTasks(int oldIndex, int newIndex) {
    final currentState = List<AdminTask>.from(state.value ?? []);
    final item = currentState.removeAt(oldIndex);
    currentState.insert(newIndex, item);
    state = AsyncValue.data(currentState);
  }
}

final todosNotifierProvider = StateNotifierProvider<TodosNotifier, AsyncValue<List<AdminTask>>>((ref) {
  ref.watch(coreActionNotifierProvider);
  return TodosNotifier(ref);
});