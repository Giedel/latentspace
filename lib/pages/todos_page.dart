import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/widgets/category_chip.dart';
import '../core/widgets/custom_card.dart';
import '../core/widgets/empty_state_widget.dart';
import '../core/widgets/app_feedback.dart';
import '../features/user_tasks/providers/task_provider.dart';
import '../features/user_tasks/models/admin_task.dart';

enum _CalendarViewMode { day, week, month }

class TodosPage extends ConsumerStatefulWidget {
  const TodosPage({super.key});

  @override
  ConsumerState<TodosPage> createState() => _TodosPageState();
}

class _TodosPageState extends ConsumerState<TodosPage> {
  static const Color _primaryColor = Color(0xFF6B4FA0);
  static const Color _softPurple = Color(0xFFF3E5F5);

  String _filterStatus = 'All'; // 'All', 'Pending', 'Completed'
  bool _isCalendarExpanded = false;
  _CalendarViewMode _calendarViewMode = _CalendarViewMode.month;
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final todosState = ref.watch(todosNotifierProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text("To-do's & Tasks", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.surfaceContainer,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: 'Sync calendar',
            icon: Icon(Icons.sync_rounded, color: colorScheme.primary),
            onPressed: () => _showCalendarSyncDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: todosState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (tasks) {
          var filtered = tasks;
          if (_filterStatus == 'Pending') {
            filtered = filtered.where((task) => task.completionStatus == 0).toList();
          } else if (_filterStatus == 'Completed') {
            filtered = filtered.where((task) => task.completionStatus == 1).toList();
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            children: [
              _buildTaskCalendar(tasks),
              const SizedBox(height: 12),
              _buildFilterButtons(),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: EmptyStateWidget(
                    icon: Icons.check_circle_outline_rounded,
                    title: _filterStatus == 'Completed' ? 'No completed tasks' : 'All caught up!',
                    message: 'No tasks match the selected filter.',
                  ),
                )
              else
                ..._buildDateGroupedTaskItems(filtered),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          CategoryChip(
            label: 'All',
            isSelected: _filterStatus == 'All',
            onTap: () => setState(() => _filterStatus = 'All'),
            icon: Icons.list_alt_rounded,
          ),
          CategoryChip(
            label: 'Pending',
            isSelected: _filterStatus == 'Pending',
            onTap: () => setState(() => _filterStatus = 'Pending'),
            icon: Icons.pending_actions_rounded,
          ),
          CategoryChip(
            label: 'Completed',
            isSelected: _filterStatus == 'Completed',
            onTap: () => setState(() => _filterStatus = 'Completed'),
            icon: Icons.check_circle_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveTaskTile(BuildContext context, WidgetRef ref, AdminTask task, Key key) {
    final isCompleted = task.completionStatus == 1;
    final colorScheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: key,
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
      ),
      onDismissed: (_) {
        ref.read(todosNotifierProvider.notifier).deleteTask(task);
        AppFeedback.show(context, message: 'Task deleted', icon: Icons.delete_outline_rounded);
      },
      child: CustomCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.zero,
        backgroundColor: isCompleted ? colorScheme.surfaceContainerHighest : colorScheme.surfaceContainer,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Checkbox(
            value: isCompleted,
            activeColor: Theme.of(context).colorScheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onChanged: (_) => ref.read(todosNotifierProvider.notifier).toggleCompletion(task),
          ),
          title: Text(
            task.title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isCompleted ? FontWeight.normal : FontWeight.bold,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              color: isCompleted ? Colors.grey : Colors.black87,
            ),
          ),
          subtitle: task.dueDate != null
              ? Text('Due: ${_formatDate(task.dueDate!)}', style: const TextStyle(fontSize: 12, color: Colors.grey))
              : null,
          trailing: IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
            onPressed: () => _showEditDialog(context, ref, task),
          ),
        ),
      ),
    );
  }

  /// A single continuous feed, grouped chronologically by due date. Calendar
  /// date selection remains available for navigation but does not hide tasks.
  List<Widget> _buildDateGroupedTaskItems(List<AdminTask> tasks) {
    final sortedTasks = List<AdminTask>.from(tasks)
      ..sort((a, b) {
        final first = DateTime.tryParse(a.dueDate ?? '');
        final second = DateTime.tryParse(b.dueDate ?? '');
        if (first == null && second == null) return a.title.compareTo(b.title);
        if (first == null) return 1;
        if (second == null) return -1;
        return first.compareTo(second);
      });

    final children = <Widget>[];
    DateTime? previousDate;
    var hasNoDueDateHeader = false;

    for (final task in sortedTasks) {
      final dueDate = DateTime.tryParse(task.dueDate ?? '');
      if (dueDate == null) {
        if (!hasNoDueDateHeader) {
          children.add(_buildTaskDateHeader(null));
          hasNoDueDateHeader = true;
        }
      } else {
        final date = _dateOnly(dueDate);
        if (previousDate == null || !_isSameDay(previousDate, date)) {
          children.add(_buildTaskDateHeader(date));
          previousDate = date;
        }
      }
      children.add(_buildInteractiveTaskTile(context, ref, task, ValueKey('task-${task.actionId}')));
    }

    return children;
  }

  Widget _buildTaskDateHeader(DateTime? date) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = date == null ? 'No due date' : '${_weekdayName(date)}, ${_formatLongDate(date)}';
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 9),
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.primary)),
        ],
      ),
    );
  }

  Widget _buildTaskCalendar(List<AdminTask> tasks) {
    final colorScheme = Theme.of(context).colorScheme;
    final tasksByDay = _groupTasksByDay(tasks);
    final monthLabel = _formatMonthLabel(_visibleMonth);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(20),
              bottom: Radius.circular(_isCalendarExpanded ? 0 : 20),
            ),
            onTap: () => setState(() => _isCalendarExpanded = !_isCalendarExpanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.calendar_month_rounded, color: colorScheme.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(monthLabel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        Text(
                          _selectedDateSummary(tasksByDay),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(_isCalendarExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded),
                    onPressed: () => setState(() => _isCalendarExpanded = !_isCalendarExpanded),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState: _isCalendarExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: _buildCompactCalendar(tasksByDay),
            secondChild: _buildExpandedCalendar(tasksByDay),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactCalendar(Map<DateTime, List<AdminTask>> tasksByDay) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: _daysForWeek(_selectedDate).map((day) {
          return Expanded(child: _buildDayCell(day, tasksByDay, isCompact: true));
        }).toList(),
      ),
    );
  }

  Widget _buildExpandedCalendar(Map<DateTime, List<AdminTask>> tasksByDay) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final calendarHeight = screenHeight < 520 ? 260.0 : 340.0;

    return Container(
      height: calendarHeight,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1)),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    _formatMonthLabel(_visibleMonth),
                    style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1)),
              ),
            ],
          ),
          Row(
            children: [
              _buildCalendarModeButton('Day', _CalendarViewMode.day),
              const SizedBox(width: 8),
              _buildCalendarModeButton('Week', _CalendarViewMode.week),
              const SizedBox(width: 8),
              _buildCalendarModeButton('Month', _CalendarViewMode.month),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _calendarViewMode == _CalendarViewMode.day
                ? _buildDaySchedule(tasksByDay)
                : _calendarViewMode == _CalendarViewMode.week
                    ? _buildWeekCalendar(tasksByDay)
                    : _buildMonthCalendar(tasksByDay),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarModeButton(String label, _CalendarViewMode mode) {
    final isSelected = _calendarViewMode == mode;
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _calendarViewMode = mode),
        child: Container(
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.primary.withValues(alpha: isSelected ? 1 : 0.18), width: isSelected ? 2 : 1),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthCalendar(Map<DateTime, List<AdminTask>> tasksByDay) {
    final days = _daysForMonthGrid(_visibleMonth);

    return Column(
      children: [
        _buildWeekdayHeader(),
        const SizedBox(height: 6),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cellWidth = (constraints.maxWidth - 24) / 7;
              final cellHeight = (constraints.maxHeight - 20) / 6;

              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: days.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  childAspectRatio: cellWidth / cellHeight,
                ),
                itemBuilder: (context, index) {
                  return _buildMonthDayCell(
                    days[index],
                    tasksByDay,
                    isCurrentMonth: days[index].month == _visibleMonth.month,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeekCalendar(Map<DateTime, List<AdminTask>> tasksByDay) {
    final days = _daysForWeek(_selectedDate);

    return Column(
      children: [
        _buildWeekdayHeader(),
        const SizedBox(height: 6),
        SizedBox(
          height: 58,
          child: Row(
            children: days.map((day) => Expanded(child: _buildWeekDayCell(day, tasksByDay))).toList(),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(child: _buildWeekSchedule(days, tasksByDay)),
      ],
    );
  }

  Widget _buildWeekSchedule(List<DateTime> days, Map<DateTime, List<AdminTask>> tasksByDay) {
    return ListView.builder(
      itemCount: 24,
      itemBuilder: (context, hour) {
        return Container(
          constraints: const BoxConstraints(minHeight: 46),
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.12))),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 54,
                child: Text(
                  _formatHourLabel(hour),
                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: days.map((day) {
                    final hourTasks = (tasksByDay[_dateOnly(day)] ?? const <AdminTask>[]).where((task) {
                      final dueDate = DateTime.tryParse(task.dueDate ?? '');
                      return dueDate != null && dueDate.hour == hour;
                    }).toList();

                    return Expanded(
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 38),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: hourTasks.map((task) => _buildWeekTaskBlock(task)).toList(),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDaySchedule(Map<DateTime, List<AdminTask>> tasksByDay) {
    final selectedTasks = List<AdminTask>.from(tasksByDay[_dateOnly(_selectedDate)] ?? const <AdminTask>[])
      ..sort((a, b) => (DateTime.tryParse(a.dueDate ?? '') ?? _selectedDate)
          .compareTo(DateTime.tryParse(b.dueDate ?? '') ?? _selectedDate));

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 54,
              child: Column(
                children: [
                  Text(
                    _weekdayName(_selectedDate),
                    style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_selectedDate.day}',
                    style: TextStyle(fontSize: 22, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: selectedTasks.isEmpty
                  ? const SizedBox(height: 8)
                  : Column(
                      children: selectedTasks.take(3).map((task) => _buildCalendarTaskPill(task)).toList(),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: 24,
            itemBuilder: (context, hour) {
              final hourTasks = selectedTasks.where((task) {
                final dueDate = DateTime.tryParse(task.dueDate ?? '');
                return dueDate != null && dueDate.hour == hour;
              }).toList();

              return Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.12))),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 54,
                      child: Text(
                        _formatHourLabel(hour),
                        style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      child: hourTasks.isEmpty
                          ? const SizedBox(height: 24)
                          : Column(
                              children: hourTasks.map((task) => _buildCalendarTaskPill(task)).toList(),
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarTaskPill(AdminTask task) {
    final isCompleted = task.completionStatus == 1;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: (isCompleted ? Colors.grey : colorScheme.primary).withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 15,
            color: isCompleted ? Colors.grey : colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isCompleted ? Colors.grey : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekTaskBlock(AdminTask task) {
    final isCompleted = task.completionStatus == 1;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 3),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.grey.shade200 : colorScheme.primary.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        task.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: isCompleted ? Colors.grey.shade600 : Colors.white,
        ),
      ),
    );
  }

  Widget _buildMonthDayCell(
    DateTime day,
    Map<DateTime, List<AdminTask>> tasksByDay, {
    bool isCurrentMonth = true,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final date = _dateOnly(day);
    final isSelected = _isSameDay(date, _selectedDate);
    final isToday = _isSameDay(date, DateTime.now());
    final tasks = tasksByDay[date] ?? const <AdminTask>[];

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        setState(() {
          _selectedDate = date;
          _visibleMonth = DateTime(date.year, date.month);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.primary.withValues(alpha: isToday ? 0.45 : 0.08),
          ),
        ),
        child: Opacity(
          opacity: isCurrentMonth ? 1 : 0.35,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: 5,
                child: tasks.isEmpty
                    ? const SizedBox.shrink()
                    : Center(
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Row(
      children: days.map((day) {
        return Expanded(
          child: Center(
            child: Text(day, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWeekDayCell(DateTime day, Map<DateTime, List<AdminTask>> tasksByDay) {
    return _buildDayCell(
      day,
      tasksByDay,
    );
  }

  Widget _buildDayCell(
    DateTime day,
    Map<DateTime, List<AdminTask>> tasksByDay, {
    bool isCompact = false,
    bool isCurrentMonth = true,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final date = _dateOnly(day);
    final isSelected = _isSameDay(date, _selectedDate);
    final isToday = _isSameDay(date, DateTime.now());
    final taskCount = tasksByDay[date]?.length ?? 0;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        setState(() {
          _selectedDate = date;
          _visibleMonth = DateTime(date.year, date.month);
        });
      },
      child: Container(
        height: isCompact ? 54 : null,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.primary.withValues(alpha: isToday ? 0.45 : 0.08),
          ),
        ),
        child: Opacity(
          opacity: isCurrentMonth ? 1 : 0.35,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isCompact)
                Text(
                  _weekdayName(day),
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected ? colorScheme.primary : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: isCompact ? 13 : 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                height: 5,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(taskCount.clamp(0, 3).toInt(), (index) {
                    return Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<DateTime, List<AdminTask>> _groupTasksByDay(List<AdminTask> tasks) {
    final grouped = <DateTime, List<AdminTask>>{};

    for (final task in tasks) {
      final dueDate = DateTime.tryParse(task.dueDate ?? '');
      if (dueDate == null) continue;

      final key = _dateOnly(dueDate);
      grouped.putIfAbsent(key, () => []).add(task);
    }

    return grouped;
  }

  bool _isTaskDueOnSelectedDate(AdminTask task) {
    final dueDate = DateTime.tryParse(task.dueDate ?? '');
    if (dueDate == null) return false;
    return _isSameDay(_dateOnly(dueDate), _dateOnly(_selectedDate));
  }

  List<DateTime> _daysForMonthGrid(DateTime month) {
    final firstDay = DateTime(month.year, month.month);
    final daysBefore = firstDay.weekday - 1;
    final gridStart = firstDay.subtract(Duration(days: daysBefore));

    return List.generate(42, (index) => gridStart.add(Duration(days: index)));
  }

  List<DateTime> _daysForWeek(DateTime anchor) {
    final start = _dateOnly(anchor).subtract(Duration(days: anchor.weekday - 1));
    return List.generate(7, (index) => start.add(Duration(days: index)));
  }

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatMonthLabel(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatLongDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _weekdayName(DateTime date) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[date.weekday - 1];
  }

  String _selectedDateSummary(Map<DateTime, List<AdminTask>> tasksByDay) {
    final count = tasksByDay[_dateOnly(_selectedDate)]?.length ?? 0;
    final taskText = count == 1 ? '1 task due' : '$count tasks due';
    return '${_weekdayName(_selectedDate)}, ${_selectedDate.month}/${_selectedDate.day} - $taskText';
  }

  String _formatDate(String isoString) {
    final d = DateTime.tryParse(isoString);
    if (d == null) return '';
    return '${d.month}/${d.day} at ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _formatHourLabel(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add New Task', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: titleController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Task title...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            FilledButton(
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isNotEmpty) {
                  ref.read(todosNotifierProvider.notifier).addTask(title);
                  Navigator.pop(context);
                  AppFeedback.show(context, message: 'Task added successfully!');
                }
              },
              style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
              child: const Text('Create'),
            )
          ],
        );
      },
    );
  }

  void _showCalendarSyncDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          backgroundColor: Theme.of(context).colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.sync_rounded, color: Theme.of(context).colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Sync Calendar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: const Text(
            'Sign in to Google to import events and start times from your primary calendar for the next 90 days.',
            style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            FilledButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                AppFeedback.show(this.context, message: 'Connecting to Google Calendar...', icon: Icons.sync_rounded);
                try {
                  final result = await ref.read(todosNotifierProvider.notifier).syncGoogleCalendar();
                  if (!mounted) return;
                  AppFeedback.show(
                    this.context,
                    message: result == null
                        ? 'Google Calendar sign-in was cancelled.'
                        : 'Calendar synced. ${result.received} found, ${result.imported} new imported.'
                            '${result.warnings.isEmpty ? '' : ' ${result.warnings.first}'}',
                    icon: Icons.sync_rounded,
                  );
                } catch (error) {
                  if (!mounted) return;
                  AppFeedback.show(this.context, message: 'Google Calendar sync failed: $error', icon: Icons.error_outline_rounded);
                }
              },
              icon: const Icon(Icons.sync_rounded, size: 18),
              label: const Text('Sync'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, AdminTask task) {
    final controller = TextEditingController(text: task.title);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Task'),
          content: SizedBox(
            width: 440,
            child: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Task title'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            FilledButton(
              onPressed: () {
                final newTitle = controller.text.trim();
                if (newTitle.isNotEmpty && newTitle != task.title) {
                  ref.read(todosNotifierProvider.notifier).editTaskTitle(task, newTitle);
                }
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
