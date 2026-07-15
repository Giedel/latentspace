import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/user_tasks/providers/task_provider.dart';
import '../features/user_tasks/models/admin_task.dart';

class TodosPage extends ConsumerWidget {
  const TodosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todosState = ref.watch(todosNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("To-do's & Tasks", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: todosState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (tasks) {
          if (tasks.isEmpty) {
            return _buildEmptyState();
          }

          return ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16).copyWith(bottom: 100),
            itemCount: tasks.length,
            // Changed from onReorder to onReorderItem
            onReorderItem: (oldIndex, newIndex) {
              ref.read(todosNotifierProvider.notifier).reorderTasks(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final task = tasks[index];
              return _buildInteractiveTaskTile(context, ref, task, Key(task.actionId));
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text("All caught up!", style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text("Tap + to add a new task.", style: TextStyle(color: Colors.grey)),
        ],
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
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) {
        ref.read(todosNotifierProvider.notifier).deleteTask(task);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task deleted')));
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 1,
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
              fontSize: 16,
              fontWeight: isCompleted ? FontWeight.normal : FontWeight.w600,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              color: isCompleted ? Colors.grey : Colors.black87,
            ),
          ),
          subtitle: task.dueDate != null
              ? Text('Due: ${_formatDate(task.dueDate!)}', style: const TextStyle(fontSize: 12))
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

  void _showEditDialog(BuildContext context, WidgetRef ref, AdminTask task) {
    final controller = TextEditingController(text: task.title);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
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