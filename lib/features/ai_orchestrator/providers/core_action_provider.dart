import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/database/action_dependency_repository.dart';
import '../../../core/database/context_memory_repository.dart';
import '../../../core/providers/database_providers.dart';
import '../models/core_ai_action.dart';
import '../services/slm_inference_engine.dart';
import '../services/slm_model_manager.dart';
import '../services/slm_service.dart';

final slmModelManagerProvider = ChangeNotifierProvider<SlmModelManager>((ref) {
  return SlmModelManager();
});

final slmServiceProvider = Provider<SlmService>((ref) {
  return SlmService();
});

final contextMemoryRepositoryProvider = Provider<ContextMemoryRepository>((ref) {
  return ContextMemoryRepository();
});

final actionDependencyRepositoryProvider = Provider<ActionDependencyRepository>((ref) {
  return ActionDependencyRepository();
});

class CoreActionNotifier extends StateNotifier<AsyncValue<List<CoreAiAction>>> {
  CoreActionNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadActions();
  }

  final Ref ref;

  Future<void> loadActions() async {
    try {
      if (!mounted) return;
      state = const AsyncValue.loading();
      final repo = ref.read(coreActionRepositoryProvider);
      final actions = await repo.getAll();
      if (!mounted) return;
      state = AsyncValue.data(actions);
    } catch (e, stackTrace) {
      if (!mounted) return;
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> addAction(CoreAiAction action) async {
    try {
      final repo = ref.read(coreActionRepositoryProvider);
      await repo.insert(action);
      await loadActions();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateAction(CoreAiAction action) async {
    try {
      final repo = ref.read(coreActionRepositoryProvider);
      await repo.update(action);
      await loadActions();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> deleteActionPermanently(String actionId) async {
    try {
      final repo = ref.read(coreActionRepositoryProvider);
      await repo.delete(actionId);
      await loadActions();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> emptyTrash() async {
    try {
      final db = await ref.read(databaseServiceProvider).database;
      await db.delete('core_ai_actions', where: 'status = ? OR status = ?', whereArgs: ['FAILED', 'REJECTED']);
      await loadActions();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> submitRawPrompt(String prompt) async {
    final slm = ref.read(slmServiceProvider);
    await slm.processInput(prompt);
    await loadActions();
  }

  Future<void> approveAndRouteAction(CoreAiAction action, {Map<String, dynamic>? customPayload}) async {
    try {
      final db = await ref.read(databaseServiceProvider).database;
      final payloadToUse = customPayload ?? action.jsonPayload;

      final approvedAction = action.copyWith(
        status: 'APPROVED',
        jsonPayload: payloadToUse,
      );
      await updateAction(approvedAction);

      final Map<String, dynamic> insertData = Map<String, dynamic>.from(payloadToUse);
      insertData['action_id'] = action.actionId;

      if (action.inferredDomain == 'FINANCE') {
        await db.insert('domain_finance_ledger', insertData);
      } else if (action.inferredDomain == 'TO-DO' || action.inferredDomain == 'REMINDER') {
        insertData['is_recurring'] = insertData['is_recurring'] ?? 0;
        insertData['completion_status'] = insertData['completion_status'] ?? 0;
        insertData['title'] = insertData['title'] ?? action.rawUserInput;
        await db.insert('domain_admin_tasks', insertData);
      }

      final completedAction = action.copyWith(
        status: 'COMPLETED',
        jsonPayload: payloadToUse,
      );
      await updateAction(completedAction);
    } catch (e) {
      print("ROUTING ERROR: $e");
      final failedAction = action.copyWith(status: 'FAILED');
      await updateAction(failedAction);
    }
  }
}

final coreActionNotifierProvider = StateNotifierProvider<CoreActionNotifier, AsyncValue<List<CoreAiAction>>>((ref) {
  return CoreActionNotifier(ref);
});

// Chat message representation for the SLM Assistant Agentic Console
class AssistantChatMessage {
  final String sender; // 'user' or 'slm_assistant'
  final String text;
  final String? reasoningThought;
  final String? domainExtracted;
  final DateTime timestamp;

  AssistantChatMessage({
    required this.sender,
    required this.text,
    this.reasoningThought,
    this.domainExtracted,
    required this.timestamp,
  });
}

class AssistantChatNotifier extends StateNotifier<List<AssistantChatMessage>> {
  AssistantChatNotifier(this.ref)
      : super([
          AssistantChatMessage(
            sender: 'slm_assistant',
            text: 'Hello Giedel! I am your on-device SLM Personal Administrator. How can I assist you with your tasks, finances, or notes today?',
            timestamp: DateTime.now(),
          )
        ]);

  final Ref ref;
  final SlmInferenceEngine _engine = SlmInferenceEngine();

  Future<void> sendMessage(String text) async {
    final userMsg = AssistantChatMessage(sender: 'user', text: text, timestamp: DateTime.now());
    state = [...state, userMsg];

    final result = await _engine.runInference(text);

    // Add primary action to core ledger database
    await ref.read(coreActionNotifierProvider.notifier).addAction(result.primaryAction);

    final reply = 'Processed input as [${result.primaryAction.inferredDomain}]. Captured into core SQLite ledger with status PENDING review.';

    final assistantMsg = AssistantChatMessage(
      sender: 'slm_assistant',
      text: reply,
      reasoningThought: result.reasoningThought,
      domainExtracted: result.primaryAction.inferredDomain,
      timestamp: DateTime.now(),
    );

    state = [...state, assistantMsg];
  }
}

final assistantChatNotifierProvider = StateNotifierProvider<AssistantChatNotifier, List<AssistantChatMessage>>((ref) {
  return AssistantChatNotifier(ref);
});