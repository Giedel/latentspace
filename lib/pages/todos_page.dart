import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/widgets/app_search_bar.dart';
import '../core/widgets/category_chip.dart';
import '../core/widgets/custom_card.dart';
import '../core/widgets/empty_state_widget.dart';
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
  String _searchQuery = '';
  bool _isCalendarExpanded = false;
  _CalendarViewMode _calendarViewMode = _CalendarViewMode.month;
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todosState = ref.watch(todosNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text("To-do's & Tasks", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: _topControlsMaxHeight(constraints.maxHeight)),
                child: Container(
                  color: Colors.white,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                      children: [
                        _buildTaskCalendar(todosState.value ?? const <AdminTask>[]),
                        const SizedBox(height: 12),
                        AppSearchBar(
                          controller: _searchController,
                          hintText: 'Search tasks...',
                          onChanged: (q) {
                            setState(() {
                              _searchQuery = q.trim().toLowerCase();
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
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
                              const SizedBox(width: 8),
                              _buildNewTaskButton(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: todosState.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                  data: (tasks) {
                    var filtered = tasks;

                    if (_filterStatus == 'Pending') {
                      filtered = filtered.where((t) => t.completionStatus == 0).toList();
                    } else if (_filterStatus == 'Completed') {
                      filtered = filtered.where((t) => t.completionStatus == 1).toList();
                    }

                    if (_searchQuery.isNotEmpty) {
                      filtered = filtered.where((t) => t.title.toLowerCase().contains(_searchQuery)).toList();
                    }

                    if (filtered.isEmpty) {
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            padding: const EdgeInsets.only(bottom: 100),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minHeight: constraints.maxHeight),
                              child: EmptyStateWidget(
                                icon: Icons.check_circle_outline_rounded,
                                title: _filterStatus == 'Completed' ? 'No completed tasks' : 'All caught up!',
                                message: 'Use "New Task" above to add a task manually or use the AI prompt.',
                              ),
                            ),
                          );
                        },
                      );
                    }

                    return ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16).copyWith(bottom: 100),
                      itemCount: filtered.length,
                      onReorderItem: (oldIndex, newIndex) {
                        ref.read(todosNotifierProvider.notifier).reorderTasks(oldIndex, newIndex);
                      },
                      itemBuilder: (context, index) {
                        final task = filtered[index];
                        return _buildInteractiveTaskTile(context, ref, task, Key(task.actionId));
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  double _topControlsMaxHeight(double availableHeight) {
    if (!_isCalendarExpanded) return availableHeight;

    final maxForControls = availableHeight - 96;
    if (maxForControls < 240) return 240;
    return maxForControls;
  }

  Widget _buildNewTaskButton() {
    return SizedBox(
      height: 34,
      child: FilledButton.icon(
        onPressed: () => _showAddTaskDialog(context),
        icon: const Icon(Icons.add_rounded, size: 16),
        label: const Text('New Task', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        style: FilledButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }

  Widget _buildInteractiveTaskTile(BuildContext context, WidgetRef ref, AdminTask task, Key key) {
    final isCompleted = task.completionStatus == 1;

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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task deleted')));
      },
      child: CustomCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.zero,
        backgroundColor: isCompleted ? Colors.grey.shade100 : Colors.white,
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

  Widget _buildTaskCalendar(List<AdminTask> tasks) {
    final tasksByDay = _groupTasksByDay(tasks);
    final monthLabel = _formatMonthLabel(_visibleMonth);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primaryColor.withValues(alpha: 0.12)),
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
                      color: _softPurple,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_month_rounded, color: _primaryColor, size: 20),
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
    final screenHeight = MediaQuery.sizeOf(context).height;
    final calendarHeight = screenHeight < 520 ? 260.0 : 340.0;

    return Container(
      height: calendarHeight,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      decoration: BoxDecoration(
        color: _softPurple.withValues(alpha: 0.35),
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
                    style: const TextStyle(fontWeight: FontWeight.bold, color: _primaryColor),
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

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _calendarViewMode = mode),
        child: Container(
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? _primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _primaryColor.withValues(alpha: isSelected ? 0 : 0.18)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : _primaryColor,
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
                  return _buildDayCell(
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
        Expanded(child: _buildDaySchedule(tasksByDay)),
      ],
    );
  }

  Widget _buildDaySchedule(Map<DateTime, List<AdminTask>> tasksByDay) {
    final selectedTasks = List<AdminTask>.from(tasksByDay[_dateOnly(_selectedDate)] ?? const <AdminTask>[])
      ..sort((a, b) => (DateTime.tryParse(a.dueDate ?? '') ?? _selectedDate)
          .compareTo(DateTime.tryParse(b.dueDate ?? '') ?? _selectedDate));

    return ListView.builder(
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
                  '${hour.toString().padLeft(2, '0')}:00',
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
    );
  }

  Widget _buildCalendarTaskPill(AdminTask task) {
    final isCompleted = task.completionStatus == 1;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.grey.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: (isCompleted ? Colors.grey : _primaryColor).withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 15,
            color: isCompleted ? Colors.grey : _primaryColor,
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
          color: isSelected ? _primaryColor : isToday ? _softPurple : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _primaryColor : _primaryColor.withValues(alpha: isToday ? 0.2 : 0.08),
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
                    color: isSelected ? Colors.white70 : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: isCompact ? 13 : 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black87,
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
                        color: isSelected ? Colors.white : _primaryColor,
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

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Task added successfully!'), backgroundColor: Colors.green),
                  );
                }
              },
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6B4FA0)),
              child: const Text('Create'),
            )
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
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Task'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Task title'),
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
