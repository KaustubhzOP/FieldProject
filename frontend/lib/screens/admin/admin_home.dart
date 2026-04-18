import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'tracking_screen.dart';
import 'complaint_management_screen.dart';
import 'analytics_screen.dart';
import 'profile_screen.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _selectedIndex = 0;

  // Use a GlobalKey to access the scaffold for potential snackbars or drawers
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _onTabSelected(int index) {
    if (mounted) {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    // We recreate the screens list to ensure the current _onTabSelected is passed
    final List<Widget> screens = [
      AdminDashboardScreen(onTabSelected: _onTabSelected),
      const AdminTrackingScreen(),
      const AdminComplaintManagementScreen(),
      const AdminAnalyticsScreen(),
      const AdminProfileScreen(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabSelected,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on_outlined), activeIcon: Icon(Icons.location_on), label: 'Tracking'),
          BottomNavigationBarItem(icon: Icon(Icons.report_outlined), activeIcon: Icon(Icons.report), label: 'Complaints'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
