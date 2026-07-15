import '../ai_orchestrator/models/core_ai_action.dart';
import 'package:uuid/uuid.dart';

class SlmService {
  final _uuid = const Uuid();

  /// Simulates an on-device Small Language Model (SLM) parsing unstructured text
  Future<CoreAiAction> processInput(String prompt) async {
    // Simulate inference time for the neural network
    await Future.delayed(const Duration(milliseconds: 1200));

    String inferredDomain = 'NOTE';
    Map<String, dynamic> payload = {};
    String executionStrategy = 'SINGLE_STEP';

    final text = prompt.toLowerCase();

    // Simulated Generative Information Extraction (GIE)
    if (text.contains('remind') || text.contains('task')) {
      inferredDomain = 'TASK';
      payload = {
        'intent': 'create_reminder',
        // Very basic mock extraction logic
        'title': prompt.replaceAll(RegExp(r'remind me to |task: ', caseSensitive: false), '').trim(),
        'due_date': DateTime.now().add(const Duration(hours: 2)).toIso8601String(), 
        'is_recurring': 0,
      };
    } else if (text.contains('spent') || text.contains('bought')) {
      inferredDomain = 'FINANCE';
      payload = {
        'intent': 'record_expense',
        'amount': 0, // In reality, the SLM would extract the integer
        'category': 'Uncategorized',
      };
    } else {
      inferredDomain = 'NOTE';
      payload = {
        'intent': 'save_note',
        'content': prompt,
      };
    }

    return CoreAiAction(
      actionId: _uuid.v4(),
      rawUserInput: prompt,
      inferredDomain: inferredDomain,
      executionStrategy: executionStrategy,
      jsonPayload: payload,
      status: 'PENDING', // ALWAYS PENDING for Human-in-the-Loop validation
      createdAt: DateTime.now(),
    );
  }
}