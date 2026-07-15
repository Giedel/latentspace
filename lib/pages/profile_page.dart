import 'package:flutter/material.dart';
import 'history_page.dart';
import 'trash_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // User Avatar Section
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFFF3E5F5),
              child: Text(
                'G',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF6B4FA0)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Giedel Dela Vega Escobido',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text(
              'giedel.escobido@example.com',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // Operational audit trail and safety options
            _buildProfileMenuItem(
              context,
              icon: Icons.history_rounded,
              title: 'History',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryPage()),
              ),
            ),
            const SizedBox(height: 12),
            _buildProfileMenuItem(
              context,
              icon: Icons.delete_outline_rounded,
              title: 'Trash Bin',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TrashPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenuItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
      }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF6B4FA0).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF6B4FA0)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}