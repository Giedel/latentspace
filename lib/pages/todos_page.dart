import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/date_provider.dart';
import '../core/widgets/app_search_bar.dart';
import '../core/widgets/calendar_overlay_dialog.dart';
import '../core/widgets/category_chip.dart';
import '../core/widgets/custom_card.dart';
import '../core/widgets/empty_state_widget.dart';
import '../features/user_tasks/providers/task_provider.dart';
import '../features/user_tasks/models/admin_task.dart';

class TodosPage extends ConsumerStatefulWidget {
  const TodosPage({super.key});

  @override
  ConsumerState<TodosPage> createState() => _TodosPageState();
}

class _TodosPageState extends ConsumerState<TodosPage> {
  String _filterStatus = 'All'; // 'All', 'Pending', 'Completed'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todosState = ref.watch(todosNotifierProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text(
          "To-do's & Tasks",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          const CalendarIconButton(),
          IconButton(
            icon: const Icon(Icons.add_task_rounded, color: Color(0xFF6B4FA0)),
            onPressed: () => _showAddTaskDialog(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskDialog(context),
        backgroundColor: const Color(0xFF6B4FA0),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'New Task',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
                  hintText: 'Search tasks...',
                  onChanged: (q) {
                    setState(() {
                      _searchQuery = q.trim().toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SingleChildScrollView(
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
                          onTap: () =>
                              setState(() => _filterStatus = 'Pending'),
                          icon: Icons.pending_actions_rounded,
                        ),
                        CategoryChip(
                          label: 'Completed',
                          isSelected: _filterStatus == 'Completed',
                          onTap: () =>
                              setState(() => _filterStatus = 'Completed'),
                          icon: Icons.check_circle_rounded,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: todosState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (tasks) {
                var filtered = tasks;

                if (selectedDate != null) {
                  filtered = filtered
                      .where(
                        (t) => matchesSelectedDate(t.dueDate, selectedDate),
                      )
                      .toList();
                }

                if (_filterStatus == 'Pending') {
                  filtered = filtered
                      .where((t) => t.completionStatus == 0)
                      .toList();
                } else if (_filterStatus == 'Completed') {
                  filtered = filtered
                      .where((t) => t.completionStatus == 1)
                      .toList();
                }

                if (_searchQuery.isNotEmpty) {
                  filtered = filtered
                      .where(
                        (t) => t.title.toLowerCase().contains(_searchQuery),
                      )
                      .toList();
                }

                if (filtered.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.check_circle_outline_rounded,
                    title: _filterStatus == 'Completed'
                        ? 'No completed tasks'
                        : 'All caught up!',
                    message:
                        'Tap "New Task" to add a task manually or use the AI prompt.',
                    actionLabel: 'Add Task',
                    onAction: () => _showAddTaskDialog(context),
                  );
                }

                return ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ).copyWith(bottom: 100),
                  itemCount: filtered.length,
                  onReorderItem: (oldIndex, newIndex) {
                    ref
                        .read(todosNotifierProvider.notifier)
                        .reorderTasks(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final task = filtered[index];
                    return _buildInteractiveTaskTile(
                      context,
                      ref,
                      task,
                      Key(task.actionId),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveTaskTile(
    BuildContext context,
    WidgetRef ref,
    AdminTask task,
    Key key,
  ) {
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
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      onDismissed: (_) {
        ref.read(todosNotifierProvider.notifier).deleteTask(task);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Task deleted')));
      },
      child: CustomCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.zero,
        backgroundColor: isCompleted ? Colors.grey.shade100 : Colors.white,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Checkbox(
            value: isCompleted,
            activeColor: Theme.of(context).colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            onChanged: (_) =>
                ref.read(todosNotifierProvider.notifier).toggleCompletion(task),
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
              ? Text(
                  'Due: ${_formatDate(task.dueDate!)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                )
              : null,
          trailing: IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
            onPressed: () => _showEditDialog(context, ref, task),
          ),
        ),
      ),
    );
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Add New Task',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
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
                    const SnackBar(
                      content: Text('Task added successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6B4FA0),
              ),
              child: const Text('Create'),
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
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Edit Task'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Task title',
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
                  ref
                      .read(todosNotifierProvider.notifier)
                      .editTaskTitle(task, newTitle);
                }
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
