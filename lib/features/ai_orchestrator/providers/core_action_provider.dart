import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/core_ai_action.dart';
import '../../../core/providers/database_providers.dart';
import '../services/slm_service.dart';

final slmServiceProvider = Provider<SlmService>((ref) {
  return SlmService();
});

class CoreActionNotifier extends StateNotifier<AsyncValue<List<CoreAiAction>>> {
  CoreActionNotifier(this.ref) : super(const AsyncValue.loading()) {

    // Automatically load actions from the database when initialized
    loadActions();
  }

  final Ref ref;

  // Fetches all actions the SQLite database
  Future<void> loadActions() async {
    try {
      state = const AsyncValue.loading();
      final repo = ref.read(coreActionRepositoryProvider);
      final actions = await repo.getAll();
      state = AsyncValue.data(actions);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Inserts a new action and refreshes the state
  Future<void> addAction(CoreAiAction action) async {
    try {
      final repo = ref.read(coreActionRepositoryProvider);
      await repo.insert(action);
      await loadActions(); // Refresh the state after adding
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Updates an existing action (e.g., changing status from PENDING to COMPLETED) and refreshes the state
  Future<void> updateAction(CoreAiAction action) async {
    try {
      final repo = ref.read(coreActionRepositoryProvider);
      await repo.update(action);
      await loadActions(); // Refresh the state after updating
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Takes raw text, passes it to the AI, and saves the pending result
  Future<void> submitRawPrompt(String prompt) async {
    // 1. Get the AI service
    final slm = ref.read(slmServiceProvider);
    
    // 2. Process the text (simulated SLM extraction)
    final pendingAction = await slm.processInput(prompt);
    
    // 3. Save to the database, which will automatically update the UI
    await addAction(pendingAction);
  }

  /// Routes an approved action's JSON payload to its specific domain table
  Future<void> approveAndRouteAction(CoreAiAction action) async {
    try {
      final db = await ref.read(databaseServiceProvider).database;

      // 1. Immediately flag as APPROVED in the UI while processing
      final approvedAction = action.copyWith(status: 'APPROVED');
      await updateAction(approvedAction);

      // 2. Prepare the payload by injecting the Foreign Key (action_id)
      final Map<String, dynamic> insertData = Map<String, dynamic>.from(action.jsonPayload);
      insertData['action_id'] = action.actionId;

      // 3. Route to the correct Domain Table
      if (action.inferredDomain == 'FINANCE') {
        await db.insert('domain_finance_ledger', insertData);
      } else if (action.inferredDomain == 'TO-DO' || action.inferredDomain == 'REMINDER') {
        await db.insert('domain_admin_tasks', insertData);
      }

      // 4. Finalize as COMPLETED
      final completedAction = action.copyWith(status: 'COMPLETED');
      await updateAction(completedAction);

    } catch (e) {
      print("ROUTING ERROR: $e");
      final failedAction = action.copyWith(status: 'FAILED');
      await updateAction(failedAction);
    }
  }
}

  // The provider that the UI will listen to for changes in the list of actions
final coreActionNotifierProvider = StateNotifierProvider<CoreActionNotifier, AsyncValue<List<CoreAiAction>>>((ref) {
  return CoreActionNotifier(ref);
});