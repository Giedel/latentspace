import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/ai_orchestrator/providers/core_action_provider.dart';
import '../features/ai_orchestrator/models/core_ai_action.dart';
import '../features/user_tasks/providers/task_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionsState = ref.watch(coreActionNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // Clean off-white background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildSearchBar(),
              const SizedBox(height: 32),
              
              // Human-In-The-Loop (HITL) Validation Section
              // Only appears if the SLM has extracted data waiting for approval
              actionsState.maybeWhen(
                data: (actions) {
                  final pending = actions.where((a) => a.status == 'PENDING').toList();
                  if (pending.isEmpty) return const SizedBox.shrink();
                  return _buildPendingActions(context, ref, pending);
                },
                orElse: () => const SizedBox.shrink(),
              ),

              _buildSectionHeader('Upcoming', 'View all'),
              const SizedBox(height: 16),
              _buildUpcomingTasks(ref),
              
              const SizedBox(height: 32),
              _buildSectionHeader('Recent Notes', 'View all'),
              const SizedBox(height: 16),
              _buildRecentNotes(ref),
              const SizedBox(height: 32), // Bottom padding
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
            const Icon(Icons.menu, size: 28),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Good morning, Giedel! 👋',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Capture ideas. Stay organized.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 24),
            const SizedBox(width: 16),
            Stack(
              children: [
                const Icon(Icons.notifications_none, size: 28),
                Positioned(
                  right: 2,
                  top: 2,
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

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search notes...',
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String actionText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          actionText,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B4FA0), fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildPendingActions(BuildContext context, WidgetRef ref, List<CoreAiAction> pendingActions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Needs Your Review', 'Clear all'),
        const SizedBox(height: 16),
        ...pendingActions.map((action) => Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showReviewDialog(context, ref, action), // Opens the HITL Dialog
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E5), // Light orange warning hue
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)), // Added a subtle border
              ),
              child: Row(
                children: [
                  const Icon(Icons.psychology, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Review ${action.inferredDomain.toLowerCase()}: "${action.rawUserInput}"',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        )),
        const SizedBox(height: 24),
      ],
    );
  }

  void _showReviewDialog(BuildContext context, WidgetRef ref, CoreAiAction action) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                // Updated to _rounded icons
                Icon(
                    action.inferredDomain == 'FINANCE' ? Icons.account_balance_wallet_rounded
                        : action.inferredDomain == 'NOTE' ? Icons.note_alt_rounded
                        : Icons.check_circle_outline_rounded,
                    color: const Color(0xFF6B4FA0)
                ),
                const SizedBox(width: 12),
                Text(
                    'Review ${action.inferredDomain}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The original conversational input
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Updated to _rounded
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

                const SizedBox(height: 20),
                const Text('Extracted Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),

                // Human-Readable Parsed Data (Icons removed)
                _buildHumanReadablePayload(action.inferredDomain, action.jsonPayload),
              ],
            ),
            actionsPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            actions: [
              TextButton(
                onPressed: () {
                  final rejectedAction = action.copyWith(status: 'FAILED');
                  ref.read(coreActionNotifierProvider.notifier).updateAction(rejectedAction);
                  Navigator.pop(context);
                },
                child: const Text('Discard', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
              ),
              FilledButton(
                onPressed: () async {
                  await ref.read(coreActionNotifierProvider.notifier).approveAndRouteAction(action);

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${action.inferredDomain} saved successfully!'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        )
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6B4FA0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Approve & Save', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
    );
  }

  /// Helper widget to parse the JSON into a beautiful UI based on the domain
  Widget _buildHumanReadablePayload(String domain, Map<String, dynamic> payload) {
    List<Widget> rows = [];

    if (domain == 'FINANCE') {
      final amount = payload['amount_cents'] != null ? (payload['amount_cents'] / 100).toStringAsFixed(2) : '0.00';
      final currency = payload['currency'] ?? 'PHP';

      // Removed the IconData parameter from _buildDetailRow calls
      rows = [
        _buildDetailRow('Amount', '$currency $amount', valueColor: Colors.green.shade700),
        _buildDetailRow('Category', payload['primary_category'] ?? 'N/A'),
        _buildDetailRow('Type', payload['transaction_type'] ?? 'N/A'),
      ];
    }
    else if (domain == 'TO-DO' || domain == 'REMINDER') {
      String readableDate = 'No date set';
      if (payload['due_date'] != null) {
        final date = DateTime.tryParse(payload['due_date'].toString());
        if (date != null) {
          readableDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
        }
      }

      rows = [
        _buildDetailRow('Task', payload['title'] ?? 'N/A'),
        _buildDetailRow('Due', readableDate),
      ];
    }
    else if (domain == 'NOTE') {
      rows = [
        _buildDetailRow('Content', payload['content'] ?? 'N/A'),
      ];
    }
    else {
      rows = payload.entries.map((e) => _buildDetailRow(e.key, e.value.toString())).toList();
    }

    return Column(children: rows);
  }

  /// Small helper to render consistent rows for the extracted data
  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTasks(WidgetRef ref) {
    // Listen to the SQLite task database
    final tasksState = ref.watch(upcomingTasksProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
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
          if (tasks.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: Text('No upcoming tasks.', style: TextStyle(color: Colors.grey))),
            );
          }

          return Column(
            children: tasks.asMap().entries.map((entry) {
              final index = entry.key;
              final task = entry.value;
              final isLast = index == tasks.length - 1;

              // Parse date for UI
              String timeDisplay = 'No date';
              if (task.dueDate != null) {
                final d = DateTime.tryParse(task.dueDate!);
                if (d != null) {
                  timeDisplay = '${d.month}/${d.day} at ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
                }
              }

              return Column(
                children: [
                  _buildTaskItem(
                      Icons.check_circle_outline,
                      task.title,
                      timeDisplay,
                      'Pending',
                      Colors.deepPurple,
                      const Color(0xFFF3E5F5)
                  ),
                  if (!isLast) _buildDivider(),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildTaskItem(IconData icon, String title, String time, String status, Color accentColor, Color bgColor) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(status, style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          CircleAvatar(radius: 3, backgroundColor: accentColor),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey.withValues(alpha: 0.1), indent: 64, endIndent: 16);
  }

  Widget _buildRecentNotes(WidgetRef ref) {
    final actionsState = ref.watch(coreActionNotifierProvider);

    return actionsState.maybeWhen(
      data: (actions) {
        // Only show completed notes that are NOT trashed (status is COMPLETED)
        final notes = actions
            .where((a) => a.inferredDomain == 'NOTE' && a.status == 'COMPLETED')
            .take(5)
            .toList();

        if (notes.isEmpty) {
          return const SizedBox(
              height: 100,
              child: Center(child: Text('No recent notes.', style: TextStyle(color: Colors.grey)))
          );
        }

        return SizedBox(
          height: 170,
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

              return _buildNoteCard(
                  context,
                  ref,
                  note,
                  'Quick Note',
                  content,
                  date,
                  bgColors[colorIndex],
                  iconColors[colorIndex]
              );
            },
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildNoteCard(
      BuildContext context,
      WidgetRef ref,
      CoreAiAction note,
      String title,
      String content,
      String date,
      Color bgColor,
      Color iconColor
      ) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          // 💡 Tapping the card opens the centered, expanded editor card
          onTap: () => _showExpandedNoteCard(context, ref, note, bgColor, iconColor),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.description_outlined, color: iconColor, size: 20),
                    // 💡 Replaced static three-dots icon with an interactive PopupMenu
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz, color: Colors.grey, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      style: const ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      onSelected: (value) {
                        if (value == 'trash') {
                          // Moves the note to trash (changes status to FAILED in SQLite)
                          final trashedNote = note.copyWith(status: 'FAILED');
                          ref.read(coreActionNotifierProvider.notifier).updateAction(trashedNote);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Note moved to Trash'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem<String>(
                          value: 'trash',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                              SizedBox(width: 8),
                              Text('Move to Trash', style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    content,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                    overflow: TextOverflow.fade,
                  ),
                ),
                Text(date, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
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
      barrierDismissible: true, // Tap outside to dismiss without saving
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          backgroundColor: Colors.transparent, // Allow card custom container styling
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500), // Ensures it stays centered and middled
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
                backgroundColor: Colors.transparent, // Match parent wrapper color
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  automaticallyImplyLeading: false,
                  title: Row(
                    children: [
                      Icon(Icons.edit_note_rounded, color: iconColor),
                      const SizedBox(width: 8),
                      const Text(
                          'Edit Note',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)
                      ),
                    ],
                  ),
                  actions: [
                    // Save Button in the top right
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: TextButton.icon(
                        onPressed: () {
                          final newContent = textController.text.trim();

                          // Prepare updated JSON payload for SQLite
                          final updatedPayload = Map<String, dynamic>.from(note.jsonPayload);
                          updatedPayload['content'] = newContent;

                          final updatedNote = note.copyWith(jsonPayload: updatedPayload);
                          ref.read(coreActionNotifierProvider.notifier).updateAction(updatedNote);

                          Navigator.pop(context); // Close the dialog

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Note saved successfully!'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(
                          foregroundColor: iconColor,
                        ),
                      ),
                    )
                  ],
                ),
                body: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: textController,
                          maxLines: null, // Makes text area auto-wrap and scrollable
                          expands: true, // Fills the available space in the card
                          keyboardType: TextInputType.multiline,
                          style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
                          decoration: const InputDecoration(
                            hintText: 'Write your thoughts here...',
                            hintStyle: TextStyle(color: Colors.black26),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Created: ${note.createdAt.month}/${note.createdAt.day}',
                            style: const TextStyle(fontSize: 11, color: Colors.black38, fontWeight: FontWeight.w500),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel', style: TextStyle(color: Colors.black54, fontSize: 13)),
                          ),
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

  void _showNoteDetailSheet(BuildContext context, WidgetRef ref, CoreAiAction note, Color bgColor) {
    final TextEditingController editController = TextEditingController(
      text: note.jsonPayload['content']?.toString() ?? '',
    );

    // State management inside the sheet for toggling Edit Mode
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setSheetState) {
              bool isEditing = false;

              return Container(
                margin: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    left: 16,
                    right: 16,
                    top: 40
                ),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: bgColor, // Matches the selected card color
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28), bottom: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Quick Note',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                        ),
                        Row(
                          children: [
                            // Discard / Move to Trash Option
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                              onPressed: () {
                                // Setting status to FAILED marks it for the Trash/History views
                                final trashedNote = note.copyWith(status: 'FAILED');
                                ref.read(coreActionNotifierProvider.notifier).updateAction(trashedNote);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Note moved to Trash'),
                                      behavior: SnackBarBehavior.floating,
                                    )
                                );
                              },
                            ),
                            // Edit / Save Switch
                            IconButton(
                              icon: Icon(isEditing ? Icons.check_rounded : Icons.edit_outlined, color: const Color(0xFF6B4FA0)),
                              onPressed: () {
                                if (isEditing) {
                                  // Save edited text to JSON payload
                                  final updatedPayload = Map<String, dynamic>.from(note.jsonPayload);
                                  updatedPayload['content'] = editController.text;

                                  final updatedNote = note.copyWith(jsonPayload: updatedPayload);
                                  ref.read(coreActionNotifierProvider.notifier).updateAction(updatedNote);
                                }
                                setSheetState(() {
                                  isEditing = !isEditing;
                                });
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                    const Divider(color: Colors.black12),
                    const SizedBox(height: 12),

                    // Dynamic view switcher based on Edit Mode
                    isEditing
                        ? TextField(
                      controller: editController,
                      maxLines: 6,
                      autofocus: true,
                      style: const TextStyle(fontSize: 15, color: Colors.black87),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Write your note...',
                      ),
                    )
                        : Text(
                      note.jsonPayload['content']?.toString() ?? 'Empty Note',
                      style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Created on: ${note.createdAt.year}-${note.createdAt.month.toString().padLeft(2, '0')}-${note.createdAt.day.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 11, color: Colors.black38),
                    ),
                  ],
                ),
              );
            }
        );
      },
    );
  }
}