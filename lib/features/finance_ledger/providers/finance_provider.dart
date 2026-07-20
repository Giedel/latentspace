import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database_service.dart';
import '../../ai_orchestrator/models/core_ai_action.dart';
import '../../ai_orchestrator/providers/core_action_provider.dart';
import '../models/finance_log.dart';

class FinanceState {
  final List<FinanceLog> logs;
  final double totalBalance;
  final double totalIncome;
  final double totalExpense;

  FinanceState({
    required this.logs,
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
  });
}

class FinanceRepository {
  final DatabaseService _dbService = DatabaseService();
  final _uuid = const Uuid();

  Future<List<FinanceLog>> getAllLogs() async {
    final db = await _dbService.database;
    final maps = await db.query(
      'domain_finance_ledger',
      orderBy: 'transaction_date DESC',
    );
    return maps.map((map) => FinanceLog.fromMap(map)).toList();
  }

  Future<void> createTransactionDirectly({
    required String transactionType,
    required double amount,
    required String primaryCategory,
    String currency = 'PHP',
    String subCategory = 'General',
  }) async {
    final db = await _dbService.database;
    final actionId = _uuid.v4();
    final now = DateTime.now();
    final amountCents = (amount * 100).round();

    final payload = {
      'transaction_type': transactionType,
      'amount_cents': amountCents,
      'currency': currency,
      'primary_category': primaryCategory,
      'sub_category': subCategory,
      'transaction_date': now.toIso8601String(),
    };

    // 1. Insert Core Action
    final action = CoreAiAction(
      actionId: actionId,
      rawUserInput: '$transactionType $currency ${amount.toStringAsFixed(2)} - $primaryCategory',
      inferredDomain: 'FINANCE',
      executionStrategy: 'SINGLE_PASS',
      jsonPayload: payload,
      status: 'COMPLETED',
      createdAt: now,
    );
    await db.insert('core_ai_actions', action.toMap());

    // 2. Insert Finance Ledger record
    await db.insert('domain_finance_ledger', {
      'action_id': actionId,
      'transaction_type': transactionType,
      'amount_cents': amountCents,
      'currency': currency,
      'primary_category': primaryCategory,
      'sub_category': subCategory,
      'transaction_date': now.toIso8601String(),
    });
  }

  Future<void> deleteTransactionByActionId(String actionId) async {
    final db = await _dbService.database;
    await db.delete('core_ai_actions', where: 'action_id = ?', whereArgs: [actionId]);
  }
}

final financeRepositoryProvider = Provider((ref) => FinanceRepository());

final financeNotifierProvider = FutureProvider<FinanceState>((ref) async {
  // Watch core actions to update live balance instantly when AI logs an expense or income
  ref.watch(coreActionNotifierProvider);

  final repo = ref.read(financeRepositoryProvider);
  final logs = await repo.getAllLogs();

  double incomeSum = 0.0;
  double expenseSum = 0.0;

  for (var log in logs) {
    double amount = log.amountCents / 100.0;
    if (log.transactionType == 'EXPENSE') {
      expenseSum += amount;
    } else {
      incomeSum += amount;
    }
  }

  final balance = incomeSum - expenseSum;

  return FinanceState(
    logs: logs,
    totalBalance: balance,
    totalIncome: incomeSum,
    totalExpense: expenseSum,
  );
});