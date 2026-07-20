import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/category_chip.dart';
import '../core/widgets/custom_card.dart';
import '../core/widgets/empty_state_widget.dart';
import '../core/widgets/stat_summary_card.dart';
import '../features/finance_ledger/providers/finance_provider.dart';

class MoneyPage extends ConsumerStatefulWidget {
  const MoneyPage({super.key});

  @override
  ConsumerState<MoneyPage> createState() => _MoneyPageState();
}

class _MoneyPageState extends ConsumerState<MoneyPage> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final financeState = ref.watch(financeNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text("Financial Ledger", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_card_rounded, color: Color(0xFF6B4FA0)),
            onPressed: () => _showAddTransactionDialog(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransactionDialog(context),
        backgroundColor: const Color(0xFF6B4FA0),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Transaction', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: financeState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (data) {
          final categories = ['All', 'Food & Beverage', 'Groceries', 'Transportation', 'Utilities', 'Shopping', 'Income'];
          var logs = data.logs;

          if (_selectedCategory != 'All') {
            logs = logs.where((l) => l.primaryCategory == _selectedCategory).toList();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16).copyWith(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Balance Card
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
                    ],
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
                        'PHP ${data.totalBalance.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Income / Expense Stat Cards Grid
                Row(
                  children: [
                    Expanded(
                      child: StatSummaryCard(
                        title: 'Total Income',
                        value: '₱${data.totalIncome.toStringAsFixed(2)}',
                        icon: Icons.arrow_downward_rounded,
                        accentColor: Colors.green,
                        backgroundColor: Colors.green.shade50.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatSummaryCard(
                        title: 'Total Expense',
                        value: '₱${data.totalExpense.toStringAsFixed(2)}',
                        icon: Icons.arrow_upward_rounded,
                        accentColor: Colors.redAccent,
                        backgroundColor: Colors.red.shade50.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Category Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((cat) {
                      return CategoryChip(
                        label: cat,
                        isSelected: _selectedCategory == cat,
                        onTap: () => setState(() => _selectedCategory = cat),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Recent Transactions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),

                // Logs List
                if (logs.isEmpty) ...[
                  const EmptyStateWidget(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'No transactions yet',
                    message: 'Use the + button or prompt AI to record expenses or income.',
                  )
                ] else ...[
                  ...logs.map((log) {
                    final amount = (log.amountCents / 100).toStringAsFixed(2);
                    final isExpense = log.transactionType == 'EXPENSE';

                    IconData icon = Icons.receipt_long_rounded;
                    if (log.primaryCategory.toLowerCase().contains('food') || log.primaryCategory.toLowerCase().contains('coffee')) {
                      icon = Icons.coffee_rounded;
                    } else if (log.primaryCategory.toLowerCase().contains('groceries')) {
                      icon = Icons.shopping_basket_rounded;
                    } else if (log.primaryCategory.toLowerCase().contains('transport')) {
                      icon = Icons.directions_car_rounded;
                    } else if (log.primaryCategory.toLowerCase().contains('utility')) {
                      icon = Icons.bolt_rounded;
                    } else if (!isExpense) {
                      icon = Icons.attach_money_rounded;
                    }

                    return CustomCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isExpense ? Colors.red.shade50 : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: isExpense ? Colors.redAccent : Colors.green),
                        ),
                        title: Text(log.primaryCategory, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        subtitle: Text('${isExpense ? "Expense" : "Income"} • ${_formatDate(log.transactionDate)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${isExpense ? '-' : '+'} ${log.currency} $amount',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isExpense ? Colors.redAccent : Colors.green,
                                fontSize: 15,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 18),
                              onPressed: () {
                                ref.read(financeRepositoryProvider).deleteTransactionByActionId(log.actionId);
                                ref.refresh(financeNotifierProvider);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Transaction deleted')),
                                );
                              },
                            )
                          ],
                        ),
                      ),
                    );
                  })
                ]
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String isoString) {
    final d = DateTime.tryParse(isoString);
    if (d == null) return '';
    return '${d.month}/${d.day}';
  }

  void _showAddTransactionDialog(BuildContext context) {
    final amountController = TextEditingController();
    String type = 'EXPENSE';
    String category = 'Food & Beverage';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Add Transaction', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount (PHP)',
                      prefixIcon: Icon(Icons.attach_money_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'EXPENSE', child: Text('Expense')),
                      DropdownMenuItem(value: 'INCOME', child: Text('Income')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          type = val;
                          category = val == 'INCOME' ? 'Income' : 'Food & Beverage';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'Food & Beverage', child: Text('Food & Beverage')),
                      DropdownMenuItem(value: 'Groceries', child: Text('Groceries')),
                      DropdownMenuItem(value: 'Transportation', child: Text('Transportation')),
                      DropdownMenuItem(value: 'Utilities', child: Text('Utilities')),
                      DropdownMenuItem(value: 'Shopping', child: Text('Shopping')),
                      DropdownMenuItem(value: 'Income', child: Text('Income')),
                      DropdownMenuItem(value: 'General', child: Text('General')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => category = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                FilledButton(
                  onPressed: () async {
                    final amt = double.tryParse(amountController.text.trim());
                    if (amt != null && amt > 0) {
                      await ref.read(financeRepositoryProvider).createTransactionDirectly(
                        transactionType: type,
                        amount: amt,
                        primaryCategory: category,
                      );
                      ref.refresh(financeNotifierProvider);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Transaction saved!'), backgroundColor: Colors.green),
                        );
                      }
                    }
                  },
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6B4FA0)),
                  child: const Text('Save'),
                )
              ],
            );
          },
        );
      },
    );
  }
}