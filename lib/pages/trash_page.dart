import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/widgets/custom_card.dart';
import '../core/widgets/empty_state_widget.dart';
import '../features/ai_orchestrator/providers/core_action_provider.dart';
import '../features/ai_orchestrator/models/core_ai_action.dart';

class TrashPage extends ConsumerWidget {
  const TrashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionsState = ref.watch(coreActionNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Trash Bin', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
            tooltip: 'Empty Trash',
            onPressed: () => _confirmEmptyTrash(context, ref),
          ),
        ],
      ),
      body: actionsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading Trash: $err')),
        data: (actions) {
          final trashedActions = actions.where((a) => a.status == 'FAILED' || a.status == 'REJECTED').toList();

          if (trashedActions.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.delete_outline_rounded,
              title: 'Trash Bin is empty',
              message: 'Items moved to trash will appear here for recovery or deletion.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: trashedActions.length,
            itemBuilder: (context, index) {
              final action = trashedActions[index];
              return _buildTrashTile(context, ref, action);
            },
          );
        },
      ),
    );
  }

  Widget _buildTrashTile(BuildContext context, WidgetRef ref, CoreAiAction action) {
    final bgColors = [const Color(0xFFF4F0FF), const Color(0xFFFFF9E6), const Color(0xFFEFFFF4)];
    final iconColors = [Colors.deepPurple, Colors.orange, Colors.green];
    final colorIndex = action.actionId.hashCode.abs() % bgColors.length;

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      backgroundColor: bgColors[colorIndex],
      onTap: () => _showTrashedItemPreview(context, ref, action, bgColors[colorIndex], iconColors[colorIndex]),
      child: Row(
        children: [
          Icon(
            action.inferredDomain == 'FINANCE' ? Icons.account_balance_wallet_rounded
                : action.inferredDomain == 'NOTE' ? Icons.note_alt_rounded
                : Icons.check_circle_outline_rounded,
            color: iconColors[colorIndex],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.rawUserInput,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  'Moved to trash: ${action.createdAt.month}/${action.createdAt.day}',
                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        ],
      ),
    );
  }

  void _confirmEmptyTrash(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Empty Trash?'),
          content: const Text('All items in the trash bin will be permanently deleted. This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                ref.read(coreActionNotifierProvider.notifier).emptyTrash();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Trash bin emptied'), backgroundColor: Colors.redAccent),
                );
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Empty Trash'),
            )
          ],
        );
      },
    );
  }

  void _showTrashedItemPreview(
      BuildContext context,
      WidgetRef ref,
      CoreAiAction action,
      Color bgColor,
      Color iconColor
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 420),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_delete_rounded, color: iconColor),
                      const SizedBox(width: 8),
                      const Text(
                        'Trashed Item Preview',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '"${action.rawUserInput}"',
                      style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black87, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: _buildDetailsForPreview(action),
                      ),
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          ref.read(coreActionNotifierProvider.notifier).deleteActionPermanently(action.actionId);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Item deleted permanently')),
                          );
                        },
                        icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 18),
                        label: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                      ),
                      FilledButton.icon(
                        onPressed: () {
                          final restored = action.copyWith(status: 'COMPLETED');
                          ref.read(coreActionNotifierProvider.notifier).updateAction(restored);

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Item restored successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        icon: const Icon(Icons.restore_rounded, size: 18),
                        label: const Text('Restore', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6B4FA0)),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildDetailsForPreview(CoreAiAction action) {
    final payload = action.jsonPayload;
    if (action.inferredDomain == 'FINANCE') {
      final amount = payload['amount_cents'] != null ? (payload['amount_cents'] / 100).toStringAsFixed(2) : '0.00';
      return [
        _buildPreviewRow('Amount', '${payload['currency'] ?? 'PHP'} $amount'),
        _buildPreviewRow('Category', payload['primary_category'] ?? 'General'),
      ];
    } else if (action.inferredDomain == 'TO-DO' || action.inferredDomain == 'REMINDER') {
      return [
        _buildPreviewRow('Title', payload['title'] ?? 'N/A'),
        _buildPreviewRow('Due Date', payload['due_date']?.toString().split('T')[0] ?? 'None'),
      ];
    } else {
      return [
        _buildPreviewRow('Content', payload['content'] ?? 'N/A'),
      ];
    }
  }

  Widget _buildPreviewRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.bold))),
          Expanded(child: Text(val, style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}