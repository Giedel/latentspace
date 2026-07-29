import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/widgets/app_search_bar.dart';
import '../core/widgets/category_chip.dart';
import '../core/widgets/custom_card.dart';
import '../core/widgets/empty_state_widget.dart';
import '../features/ai_orchestrator/providers/core_action_provider.dart';
import '../features/ai_orchestrator/models/core_ai_action.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  String _selectedDomain = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actionsState = ref.watch(coreActionNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('History Ledger', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                AppSearchBar(
                  controller: _searchController,
                  hintText: 'Search raw prompts & actions...',
                  onChanged: (q) {
                    setState(() => _searchQuery = q.trim().toLowerCase());
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      CategoryChip(
                        label: 'All',
                        isSelected: _selectedDomain == 'All',
                        onTap: () => setState(() => _selectedDomain = 'All'),
                        icon: Icons.history_rounded,
                      ),
                      CategoryChip(
                        label: 'Finance',
                        isSelected: _selectedDomain == 'FINANCE',
                        onTap: () => setState(() => _selectedDomain = 'FINANCE'),
                        icon: Icons.account_balance_wallet_rounded,
                      ),
                      CategoryChip(
                        label: 'To-do',
                        isSelected: _selectedDomain == 'TO-DO',
                        onTap: () => setState(() => _selectedDomain = 'TO-DO'),
                        icon: Icons.check_circle_outline_rounded,
                      ),
                      CategoryChip(
                        label: 'Note',
                        isSelected: _selectedDomain == 'NOTE',
                        onTap: () => setState(() => _selectedDomain = 'NOTE'),
                        icon: Icons.note_alt_rounded,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: actionsState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error loading history: $err')),
              data: (actions) {
                var filtered = actions;

                if (_selectedDomain != 'All') {
                  filtered = filtered.where((a) => a.inferredDomain == _selectedDomain).toList();
                }

                if (_searchQuery.isNotEmpty) {
                  filtered = filtered.where((a) => a.rawUserInput.toLowerCase().contains(_searchQuery)).toList();
                }

                if (filtered.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.history_toggle_off_rounded,
                    title: 'No historical logs found',
                    message: 'Captured prompt logs will appear here.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final action = filtered[index];
                    return _HistoryCard(action: action);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatefulWidget {
  final CoreAiAction action;

  const _HistoryCard({required this.action});

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  bool _isExpanded = false;

  Color _getStatusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'APPROVED':
        return Colors.blue;
      case 'FAILED':
      case 'REJECTED':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.action;
    final statusColor = _getStatusColor(action.status);

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 14),
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      action.status,
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    action.inferredDomain,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey),
                  ),
                ],
              ),
              Icon(
                _isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                color: Colors.grey,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),

          const Text('Raw Input Prompt', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(
            '"${action.rawUserInput}"',
            style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black87),
          ),

          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ID', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                          Text(action.actionId.substring(0, 8), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Strategy', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                          Text(action.executionStrategy, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Payload Details', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildDetailList(action),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      _formatTimestamp(action.createdAt),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                )
              ],
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          )
        ],
      ),
    );
  }

  List<Widget> _buildDetailList(CoreAiAction action) {
    final payload = action.jsonPayload;
    if (action.inferredDomain == 'FINANCE') {
      final amount = payload['amount_cents'] != null ? (payload['amount_cents'] / 100).toStringAsFixed(2) : '0.00';
      return [
        _buildBullet('Amount: ${payload['currency'] ?? 'PHP'} $amount'),
        _buildBullet('Category: ${payload['primary_category'] ?? 'General'}'),
        _buildBullet('Type: ${payload['transaction_type'] ?? 'EXPENSE'}'),
      ];
    } else if (action.inferredDomain == 'TO-DO' || action.inferredDomain == 'REMINDER') {
      return [
        _buildBullet('Title: ${payload['title'] ?? 'N/A'}'),
        _buildBullet('Due Date: ${payload['due_date']?.toString().split('T')[0] ?? 'None'}'),
      ];
    } else {
      return [
        _buildBullet('Content: ${payload['content'] ?? payload.toString()}'),
      ];
    }
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B4FA0))),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.black87))),
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