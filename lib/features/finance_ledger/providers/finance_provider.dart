import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_service.dart';
import '../../ai_orchestrator/providers/core_action_provider.dart';
import '../models/finance_log.dart';

class FinanceState {
  final List<FinanceLog> logs;
  final double totalBalance;

  FinanceState({required this.logs, required this.totalBalance});
}

class FinanceRepository {
  final DatabaseService _dbService = DatabaseService();

  Future<List<FinanceLog>> getAllLogs() async {
    final db = await _dbService.database;
    final maps = await db.query(
      'domain_finance_ledger',
      orderBy: 'transaction_date DESC', // Newest first
    );
    return maps.map((map) => FinanceLog.fromMap(map)).toList();
  }
}

final financeRepositoryProvider = Provider((ref) => FinanceRepository());

final financeNotifierProvider = FutureProvider<FinanceState>((ref) async {
  // Watch the core actions so the ledger updates instantly when AI logs an expense
  ref.watch(coreActionNotifierProvider);

  final repo = ref.read(financeRepositoryProvider);
  final logs = await repo.getAllLogs();

  // Calculate the live balance
  double balance = 0.0;
  for (var log in logs) {
    double amount = log.amountCents / 100.0; // Convert cents to standard
    if (log.transactionType == 'EXPENSE') {
      balance -= amount;
    } else {
      balance += amount;
    }
  }

  return FinanceState(logs: logs, totalBalance: balance);
});