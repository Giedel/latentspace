import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/core_ai_action.dart';
import '../../../core/providers/database_providers.dart';

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

  // The provider that the UI will listen to for changes in the list of actions
  final coreActionNotifierProvider = StateNotifierProvider<CoreActionNotifier, AsyncValue<List<CoreAiAction>>>((ref) {
    return CoreActionNotifier(ref);
  });
}