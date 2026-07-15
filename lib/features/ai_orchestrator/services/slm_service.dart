import 'package:uuid/uuid.dart';
import '../models/core_ai_action.dart';

class SlmService {
  final _uuid = const Uuid();

  Future<CoreAiAction> processInput(String prompt) async {
    await Future.delayed(const Duration(milliseconds: 1200));

    String inferredDomain = 'NOTE';
    Map<String, dynamic> payload = {};
    String executionStrategy = 'SINGLE_PASS';

    final text = prompt.toLowerCase();

    if (text.contains('remind') || text.contains('task')) {
      inferredDomain = 'TO-DO'; // Updated domain mapping
      payload = {
        // Maps exactly to domain_admin_tasks columns
        'title': prompt.replaceAll(RegExp(r'remind me to |task: ', caseSensitive: false), '').trim(),
        'description': 'Auto-extracted from: "$prompt"',
        'due_date': DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
        'is_recurring': 0,
        'completion_status': 0,
      };
    } else if (text.contains('spent') || text.contains('bought')) {
      inferredDomain = 'FINANCE'; // Updated domain mapping
      payload = {
        // Maps exactly to domain_finance_ledger columns
        'transaction_type': 'EXPENSE',
        'amount_cents': 15000, // Hardcoded for mock: 150.00 PHP = 15000 cents
        'currency': 'PHP',
        'primary_category': 'Food & Beverage',
        'sub_category': 'Uncategorized',
        'transaction_date': DateTime.now().toIso8601String(),
      };
    } else {
      inferredDomain = 'NOTE';
      payload = { 'content': prompt };
    }

    return CoreAiAction(
      actionId: _uuid.v4(),
      rawUserInput: prompt,
      inferredDomain: inferredDomain,
      executionStrategy: executionStrategy,
      jsonPayload: payload,
      status: 'PENDING',
      createdAt: DateTime.now(),
    );
  }
}