import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:latentspace/pages/profile_page.dart';
import 'dashboard_page.dart';
import 'todos_page.dart';
import 'money_page.dart';
import '../features/dashboard/presentation/widgets/multimodal_input_sheet.dart';

final navIndexProvider = StateProvider<int>((ref) => 0);

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navIndexProvider);

    // Pages that corresponds to nav items
    final List<Widget> pages = [
      const DashboardPage(),
      const TodosPage(),
      const MoneyPage(),
      const ProfilePage(), // Profile placeholder
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),

      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true, // Allows the sheet to adjust for the keyboard
            backgroundColor: Colors.transparent, // Keeps our custom rounded container styling
            builder: (context) => const MultimodalInputSheet(),
          );
        },
        elevation: 4,
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Floating Bottom Navigation Bar
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: BottomAppBar(
          padding: EdgeInsets.zero,
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: const AutomaticNotchedShape(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(30)),
            ),
          ),
          notchMargin: 12,
          child: SizedBox(
            height: 65,
            child: Row(
              children: [
                Expanded(
                  child: _buildNavItem(context, ref, Icons.home_rounded, 'Home', 0, currentIndex),
                ),
                Expanded(
                  child: _buildNavItem(context, ref, Icons.check_circle_outline_rounded, "To-do's", 1, currentIndex),
                ),
                
                // Space for FAB
                const SizedBox(width: 40), 
                
                Expanded(
                  child: _buildNavItem(context, ref, Icons.account_balance_wallet_rounded, 'Money', 2, currentIndex),
                ),
                Expanded(
                  child: _buildNavItem(context, ref, Icons.person_outline_rounded, 'Profile', 3, currentIndex),
                ),
              ],
            )
          )
        ),
      )
    );
  }

  Widget _buildNavItem(BuildContext context, WidgetRef ref, IconData icon, String label, int index, int currentIndex) {
    final isActive = index == currentIndex;
    final color = isActive ? Theme.of(context).colorScheme.primary : Colors.grey;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => ref.read(navIndexProvider.notifier).state = index,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: SizedBox(
          height: double.infinity, 
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            // 2. Change to max so the column stretches
            mainAxisSize: MainAxisSize.max, 
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              )
            ]
          )
        )
      )
    );
  }
}