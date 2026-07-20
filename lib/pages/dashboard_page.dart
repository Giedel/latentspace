import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/widgets/app_search_bar.dart';
import '../core/widgets/custom_card.dart';
import '../core/widgets/empty_state_widget.dart';
import '../features/ai_orchestrator/presentation/widgets/slm_model_card.dart';
import '../features/ai_orchestrator/providers/core_action_provider.dart';
import '../features/ai_orchestrator/models/core_ai_action.dart';
import '../features/user_tasks/providers/task_provider.dart';
import 'agentic_assistant_page.dart';
import 'main_layout.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning, Giedel! 👋';
    if (hour < 17) return 'Good afternoon, Giedel! ☀️';
    return 'Good evening, Giedel! 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final actionsState = ref.watch(coreActionNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              
              // Quantized SLM Model Status Card
              const SlmModelCard(),
              const SizedBox(height: 20),

              AppSearchBar(
                controller: _searchController,
                hintText: 'Search notes, tasks, or prompt history...',
                onChanged: (query) {
                  setState(() {
                    _searchQuery = query.trim().toLowerCase();
                  });
                },
              ),
              const SizedBox(height: 24),

              actionsState.maybeWhen(
                data: (actions) {
                  final pending = actions.where((a) => a.status == 'PENDING').toList();
                  if (pending.isEmpty) return const SizedBox.shrink();
                  return _buildPendingActions(context, ref, pending);
                },
                orElse: () => const SizedBox.shrink(),
              ),

              _buildSectionHeader('Upcoming Tasks', 'View all', () {
                ref.read(navIndexProvider.notifier).state = 1;
              }),
              const SizedBox(height: 14),
              _buildUpcomingTasks(ref),

              const SizedBox(height: 28),
              
              _buildSectionHeader('Recent Notes', 'View all', () {
                ref.read(navIndexProvider.notifier).state = 3;
              }),
              const SizedBox(height: 14),
              _buildRecentNotes(ref),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.hub_rounded, color: Theme.of(context).colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'On-device SLM Personal Administrator',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.smart_toy_outlined, size: 24, color: Color(0xFF6B4FA0)),
              tooltip: 'Agentic Assistant Console',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AgenticAssistantPage()),
                );
              },
            ),
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, size: 26),
                  onPressed: () {},
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              ],
            ),
          ],
        )
      ],
    );
  }

  Widget _buildSectionHeader(String title, String actionText, VoidCallback onAction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        InkWell(
          onTap: onAction,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Text(
              actionText,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B4FA0), fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingActions(BuildContext context, WidgetRef ref, List<CoreAiAction> pendingActions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Needs Your Review',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepOrange),
            ),
            TextButton(
              onPressed: () {
                for (var action in pendingActions) {
                  ref.read(coreActionNotifierProvider.notifier).updateAction(
                    action.copyWith(status: 'REJECTED'),
                  );
                }
              },
              child: const Text('Dismiss all', style: TextStyle(color: Colors.grey, fontSize: 12)),
            )
          ],
        ),
        const SizedBox(height: 8),
        ...pendingActions.map((action) => CustomCard(
          margin: const EdgeInsets.only(bottom: 10),
          backgroundColor: const Color(0xFFFFF4E5),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          onTap: () => _showEditableReviewDialog(context, ref, action),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.psychology_rounded, color: Colors.deepOrange, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review ${action.inferredDomain.toLowerCase()}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '"${action.rawUserInput}"',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        )),
        const SizedBox(height: 20),
      ],
    );
  }

  void _showEditableReviewDialog(BuildContext context, WidgetRef ref, CoreAiAction action) {
    final domain = action.inferredDomain;
    final Map<String, dynamic> mutablePayload = Map<String, dynamic>.from(action.jsonPayload);

    final titleController = TextEditingController(
      text: mutablePayload['title']?.toString() ?? mutablePayload['content']?.toString() ?? action.rawUserInput,
    );
    final amountController = TextEditingController(
      text: mutablePayload['amount_cents'] != null
          ? (mutablePayload['amount_cents'] / 100).toStringAsFixed(2)
          : '0.00',
    );
    String selectedCategory = mutablePayload['primary_category']?.toString() ?? 'General';
    String selectedType = mutablePayload['transaction_type']?.toString() ?? 'EXPENSE';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  Icon(
                    domain == 'FINANCE' ? Icons.account_balance_wallet_rounded
                        : domain == 'NOTE' ? Icons.note_alt_rounded
                        : Icons.check_circle_outline_rounded,
                    color: const Color(0xFF6B4FA0),
                  ),
                  const SizedBox(width: 10),
                  Text('Review $domain', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.format_quote_rounded, color: Colors.grey, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              action.rawUserInput,
                              style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black87, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Extracted Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 12),

                    if (domain == 'FINANCE') ...[
                      TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Amount (PHP)',
                          prefixIcon: Icon(Icons.attach_money_rounded),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: ['EXPENSE', 'INCOME'].contains(selectedType) ? selectedType : 'EXPENSE',
                        decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'EXPENSE', child: Text('Expense')),
                          DropdownMenuItem(value: 'INCOME', child: Text('Income')),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedType = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: ['Food & Beverage', 'Groceries', 'Transportation', 'Utilities', 'Shopping', 'Income', 'General'].contains(selectedCategory) ? selectedCategory : 'General',
                        decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'Food & Beverage', child: Text('Food & Beverage')),
                          DropdownMenuItem(value: 'Groceries', child: Text('Groceries')),
                          DropdownMenuItem(value: 'Transportation', child: Text('Transportation')),
                          DropdownMenuItem(value: 'Utilities', child: Text('Utilities')),
                          DropdownMenuItem(value: 'Shopping', child: Text('Shopping')),
                          DropdownMenuItem(value: 'Income', child: Text('Income')),
                          DropdownMenuItem(value: 'General', child: Text('General')),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedCategory = val);
                        },
                      ),
                    ] else if (domain == 'TO-DO' || domain == 'REMINDER') ...[
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Task Title',
                          prefixIcon: Icon(Icons.check_box_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ] else ...[
                      TextField(
                        controller: titleController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Note Content',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    final rejected = action.copyWith(status: 'REJECTED');
                    ref.read(coreActionNotifierProvider.notifier).updateAction(rejected);
                    Navigator.pop(context);
                  },
                  child: const Text('Discard', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ),
                FilledButton(
                  onPressed: () async {
                    if (domain == 'FINANCE') {
                      final amt = double.tryParse(amountController.text.trim()) ?? 10.0;
                      mutablePayload['amount_cents'] = (amt * 100).round();
                      mutablePayload['transaction_type'] = selectedType;
                      mutablePayload['primary_category'] = selectedCategory;
                    } else if (domain == 'TO-DO' || domain == 'REMINDER') {
                      mutablePayload['title'] = titleController.text.trim();
                    } else {
                      mutablePayload['content'] = titleController.text.trim();
                    }

                    await ref.read(coreActionNotifierProvider.notifier).approveAndRouteAction(
                      action,
                      customPayload: mutablePayload,
                    );

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$domain approved & saved!'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6B4FA0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Approve & Save', style: TextStyle(fontWeight: FontWeight.bold)),
                )
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildUpcomingTasks(WidgetRef ref) {
    final tasksState = ref.watch(upcomingTasksProvider);

    return CustomCard(
      padding: EdgeInsets.zero,
      child: tasksState.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (err, stack) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error loading tasks: $err'),
        ),
        data: (tasks) {
          final filtered = _searchQuery.isEmpty
              ? tasks
              : tasks.where((t) => t.title.toLowerCase().contains(_searchQuery)).toList();

          if (filtered.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.check_circle_outline_rounded,
              title: 'No upcoming tasks',
              message: 'You are all caught up!',
            );
          }

          return Column(
            children: filtered.asMap().entries.map((entry) {
              final index = entry.key;
              final task = entry.value;
              final isLast = index == filtered.length - 1;

              String timeDisplay = 'No due date';
              if (task.dueDate != null) {
                final d = DateTime.tryParse(task.dueDate!);
                if (d != null) {
                  timeDisplay = '${d.month}/${d.day} at ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
                }
              }

              return Column(
                children: [
                  ListTile(
                    onTap: () {
                      ref.read(todosNotifierProvider.notifier).toggleCompletion(task);
                    },
                    leading: Checkbox(
                      value: task.completionStatus == 1,
                      activeColor: const Color(0xFF6B4FA0),
                      onChanged: (_) {
                        ref.read(todosNotifierProvider.notifier).toggleCompletion(task);
                      },
                    ),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        decoration: task.completionStatus == 1 ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Text(timeDisplay, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Pending',
                        style: TextStyle(color: Color(0xFF6B4FA0), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  if (!isLast) Divider(height: 1, color: Colors.grey.withValues(alpha: 0.1), indent: 56),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildRecentNotes(WidgetRef ref) {
    final actionsState = ref.watch(coreActionNotifierProvider);

    return actionsState.maybeWhen(
      data: (actions) {
        var notes = actions.where((a) => a.inferredDomain == 'NOTE' && a.status == 'COMPLETED').toList();

        if (_searchQuery.isNotEmpty) {
          notes = notes.where((n) {
            final content = n.jsonPayload['content']?.toString().toLowerCase() ?? '';
            return content.contains(_searchQuery);
          }).toList();
        }

        if (notes.isEmpty) {
          return const CustomCard(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('No notes found.', style: TextStyle(color: Colors.grey)),
              ),
            ),
          );
        }

        return SizedBox(
          height: 165,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              final content = note.jsonPayload['content']?.toString() ?? 'Empty Note';
              final date = '${note.createdAt.month}/${note.createdAt.day}';

              final bgColors = [const Color(0xFFF4F0FF), const Color(0xFFFFF9E6), const Color(0xFFEFFFF4)];
              final iconColors = [Colors.deepPurple, Colors.orange, Colors.green];
              final colorIndex = note.actionId.hashCode.abs() % bgColors.length;

              return Container(
                width: 170,
                margin: const EdgeInsets.only(right: 14),
                child: CustomCard(
                  backgroundColor: bgColors[colorIndex],
                  border: Border.all(color: iconColors[colorIndex].withValues(alpha: 0.2)),
                  onTap: () => _showExpandedNoteCard(context, ref, note, bgColors[colorIndex], iconColors[colorIndex]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.description_outlined, color: iconColors[colorIndex], size: 20),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_horiz_rounded, color: Colors.grey, size: 20),
                            padding: EdgeInsets.zero,
                            onSelected: (val) {
                              if (val == 'trash') {
                                final trashed = note.copyWith(status: 'FAILED');
                                ref.read(coreActionNotifierProvider.notifier).updateAction(trashed);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Note moved to Trash')),
                                );
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'trash',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                    SizedBox(width: 8),
                                    Text('Move to Trash', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                                  ],
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        note.jsonPayload['title']?.toString() ?? 'Quick Note',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Text(
                          content,
                          style: const TextStyle(fontSize: 12, color: Colors.black70),
                          overflow: TextOverflow.fade,
                        ),
                      ),
                      Text(date, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  void _showExpandedNoteCard(
      BuildContext context,
      WidgetRef ref,
      CoreAiAction note,
      Color bgColor,
      Color iconColor
  ) {
    final textController = TextEditingController(text: note.jsonPayload['content']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  title: Row(
                    children: [
                      Icon(Icons.edit_note_rounded, color: iconColor),
                      const SizedBox(width: 8),
                      const Text('Edit Note', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                  actions: [
                    TextButton.icon(
                      onPressed: () {
                        final newContent = textController.text.trim();
                        final updatedPayload = Map<String, dynamic>.from(note.jsonPayload);
                        updatedPayload['content'] = newContent;

                        final updatedNote = note.copyWith(jsonPayload: updatedPayload);
                        ref.read(coreActionNotifierProvider.notifier).updateAction(updatedNote);

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Note updated!'), backgroundColor: Colors.green),
                        );
                      },
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(foregroundColor: iconColor),
                    )
                  ],
                ),
                body: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: textController,
                          maxLines: null,
                          expands: true,
                          style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
                          decoration: const InputDecoration(
                            hintText: 'Write your thoughts...',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Created: ${note.createdAt.month}/${note.createdAt.day}',
                            style: const TextStyle(fontSize: 11, color: Colors.black45),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}