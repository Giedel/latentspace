import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/theme_provider.dart';
import '../core/widgets/custom_card.dart';
import '../core/widgets/app_feedback.dart';
import '../core/widgets/stat_summary_card.dart';
import '../features/ai_orchestrator/providers/core_action_provider.dart';
import '../features/finance_ledger/providers/finance_provider.dart';
import '../features/user_tasks/providers/task_provider.dart';
import 'agentic_assistant_page.dart';
import 'history_page.dart';
import 'trash_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
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
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Profile Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.surfaceContainer,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // User Avatar Section
            CircleAvatar(
              radius: 44,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                'G',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: primaryColor),
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

            // Live Overview Stats
            Row(
              children: [
                Expanded(
                  child: StatSummaryCard(
                    title: 'Completed Tasks',
                    value: '$completedTasks',
                    icon: Icons.check_circle_outline_rounded,
                    accentColor: primaryColor,
                    backgroundColor: colorScheme.surfaceContainer,
                    valueColor: Colors.black,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatSummaryCard(
                    title: 'Notes Saved',
                    value: '$noteCount',
                    icon: Icons.description_outlined,
                    accentColor: primaryColor,
                    backgroundColor: colorScheme.surfaceContainer,
                    valueColor: Colors.black,
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
                    accentColor: primaryColor,
                    backgroundColor: colorScheme.surfaceContainer,
                    valueColor: Colors.black,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatSummaryCard(
                    title: 'Total Logs',
                    value: '$actionCount',
                    icon: Icons.history_rounded,
                    accentColor: primaryColor,
                    backgroundColor: colorScheme.surfaceContainer,
                    valueColor: Colors.black,
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
                MaterialPageRoute(builder: (context) => const AgenticAssistantPage()),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    child: Icon(Icons.smart_toy_rounded, color: primaryColor),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text('Agentic Assistant Console', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                ],
              ),
            ),

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
                    child: Icon(Icons.history_rounded, color: primaryColor),
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
              onTap: () => _showThemePicker(context, ref),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    child: Icon(Icons.palette_outlined, color: primaryColor),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text('Customize Theme', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                    child: Icon(Icons.delete_outline_rounded, color: primaryColor),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text('Trash Bin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                ],
              ),
            ),

            CustomCard(
              margin: const EdgeInsets.only(bottom: 12),
              onTap: () {
                AppFeedback.show(context, message: 'LatentSpace v1.0.0 (On-Device Gemma 2B SLM Middleware + SQLite)', icon: Icons.info_outline_rounded);
              },
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    child: Icon(Icons.info_outline_rounded, color: primaryColor),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text('About LatentSpace', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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

  void _showThemePicker(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.read(themeChoiceProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;
    const options = [
      (AppThemeChoice.system, 'Phone theme', Icons.phone_android_rounded),
      (AppThemeChoice.defaultTheme, 'Default theme', Icons.auto_awesome_rounded),
      (AppThemeChoice.ocean, 'Ocean', Icons.water_drop_outlined),
      (AppThemeChoice.forest, 'Forest', Icons.forest_outlined),
      (AppThemeChoice.sunset, 'Sunset', Icons.wb_sunny_outlined),
    ];

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Customize Theme'),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((option) {
              final (choice, label, icon) = option;
              return RadioListTile<AppThemeChoice>(
                value: choice,
                groupValue: currentTheme,
                secondary: Icon(icon, color: primaryColor),
                title: Text(label),
                onChanged: (selectedChoice) {
                  if (selectedChoice == null) return;
                  ref.read(themeChoiceProvider.notifier).state = selectedChoice;
                  Navigator.pop(dialogContext);
                  AppFeedback.show(context, message: '$label selected', icon: Icons.palette_outlined);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
