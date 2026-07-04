import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class MoneyPage extends StatelessWidget {
  const MoneyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Financial Ledger"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats / Summary Card
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
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Total Balance',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '₱ 12,450.00',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Recent Logs',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 16),

            // Transaction List Placeholder
            Expanded(
              child: ListView(
                children: [
                  _buildLogItem('Coffee', '₱ 150.00', 'Expense', Icons.coffee),
                  _buildLogItem('Allowance', '₱ 2,000.00', 'Income', Icons.arrow_downward),
                ],
              ),
            )
          ],
        )
      )
    );
  }

  Widget _buildLogItem(String title, String amount, String type, IconData icon) {
    final isExpense = type == 'Expense';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isExpense ? Colors.red.shade100 : Colors.green.shade100,
        child: Icon(icon, color: isExpense ? Colors.red : Colors.green),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(type),
      trailing: Text(
        '${isExpense ? '-' : '+'}$amount',
        style: TextStyle(fontWeight: FontWeight.bold, color: isExpense ? Colors.red : Colors.green, fontSize: 16),
      )
    );
  }
}