import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_colors.dart';
import 'home_screen.dart';
import 'complaint_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

import '../../services/notification_service.dart';

class ResidentHome extends StatefulWidget {
  const ResidentHome({super.key});

  @override
  State<ResidentHome> createState() => _ResidentHomeState();
}

class _ResidentHomeState extends State<ResidentHome> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      NotificationService().initialize(user.id);
      NotificationService().processPendingNotifications();
    }
  }
  
  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0: return const ResidentHomeScreen();
      case 1: return const ComplaintScreen();
      case 2: return const CollectionHistoryScreen();
      case 3: return const ProfileScreen();
      default: return const ResidentHomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 700;

    if (isWide) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: AppColors.card,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) => setState(() => _selectedIndex = index),
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: const IconThemeData(color: AppColors.primary),
              unselectedIconTheme: const IconThemeData(color: AppColors.textMuted),
              selectedLabelTextStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              unselectedLabelTextStyle: const TextStyle(color: AppColors.textMuted),
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.map_rounded), label: Text('Track')),
                NavigationRailDestination(icon: Icon(Icons.report_problem_rounded), label: Text('Report')),
                NavigationRailDestination(icon: Icon(Icons.history_rounded), label: Text('History')),
                NavigationRailDestination(icon: Icon(Icons.person_rounded), label: Text('Profile')),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1, color: AppColors.border),
            Expanded(child: _buildBody()),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildBody(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, -5))],
          border: const Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            backgroundColor: AppColors.card,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textMuted,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.map_rounded), activeIcon: Icon(Icons.map_rounded), label: 'Track'),
              BottomNavigationBarItem(icon: Icon(Icons.report_problem_rounded), activeIcon: Icon(Icons.report_problem_rounded), label: 'Report'),
              BottomNavigationBarItem(icon: Icon(Icons.history_rounded), activeIcon: Icon(Icons.history_rounded), label: 'History'),
              BottomNavigationBarItem(icon: Icon(Icons.person_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}
