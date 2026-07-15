import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/ai_orchestrator/providers/core_action_provider.dart';
import '../features/ai_orchestrator/models/core_ai_action.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionsState = ref.watch(coreActionNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: actionsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading history: $err')),
        data: (actions) {
          // Display all actions (Completed, Failed, Pending, Approved, etc.)
          if (actions.isEmpty) {
            return const Center(child: Text('No historical logs found.', style: TextStyle(color: Colors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              return _HistoryCard(action: action);
            },
          );
        },
      ),
    );
  }
}

/// A stateful widget to handle the expand/collapse animation of individual history cards
class _HistoryCard extends StatefulWidget {
  final CoreAiAction action;

  const _HistoryCard({required this.action});

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final action = widget.action;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- ALWAYS VISIBLE (COLLAPSED STATE) ---

              // Top Row: ID & Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ID: ${action.actionId.toUpperCase()}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey),
                  ),
                  Row(
                    children: [
                      const SizedBox(width: 8),
                      Icon(
                        _isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 16),

              // Text Input Section
              const Text('Text', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                '"${action.rawUserInput}"',
                style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black87),
              ),

              // --- ONLY VISIBLE WHEN EXPANDED ---

              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 32),

                    // Category & Execution Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Category', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(action.inferredDomain, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Execution', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text(
                                action.executionStrategy == 'SINGLE_PASS' ? 'Single Action' : 'Multi Step Flow',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Extracted Details Panel
                    const Text('Extracted Details', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _buildDetailList(action),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Timestamp Row
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          _formatTimestamp(action.createdAt),
                          style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                      ],
                    )
                  ],
                ),
                crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDetailList(CoreAiAction action) {
    final payload = action.jsonPayload;
    if (action.inferredDomain == 'FINANCE') {
      final amount = payload['amount_cents'] != null ? (payload['amount_cents'] / 100).toStringAsFixed(2) : '0.00';
      return [
        _buildBullet('Amount: ${payload['currency'] ?? 'PHP'} $amount'),
        _buildBullet('Category: ${payload['primary_category'] ?? 'Uncategorized'}'),
        _buildBullet('Type: ${payload['transaction_type'] ?? 'Expense'}'),
      ];
    } else if (action.inferredDomain == 'TO-DO' || action.inferredDomain == 'REMINDER') {
      return [
        _buildBullet('Title: ${payload['title'] ?? 'N/A'}'),
        _buildBullet('Due Date: ${payload['due_date'] != null ? payload['due_date'].toString().split('T')[0] : 'None'}'),
      ];
    } else {
      return [
        _buildBullet('Content: ${payload['content'] ?? payload.toString()}'),
      ];
    }
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B4FA0))),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.black54))),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} • $hour:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }
}