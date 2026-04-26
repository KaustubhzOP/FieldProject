import 'package:flutter/material.dart';
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
    NotificationService().processPendingNotifications();
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildBody(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            backgroundColor: AppColors.secondary,
            selectedItemColor: AppColors.accent,
            unselectedItemColor: AppColors.textMuted,
            showSelectedLabels: true,
            showUnselectedLabels: false,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.map_rounded), activeIcon: Icon(Icons.map_rounded), label: 'Track'),
              BottomNavigationBarItem(icon: Icon(Icons.campaign_outlined), activeIcon: Icon(Icons.campaign_rounded), label: 'Report'),
              BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), activeIcon: Icon(Icons.calendar_month_rounded), label: 'History'),
              BottomNavigationBarItem(icon: Icon(Icons.account_circle_outlined), activeIcon: Icon(Icons.account_circle_rounded), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}
