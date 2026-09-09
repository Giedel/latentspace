import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../features/finance_ledger/providers/finance_provider.dart';
import '../features/user_tasks/models/admin_task.dart';
import '../features/user_tasks/providers/task_provider.dart';
import 'main_layout.dart';

final notificationReadIdsProvider = StateProvider<Set<String>>((ref) => <String>{});
final notificationDeletedIdsProvider = StateProvider<Set<String>>((ref) => <String>{});

enum NotificationDestination { todos, money }

class AppNotification {
  final String id;
  final IconData icon;
  final String title;
  final String message;
  final String detail;
  final Color color;
  final NotificationDestination destination;

  const AppNotification({
    required this.id,
    required this.icon,
    required this.title,
    required this.message,
    required this.detail,
    required this.color,
    required this.destination,
  });
}

List<AppNotification> buildAppNotifications({
  required AsyncValue<List<AdminTask>> todosState,
  required AsyncValue<FinanceState> financeState,
}) {
  const lowBudgetThreshold = 5000.0;
  final notifications = <AppNotification>[];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tasks = todosState.value ?? const <AdminTask>[];

  for (final task in tasks.where((task) => task.completionStatus == 0)) {
    final dueDate = DateTime.tryParse(task.dueDate ?? '');
    if (dueDate == null) continue;

    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final daysUntilDue = dueDay.difference(today).inDays;
    final taskId = task.taskId?.toString() ?? task.actionId;

    if (daysUntilDue < 0) {
      notifications.add(AppNotification(
        id: 'task-overdue-$taskId',
        icon: Icons.priority_high_rounded,
        title: 'Deadline overdue',
        message: task.title,
        detail: _formatDueDetail(dueDate),
        color: Colors.redAccent,
        destination: NotificationDestination.todos,
      ));
    } else if (daysUntilDue <= 5) {
      notifications.add(AppNotification(
        id: 'task-due-$taskId',
        icon: Icons.event_available_rounded,
        title: daysUntilDue == 0 ? 'Due today' : 'Due in $daysUntilDue day${daysUntilDue == 1 ? '' : 's'}',
        message: task.title,
        detail: _formatDueDetail(dueDate),
        color: const Color(0xFF6B4FA0),
        destination: NotificationDestination.todos,
      ));
    }
  }

  final finance = financeState.value;
  if (finance != null && finance.totalBalance < lowBudgetThreshold) {
    notifications.add(AppNotification(
      id: 'finance-low-budget',
      icon: Icons.account_balance_wallet_outlined,
      title: finance.totalBalance <= 0 ? 'Budget depleted' : 'Low budget',
      message: 'Current balance is PHP ${finance.totalBalance.toStringAsFixed(2)}',
      detail: 'Keep at least PHP ${lowBudgetThreshold.toStringAsFixed(0)} available',
      color: Colors.deepOrange,
      destination: NotificationDestination.money,
    ));
  }

  return notifications.take(12).toList();
}

String _formatDueDetail(DateTime dueDate) {
  final hour = dueDate.hour.toString().padLeft(2, '0');
  final minute = dueDate.minute.toString().padLeft(2, '0');
  return '${dueDate.month}/${dueDate.day}/${dueDate.year} at $hour:$minute';
}

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  static const Color _primaryColor = Color(0xFF6B4FA0);
  static const Color _softPurple = Color(0xFFF3E5F5);

  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final todosState = ref.watch(todosNotifierProvider);
    final financeState = ref.watch(financeNotifierProvider);
    final readIds = ref.watch(notificationReadIdsProvider);
    final deletedIds = ref.watch(notificationDeletedIdsProvider);
    final allNotifications = buildAppNotifications(
      todosState: todosState,
      financeState: financeState,
    ).where((item) => !deletedIds.contains(item.id)).toList();
    final visibleNotifications = _selectedTab == 0
        ? allNotifications
        : allNotifications.where((item) => !readIds.contains(item.id)).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: allNotifications.isEmpty || allNotifications.every((item) => readIds.contains(item.id))
                ? null
                : () {
                    ref.read(notificationReadIdsProvider.notifier).state = {
                      ...readIds,
                      ...allNotifications.map((item) => item.id),
                    };
                  },
            icon: const Icon(Icons.done_all_rounded, size: 18),
            label: const Text('Mark all read'),
            style: TextButton.styleFrom(
              foregroundColor: _primaryColor,
              disabledForegroundColor: Colors.grey.withValues(alpha: 0.5),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _softPurple.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _buildTabButton('All', 0, allNotifications.length),
                  _buildTabButton(
                    'Unread',
                    1,
                    allNotifications.where((item) => !readIds.contains(item.id)).length,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: visibleNotifications.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                    itemCount: visibleNotifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final notification = visibleNotifications[index];
                      final isRead = readIds.contains(notification.id);
                      return _buildNotificationTile(notification, isRead);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index, int count) {
    final isSelected = _selectedTab == index;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? _primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$label ($count)',
            style: TextStyle(
              color: isSelected ? Colors.white : _primaryColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationTile(AppNotification notification, bool isRead) {
    return GestureDetector(
      onTap: () => _openNotification(notification),
      onLongPressStart: (details) => _showNotificationMenu(notification, isRead, details.globalPosition),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : _softPurple.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isRead ? Colors.grey.withValues(alpha: 0.12) : _primaryColor.withValues(alpha: 0.18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: notification.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(notification.icon, color: notification.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.detail,
                    style: TextStyle(fontSize: 11, color: notification.color, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none_rounded, color: _primaryColor, size: 44),
            SizedBox(height: 12),
            Text('No notifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text(
              'You are all caught up.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _openNotification(AppNotification notification) {
    _markAsRead(notification.id);
    ref.read(navIndexProvider.notifier).state = notification.destination == NotificationDestination.todos ? 1 : 2;
    Navigator.pop(context);
  }

  Future<void> _showNotificationMenu(AppNotification notification, bool isRead, Offset position) async {
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      items: [
        PopupMenuItem(
          value: isRead ? 'unread' : 'read',
          child: Row(
            children: [
              Icon(isRead ? Icons.mark_email_unread_outlined : Icons.mark_email_read_outlined, size: 18, color: _primaryColor),
              const SizedBox(width: 10),
              Text(isRead ? 'Mark as unread' : 'Mark as read'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
              SizedBox(width: 10),
              Text('Delete notification', style: TextStyle(color: Colors.redAccent)),
            ],
          ),
        ),
      ],
    );

    if (action == 'read') {
      _markAsRead(notification.id);
    } else if (action == 'unread') {
      final updated = {...ref.read(notificationReadIdsProvider)};
      updated.remove(notification.id);
      ref.read(notificationReadIdsProvider.notifier).state = updated;
    } else if (action == 'delete') {
      final current = ref.read(notificationDeletedIdsProvider);
      ref.read(notificationDeletedIdsProvider.notifier).state = {...current, notification.id};
    }
  }

  void _markAsRead(String id) {
    final current = ref.read(notificationReadIdsProvider);
    ref.read(notificationReadIdsProvider.notifier).state = {...current, id};
  }
}
