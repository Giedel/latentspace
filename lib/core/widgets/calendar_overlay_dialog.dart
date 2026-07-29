import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/date_provider.dart';

void showCalendarOverlay(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (context) => const CalendarOverlayDialog(),
  );
}

class CalendarOverlayDialog extends ConsumerStatefulWidget {
  const CalendarOverlayDialog({super.key});

  @override
  ConsumerState<CalendarOverlayDialog> createState() => _CalendarOverlayDialogState();
}

class _CalendarOverlayDialogState extends ConsumerState<CalendarOverlayDialog> {
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    final selected = ref.read(selectedDateProvider);
    _focusedMonth = selected ?? DateTime.now();
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  void _selectDate(DateTime date) {
    ref.read(selectedDateProvider.notifier).state = DateTime(date.year, date.month, date.day);
    Navigator.of(context).pop();
  }

  void _selectToday() {
    final now = DateTime.now();
    _selectDate(now);
  }

  void _showAllDates() {
    ref.read(selectedDateProvider.notifier).state = null;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final today = DateTime.now();

    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday; // 1 = Mon, 7 = Sun
    final leadingPadding = firstWeekday - 1;

    final weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dialog Title Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, color: Color(0xFF6B4FA0), size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Select Filter Date',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22, color: Colors.grey),
                  onPressed: () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Month Navigation & Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D2D2D)),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 22),
                      onPressed: _previousMonth,
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 22),
                      onPressed: _nextMonth,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Weekday Headers
            Row(
              children: weekDays
                  .map((day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),

            // Days Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: leadingPadding + daysInMonth,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 1.1,
              ),
              itemBuilder: (context, index) {
                if (index < leadingPadding) {
                  return const SizedBox.shrink();
                }

                final dayNum = index - leadingPadding + 1;
                final dateOfCell = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);

                final isToday = isSameDay(dateOfCell, today);
                final isSelected = isSameDay(dateOfCell, selectedDate);

                Color bgColor = Colors.transparent;
                Color textColor = Colors.black87;
                Border? border;

                if (isSelected) {
                  bgColor = const Color(0xFF6B4FA0);
                  textColor = Colors.white;
                } else if (isToday) {
                  bgColor = const Color(0xFFF3E5F5);
                  textColor = const Color(0xFF6B4FA0);
                  border = Border.all(color: const Color(0xFF6B4FA0), width: 1.5);
                }

                return InkWell(
                  onTap: () => _selectDate(dateOfCell),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(10),
                      border: border,
                    ),
                    child: Text(
                      '$dayNum',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: (isSelected || isToday) ? FontWeight.bold : FontWeight.normal,
                        color: textColor,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Dialog Footer Quick Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: _selectToday,
                  icon: const Icon(Icons.today_rounded, size: 16, color: Color(0xFF6B4FA0)),
                  label: const Text('Today', style: TextStyle(color: Color(0xFF6B4FA0), fontWeight: FontWeight.bold)),
                ),
                TextButton.icon(
                  onPressed: _showAllDates,
                  icon: const Icon(Icons.clear_all_rounded, size: 16, color: Colors.grey),
                  label: const Text('Show All', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable IconButton widget to display in AppBars/Headers that opens the Calendar Overlay
class CalendarIconButton extends ConsumerWidget {
  const CalendarIconButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final isToday = isSameDay(selectedDate, DateTime.now());

    String badgeLabel;
    if (selectedDate == null) {
      badgeLabel = 'All';
    } else if (isToday) {
      badgeLabel = 'Today';
    } else {
      badgeLabel = '${selectedDate.month}/${selectedDate.day}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () => showCalendarOverlay(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF6B4FA0).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF6B4FA0).withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_month_rounded, color: Color(0xFF6B4FA0), size: 20),
              const SizedBox(width: 6),
              Text(
                badgeLabel,
                style: const TextStyle(
                  color: Color(0xFF6B4FA0),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
