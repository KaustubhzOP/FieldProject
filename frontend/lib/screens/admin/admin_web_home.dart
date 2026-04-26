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
          Container(
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: AppColors.border, width: 1)),
            ),
            child: NavigationRail(
              backgroundColor: AppColors.card,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
              labelType: NavigationRailLabelType.all,
              indicatorColor: AppColors.primary.withOpacity(0.1),
              indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              selectedIconTheme: const IconThemeData(color: AppColors.primary),
              unselectedIconTheme: const IconThemeData(color: AppColors.textMuted),
              selectedLabelTextStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
              unselectedLabelTextStyle: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w500),
              leading: Column(
                children: [
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: const Icon(Icons.recycling_rounded, color: AppColors.card, size: 28),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined), 
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: Text('Dashboard')
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.explore_outlined), 
                  selectedIcon: Icon(Icons.explore_rounded),
                  label: Text('Tracking')
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.assignment_outlined), 
                  selectedIcon: Icon(Icons.assignment_rounded),
                  label: Text('Requests')
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.insights_outlined), 
                  selectedIcon: Icon(Icons.insights_rounded),
                  label: Text('Analytics')
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.manage_accounts_outlined), 
                  selectedIcon: Icon(Icons.manage_accounts_rounded),
                  label: Text('Admin')
                ),
              ],
            ),
          ),
          
          // Main Content Area
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border, width: 1),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: IndexedStack(index: _selectedIndex, children: screens),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
