import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../features/finance_ledger/providers/finance_provider.dart';

class MoneyPage extends ConsumerWidget {
  const MoneyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final financeState = ref.watch(financeNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Financial Ledger", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: financeState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (data) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Live Stats / Summary Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryColor, Color(0xFF9575CD)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        )
                      ]
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Balance',
                        style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        // Format dynamically (e.g., PHP 12450.00)
                        'PHP ${data.totalBalance.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                const Text(
                  'Recent Logs',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Dynamic Transaction List
                Expanded(
                  child: data.logs.isEmpty
                      ? const Center(
                      child: Text("No transactions yet.", style: TextStyle(color: Colors.grey))
                  )
                      : ListView.builder(
                    itemCount: data.logs.length,
                    itemBuilder: (context, index) {
                      final log = data.logs[index];
                      final amount = (log.amountCents / 100).toStringAsFixed(2);
                      final isExpense = log.transactionType == 'EXPENSE';

                      // Map categories to distinct icons dynamically
                      IconData icon = Icons.receipt_long;
                      if (log.primaryCategory.toLowerCase().contains('food') || log.primaryCategory.toLowerCase().contains('coffee')) {
                        icon = Icons.coffee_rounded;
                      } else if (!isExpense) {
                        icon = Icons.arrow_downward_rounded;
                      }

                      return _buildLogItem(
                          log.primaryCategory,
                          '${log.currency} $amount',
                          isExpense ? 'Expense' : 'Income',
                          icon,
                          log.transactionDate
                      );
                    },
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogItem(String title, String amount, String type, IconData icon, String dateISO) {
    final isExpense = type == 'Expense';

    // Parse date for clean subtitle display
    final date = DateTime.tryParse(dateISO);
    final dateDisplay = date != null ? '${date.month}/${date.day}' : '';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isExpense ? Colors.red.shade50 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: isExpense ? Colors.redAccent : Colors.green),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          subtitle: Text('$type • $dateDisplay', style: const TextStyle(fontSize: 12)),
          trailing: Text(
            '${isExpense ? '-' : '+'} $amount',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isExpense ? Colors.redAccent : Colors.green,
                fontSize: 15
            ),
          )
      ),
    );
  }
}