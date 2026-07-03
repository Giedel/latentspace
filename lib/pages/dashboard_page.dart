import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latentspace/core/providers/database_providers.dart';
import '../features/ai_orchestrator/providers/core_action_provider.dart';
import '../features/ai_orchestrator/models/core_ai_action.dart';

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
                  return _buildPendingActions(pending);
                },
                orElse: () => const SizedBox.shrink(),
              ),

              _buildSectionHeader('Upcoming', 'View all'),
              const SizedBox(height: 16),
              _buildUpcomingTasks(),
              
              const SizedBox(height: 32),
              _buildSectionHeader('Recent Notes', 'View all'),
              const SizedBox(height: 16),
              _buildRecentNotes(),
              const SizedBox(height: 32), // Bottom padding
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Open multimodal input sheet (Text, Voice, Image)
        },
        backgroundColor: const Color(0xFF6B4FA0),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(),
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
            color: Colors.black.withOpacity(0.03),
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

  Widget _buildPendingActions(List<CoreAiAction> pendingActions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Needs Your Review', 'Clear all'),
        const SizedBox(height: 16),
        ...pendingActions.map((action) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4E5), // Light orange warning hue
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.psychology, color: Colors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Extracted a ${action.inferredDomain.toLowerCase()} from: "${action.rawUserInput}"',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        )),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildUpcomingTasks() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          _buildTaskItem(Icons.calendar_month, 'Team Meeting', '10:00 AM - 11:00 AM', 'In 1 hr', Colors.deepPurple, const Color(0xFFF3E5F5)),
          _buildDivider(),
          _buildTaskItem(Icons.check_box_outlined, 'Submit Capstone Proposal', '12:00 PM', 'In 3 hrs', Colors.green, const Color(0xFFE8F5E9)),
          _buildDivider(),
          _buildTaskItem(Icons.notifications_active_outlined, 'Review UI/UX Designs', '2:30 PM', 'In 5 hrs', Colors.orange, const Color(0xFFFFF3E0)),
          _buildDivider(),
          _buildTaskItem(Icons.card_giftcard, 'Dinner with Family', '7:00 PM', 'Today', Colors.redAccent, const Color(0xFFFFEBEE)),
        ],
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
    return Divider(height: 1, color: Colors.grey.withOpacity(0.1), indent: 64, endIndent: 16);
  }

  Widget _buildRecentNotes() {
    return SizedBox(
      height: 170,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          _buildNoteCard('Capstone Ideas', 'AI-powered note taking assistant for students...', 'Yesterday', const Color(0xFFF4F0FF), Colors.deepPurple),
          _buildNoteCard('UI Inspiration', 'Clean, minimal, and focused on usability first.', '2 days ago', const Color(0xFFFFF9E6), Colors.orange),
          _buildNoteCard('Feature Checklist', '• Notes\n• Tasks\n• Reminders\n• Calendar', '3 days ago', const Color(0xFFEFFFF4), Colors.green),
        ],
      ),
    );
  }

  Widget _buildNoteCard(String title, String content, String date, Color bgColor, Color iconColor) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.description_outlined, color: iconColor, size: 20),
              const Icon(Icons.more_horiz, color: Colors.grey, size: 20),
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
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: Colors.white,
      elevation: 10,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 'Home', true),
            _buildNavItem(Icons.note_alt_outlined, 'Notes', false),
            const SizedBox(width: 40), // Space for FAB
            _buildNavItem(Icons.check_box_outlined, 'Tasks', false),
            _buildNavItem(Icons.person_outline, 'Profile', false),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    final color = isActive ? const Color(0xFF6B4FA0) : Colors.grey;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}