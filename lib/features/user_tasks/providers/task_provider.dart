import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/database/database_service.dart';
import '../../ai_orchestrator/providers/core_action_provider.dart';
import '../models/admin_task.dart';

class TaskRepository {
  final DatabaseService _dbService = DatabaseService();

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
      orderBy: 'completion_status ASC, due_date ASC', // Uncompleted tasks bubble to the top
    );
    return maps.map((map) => AdminTask.fromMap(map)).toList();
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
    // Because of your 'ON DELETE CASCADE' schema rule, deleting the core action
    // safely obliterates the task from the domain_admin_tasks table automatically.
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

/// The interactive state controller for the full Todos Page
class TodosNotifier extends StateNotifier<AsyncValue<List<AdminTask>>> {
  TodosNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadAllTasks();
  }

  final Ref ref;

  Future<void> loadAllTasks() async {
    try {
      final repo = ref.read(taskRepositoryProvider);
      final tasks = await repo.getAllTasks();
      state = AsyncValue.data(tasks);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> toggleCompletion(AdminTask task) async {
    if (task.taskId == null) return;
    final newStatus = task.completionStatus == 0 ? 1 : 0;

    // 1. Optimistic UI Update (Makes the checkbox feel instant to the user)
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

    // 2. Background DB Update
    await ref.read(taskRepositoryProvider).updateTaskStatus(task.taskId!, newStatus);
    ref.read(coreActionNotifierProvider.notifier).loadActions(); // Syncs dashboard
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
    ref.read(coreActionNotifierProvider.notifier).loadActions(); // Syncs dashboard
  }

  // Handles drag-and-drop reordering in local memory
  void reorderTasks(int oldIndex, int newIndex) {
    final currentState = List<AdminTask>.from(state.value ?? []);

    // The manual newIndex -= 1 math has been removed because Flutter does it now!
    final item = currentState.removeAt(oldIndex);
    currentState.insert(newIndex, item);

    state = AsyncValue.data(currentState);
  }
}

final todosNotifierProvider = StateNotifierProvider<TodosNotifier, AsyncValue<List<AdminTask>>>((ref) {
  ref.watch(coreActionNotifierProvider); // Auto-refreshes when AI extracts a new task
  return TodosNotifier(ref);
});