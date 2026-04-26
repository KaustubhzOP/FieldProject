import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import 'dashboard_screen.dart';
import 'tracking_screen.dart';
import 'complaint_management_screen.dart';
import 'analytics_screen.dart';
import 'profile_screen.dart';

class AdminWebHome extends StatefulWidget {
  const AdminWebHome({super.key});

  @override
  State<AdminWebHome> createState() => _AdminWebHomeState();
}

class _AdminWebHomeState extends State<AdminWebHome> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      AdminDashboardScreen(onTabSelected: (idx) => setState(() => _selectedIndex = idx)),
      const AdminTrackingScreen(),
      AdminComplaintManagementScreen(),
      const AdminAnalyticsScreen(),
      const AdminProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Desktop Sidebar (Navigation Rail)
          NavigationRail(
            backgroundColor: AppColors.secondary,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
            labelType: NavigationRailLabelType.all,
            selectedIconTheme: const IconThemeData(color: AppColors.accent),
            unselectedIconTheme: const IconThemeData(color: AppColors.textMuted),
            selectedLabelTextStyle: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
            unselectedLabelTextStyle: const TextStyle(color: AppColors.textMuted),
            leading: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.recycling_rounded, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 30),
              ],
            ),
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.grid_view_rounded), label: Text('Dashboard')),
              NavigationRailDestination(icon: Icon(Icons.explore_outlined), label: Text('Tracking')),
              NavigationRailDestination(icon: Icon(Icons.assignment_outlined), label: Text('Requests')),
              NavigationRailDestination(icon: Icon(Icons.insights_rounded), label: Text('Analytics')),
              NavigationRailDestination(icon: Icon(Icons.manage_accounts_outlined), label: Text('Admin')),
            ],
          ),
          
          // Main Content Area
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: IndexedStack(index: _selectedIndex, children: screens),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
