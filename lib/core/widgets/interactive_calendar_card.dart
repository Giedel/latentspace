import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/date_provider.dart';

class InteractiveCalendarCard extends ConsumerStatefulWidget {
  const InteractiveCalendarCard({super.key});

  @override
  ConsumerState<InteractiveCalendarCard> createState() => _InteractiveCalendarCardState();
}

class _InteractiveCalendarCardState extends ConsumerState<InteractiveCalendarCard> {
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

  void _selectToday() {
    final now = DateTime.now();
    setState(() {
      _focusedMonth = now;
    });
    ref.read(selectedDateProvider.notifier).state = DateTime(now.year, now.month, now.day);
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Header & Navigation Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, color: Color(0xFF6B4FA0), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    '${monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  InkWell(
                    onTap: _selectToday,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B4FA0).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Today',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B4FA0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 22),
                    onPressed: _previousMonth,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Previous Month',
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 22),
                    onPressed: _nextMonth,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Next Month',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Days of Week Labels
          Row(
            children: weekDays
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),

          // Calendar Days Grid
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
                onTap: () {
                  // Toggle selection or select date
                  final newDate = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
                  if (isSelected) {
                    ref.read(selectedDateProvider.notifier).state = null; // Clear filter on re-tap
                  } else {
                    ref.read(selectedDateProvider.notifier).state = newDate;
                  }
                },
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
          const SizedBox(height: 12),

          // Date Filter Status Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selectedDate != null
                  ? const Color(0xFF6B4FA0).withValues(alpha: 0.08)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        selectedDate != null ? Icons.filter_alt_rounded : Icons.touch_app_outlined,
                        size: 16,
                        color: selectedDate != null ? const Color(0xFF6B4FA0) : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          selectedDate != null
                              ? 'Filter: ${monthNames[selectedDate.month - 1]} ${selectedDate.day}, ${selectedDate.year}'
                              : 'Select a date to filter Home, To-do\'s & Money',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: selectedDate != null ? FontWeight.bold : FontWeight.normal,
                            color: selectedDate != null ? const Color(0xFF6B4FA0) : Colors.grey.shade700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selectedDate != null)
                  InkWell(
                    onTap: () {
                      ref.read(selectedDateProvider.notifier).state = null;
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Text(
                        'Show All',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
