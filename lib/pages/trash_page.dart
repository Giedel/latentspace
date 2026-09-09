import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/widgets/custom_card.dart';
import '../core/widgets/empty_state_widget.dart';
import '../core/widgets/app_feedback.dart';
import '../core/theme/app_theme.dart';
import '../features/ai_orchestrator/providers/core_action_provider.dart';
import '../features/ai_orchestrator/models/core_ai_action.dart';

class TrashPage extends ConsumerWidget {
  const TrashPage({super.key});

  static const _themeColor = AppTheme.primaryColor;

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
            icon: const Icon(Icons.delete_forever_rounded, color: _themeColor),
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
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 12),
      // Match the scaffold surface so the shadow is visible only outside the
      // white outline, rather than showing through the card interior.
      backgroundColor: AppTheme.appBackgroundColor,
      border: Border.all(color: Colors.white, width: 1.2),
      elevation: 0.8,
      onTap: () => _showTrashedItemPreview(context, ref, action),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              action.inferredDomain == 'FINANCE' ? Icons.account_balance_wallet_rounded
                  : action.inferredDomain == 'NOTE' ? Icons.note_alt_rounded
                  : Icons.check_circle_outline_rounded,
              color: _themeColor,
            ),
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
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: Colors.white, width: 1.2),
          ),
          title: const Row(
            children: [
              Icon(Icons.delete_forever_rounded, color: _themeColor),
              SizedBox(width: 10),
              Text('Empty Trash?'),
            ],
          ),
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
                AppFeedback.show(context, message: 'Trash bin emptied', icon: Icons.delete_outline_rounded);
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_delete_rounded, color: _themeColor),
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
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white),
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
                          AppFeedback.show(context, message: 'Item deleted permanently', icon: Icons.delete_forever_rounded);
                        },
                        icon: const Icon(Icons.delete_forever_rounded, color: _themeColor, size: 18),
                        label: const Text('Delete', style: TextStyle(color: _themeColor)),
                      ),
                      FilledButton.icon(
                        onPressed: () async {
                          await ref.read(coreActionNotifierProvider.notifier).restoreFromTrash(action);
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          AppFeedback.show(
                            context,
                            message: action.status == 'REJECTED'
                                ? 'Item restored for review'
                                : 'Item restored successfully!',
                            icon: Icons.restore_rounded,
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
