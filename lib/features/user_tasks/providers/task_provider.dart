import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'; // Handles StateNotifierProvider in Riverpod 3.0+
import 'package:state_notifier/state_notifier.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database_service.dart';
import '../../ai_orchestrator/models/core_ai_action.dart';
import '../../ai_orchestrator/providers/core_action_provider.dart';
import '../../calendar/services/google_calendar_service.dart';
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

  /// Inserts calendar events once and refreshes their title/date on later syncs.
  /// User completion state is deliberately preserved when Google changes an event.
  Future<int> upsertGoogleCalendarEvents(GoogleCalendarSyncData syncData) async {
    final db = await _dbService.database;
    var imported = 0;

    await db.transaction((txn) async {
      for (final event in syncData.events) {
        final existing = await txn.query(
          'google_calendar_events',
          columns: const ['action_id'],
          where: 'event_id = ?',
          whereArgs: [event.id],
          limit: 1,
        );
        final dueDate = event.start.toIso8601String();
        final description = event.description ?? 'Imported from Google Calendar';

        if (existing.isNotEmpty) {
          await txn.update(
            'domain_admin_tasks',
            {'title': event.title, 'description': description, 'due_date': dueDate},
            where: 'action_id = ?',
            whereArgs: [existing.single['action_id']],
          );
          await txn.update(
            'google_calendar_events',
            {'account_email': syncData.accountEmail, 'updated_at': event.updated?.toIso8601String()},
            where: 'event_id = ?',
            whereArgs: [event.id],
          );
          continue;
        }

        final actionId = _uuid.v4();
        final now = DateTime.now();
        final payload = {
          'title': event.title,
          'description': description,
          'due_date': dueDate,
          'source': 'google_calendar',
          'google_event_id': event.id,
        };
        await txn.insert('core_ai_actions', CoreAiAction(
          actionId: actionId,
          rawUserInput: event.title,
          inferredDomain: 'TO-DO',
          executionStrategy: 'SINGLE_PASS',
          jsonPayload: payload,
          status: 'COMPLETED',
          createdAt: now,
        ).toMap());
        await txn.insert('domain_admin_tasks', {
          'action_id': actionId,
          'title': event.title,
          'description': description,
          'due_date': dueDate,
          'is_recurring': 0,
          'completion_status': 0,
        });
        await txn.insert('google_calendar_events', {
          'event_id': event.id,
          'action_id': actionId,
          'account_email': syncData.accountEmail,
          'updated_at': event.updated?.toIso8601String(),
        });
        imported++;
      }
    });
    return imported;
  }
}

class GoogleCalendarImportResult {
  const GoogleCalendarImportResult({
    required this.received,
    required this.imported,
    required this.warnings,
  });

  final int received;
  final int imported;
  final List<String> warnings;
}

// --- PROVIDERS ---

final taskRepositoryProvider = Provider<TaskRepository>((ref) => TaskRepository());

final upcomingTasksProvider = FutureProvider<List<AdminTask>>((ref) async {
  ref.watch(coreActionNotifierProvider); // Triggers updates from Dashboard AI approvals
  final repo = ref.read(taskRepositoryProvider);
  return repo.getUpcomingTasks();
});

/// Interactive state controller for the full Todos Page
class TodosNotifier extends AsyncNotifier<List<AdminTask>> {
  @override
  Future<List<AdminTask>> build() async {
    ref.watch(coreActionNotifierProvider); // Automatically re-builds when core actions change
    final repo = ref.read(taskRepositoryProvider);
    return repo.getAllTasks();
  }

  Future<void> addTask(String title, {String? dueDate, String? description}) async {
    await ref.read(taskRepositoryProvider).createTaskDirectly(title, dueDate: dueDate, description: description);
    ref.invalidateSelf();
    ref.read(coreActionNotifierProvider.notifier).loadActions();
  }

  Future<void> toggleCompletion(AdminTask task) async {
    if (task.taskId == null) return;
    final newStatus = task.completionStatus == 0 ? 1 : 0;

    // Optimistic UI Update
    final currentList = state.value ?? [];
    state = AsyncValue.data(currentList.map((t) {
      if (t.taskId == task.taskId) {
        return AdminTask(
          taskId: t.taskId, actionId: t.actionId, title: t.title, description: t.description,
          dueDate: t.dueDate, isRecurring: t.isRecurring, completionStatus: newStatus,
        );
      }
      return t;
    }).toList());

    await ref.read(taskRepositoryProvider).updateTaskStatus(task.taskId!, newStatus);
    ref.invalidate(upcomingTasksProvider);
    ref.read(coreActionNotifierProvider.notifier).loadActions();
  }

  /// Sets a known completion state. This is used by Undo so it restores the
  /// original value rather than toggling from a stale task snapshot.
  Future<void> setCompletionStatus(AdminTask task, int completionStatus) async {
    if (task.taskId == null) return;

    final currentList = state.value ?? [];
    state = AsyncValue.data(currentList.map((item) {
      if (item.taskId == task.taskId) {
        return AdminTask(
          taskId: item.taskId,
          actionId: item.actionId,
          title: item.title,
          description: item.description,
          dueDate: item.dueDate,
          isRecurring: item.isRecurring,
          completionStatus: completionStatus,
        );
      }
      return item;
    }).toList());

    await ref.read(taskRepositoryProvider).updateTaskStatus(task.taskId!, completionStatus);
    ref.invalidate(upcomingTasksProvider);
    ref.read(coreActionNotifierProvider.notifier).loadActions();
  }

  Future<void> editTaskTitle(AdminTask task, String newTitle) async {
    if (task.taskId == null) return;

    final currentList = state.value ?? [];
    state = AsyncValue.data(currentList.map((t) {
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
    final currentList = state.value ?? [];
    state = AsyncValue.data(currentList.where((t) => t.actionId != task.actionId).toList());

    await ref.read(taskRepositoryProvider).deleteTaskByActionId(task.actionId);
    ref.read(coreActionNotifierProvider.notifier).loadActions();
  }

  Future<GoogleCalendarImportResult?> syncGoogleCalendar() async {
    final syncData = await GoogleCalendarService().loadUpcomingEvents();
    if (syncData == null) return null;
    final imported = await ref.read(taskRepositoryProvider).upsertGoogleCalendarEvents(syncData);
    ref.invalidateSelf();
    ref.read(coreActionNotifierProvider.notifier).loadActions();
    return GoogleCalendarImportResult(
      received: syncData.events.length,
      imported: imported,
      warnings: syncData.warnings,
    );
  }

  void reorderTasks(int oldIndex, int newIndex) {
    final currentList = List<AdminTask>.from(state.value ?? []);
    final item = currentList.removeAt(oldIndex);
    currentList.insert(newIndex, item);
    state = AsyncValue.data(currentList);
  }
}

final todosNotifierProvider = AsyncNotifierProvider<TodosNotifier, List<AdminTask>>(() {
  return TodosNotifier();
});
