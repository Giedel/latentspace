import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/ai_orchestrator/providers/core_action_provider.dart';
import '../features/ai_orchestrator/models/core_ai_action.dart';

class TrashPage extends ConsumerWidget {
  const TrashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionsState = ref.watch(coreActionNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash Bin', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: actionsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading Trash: $err')),
        data: (actions) {
          // Trashed items correspond to core action status == 'FAILED'
          final trashedActions = actions.where((a) => a.status == 'FAILED').toList();

          if (trashedActions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.delete_outline_rounded, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Trash is empty', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                ],
              ),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: bgColors[colorIndex],
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          action.inferredDomain == 'FINANCE' ? Icons.account_balance_wallet_rounded
              : action.inferredDomain == 'NOTE' ? Icons.note_alt_rounded
              : Icons.check_circle_outline_rounded,
          color: iconColors[colorIndex],
        ),
        title: Text(
          action.rawUserInput,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          'Moved to trash on: ${action.createdAt.month}/${action.createdAt.day}',
          style: const TextStyle(fontSize: 11, color: Colors.black38),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: () => _showTrashedItemPreview(context, ref, action, bgColors[colorIndex], iconColors[colorIndex]),
      ),
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lock_clock_rounded, color: iconColor),
                      const SizedBox(width: 8),
                      const Text(
                          'Trashed Item Preview',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // The uneditable raw conversational phrase
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '"${action.rawUserInput}"',
                      style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black87, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('Details (Uneditable in Trash)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 8),

                  // Detail list based on the target category
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: _buildDetailsForPreview(action),
                      ),
                    ),
                  ),

                  // Actions row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close', style: TextStyle(color: Colors.black54)),
                      ),
                      FilledButton.icon(
                        onPressed: () {
                          // RESTORE OPTION: Revert state status to COMPLETED
                          final restoredAction = action.copyWith(status: 'COMPLETED');
                          ref.read(coreActionNotifierProvider.notifier).updateAction(restoredAction);

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Item restored successfully!'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        },
                        icon: const Icon(Icons.restore_rounded, size: 18),
                        label: const Text('Restore', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF6B4FA0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
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
        _buildPreviewRow('Category', payload['primary_category'] ?? 'Uncategorized'),
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