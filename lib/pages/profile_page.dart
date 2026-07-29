import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/widgets/custom_card.dart';
import '../core/widgets/stat_summary_card.dart';
import '../features/ai_orchestrator/presentation/widgets/slm_model_card.dart';
import '../features/ai_orchestrator/providers/core_action_provider.dart';
import '../features/finance_ledger/providers/finance_provider.dart';
import '../features/user_tasks/providers/task_provider.dart';
import 'history_page.dart';
import 'trash_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionsState = ref.watch(coreActionNotifierProvider);
    final todosState = ref.watch(todosNotifierProvider);
    final financeState = ref.watch(financeNotifierProvider);

    int noteCount = 0;
    int actionCount = 0;
    actionsState.whenData((actions) {
      actionCount = actions.length;
      noteCount = actions.where((a) => a.inferredDomain == 'NOTE' && a.status == 'COMPLETED').length;
    });

    int completedTasks = 0;
    todosState.whenData((tasks) {
      completedTasks = tasks.where((t) => t.completionStatus == 1).length;
    });

    double balance = 0.0;
    financeState.whenData((data) {
      balance = data.totalBalance;
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Profile & SLM Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // User Avatar Section
            const CircleAvatar(
              radius: 44,
              backgroundColor: Color(0xFFF3E5F5),
              child: Text(
                'G',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Color(0xFF6B4FA0)),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Giedel Dela Vega Escobido',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text(
              'giedel.escobido@example.com',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Quantized SLM Model Status Card
            const SlmModelCard(),
            const SizedBox(height: 20),

            // Live Overview Stats
            Row(
              children: [
                Expanded(
                  child: StatSummaryCard(
                    title: 'Completed Tasks',
                    value: '$completedTasks',
                    icon: Icons.check_circle_outline_rounded,
                    accentColor: const Color(0xFF6B4FA0),
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatSummaryCard(
                    title: 'Notes Saved',
                    value: '$noteCount',
                    icon: Icons.description_outlined,
                    accentColor: Colors.amber.shade800,
                    backgroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatSummaryCard(
                    title: 'Net Balance',
                    value: '₱${balance.toStringAsFixed(2)}',
                    icon: Icons.account_balance_wallet_outlined,
                    accentColor: Colors.teal,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatSummaryCard(
                    title: 'Total Logs',
                    value: '$actionCount',
                    icon: Icons.history_rounded,
                    accentColor: Colors.blueAccent,
                    backgroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Menu Items

            CustomCard(
              margin: const EdgeInsets.only(bottom: 12),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryPage()),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B4FA0).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.history_rounded, color: Color(0xFF6B4FA0)),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text('History Ledger', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                ],
              ),
            ),

            CustomCard(
              margin: const EdgeInsets.only(bottom: 12),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TrashPage()),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text('Trash Bin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}