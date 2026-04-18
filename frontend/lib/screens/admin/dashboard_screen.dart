import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_requests_screen.dart';
import 'assign_route_screen.dart';
import '../../services/auth_service.dart';
import '../../config/app_colors.dart';

class AdminDashboardScreen extends StatelessWidget {
  final Function(int)? onTabSelected;
  const AdminDashboardScreen({super.key, this.onTabSelected});

  @override
  Widget build(BuildContext context) {
    final _authService = AuthService();
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildSectionHeader('Operations Overview'),
                  const SizedBox(height: 20),
                  _buildStatsGrid(),
                  const SizedBox(height: 40),
                  _buildSectionHeader('Management Suite'),
                  const SizedBox(height: 20),
                  _buildActionPanel(context, _authService),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      backgroundColor: AppColors.background,
      floating: false,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 20),
        title: const Text('Admin Console', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.secondary, AppColors.background],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5));
  }

  Widget _buildStatsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('homeStatus', whereIn: ['pending_approval', 'pending_removal'])
          .snapshots(),
      builder: (context, snapshot) {
        final pendingCount = snapshot.hasData ? snapshot.data!.docs.length.toString() : '...';
        
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('drivers')
              .where('isOnDuty', isEqualTo: true)
              .snapshots(),
          builder: (context, driverSnapshot) {
            final activeTrucks = driverSnapshot.hasData ? driverSnapshot.data!.docs.length.toString().padLeft(2, '0') : '...';
            
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildStatCard('Active Trucks', activeTrucks, Icons.local_shipping_rounded, AppColors.accent),
                _buildStatCard('Verifications', pendingCount, Icons.verified_user_rounded, Colors.tealAccent),
                _buildStatCard('Alerts', '12', Icons.notifications_active_rounded, Colors.orangeAccent),
                _buildStatCard('Ops Score', '94%', Icons.analytics_rounded, Colors.purpleAccent),
              ],
            );
          }
        );
      }
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionPanel(BuildContext context, AuthService authService) {
    return Column(
      children: [
        _buildAdvancedActionTile(
          context,
          'Route Assignments',
          'Manage truck paths and ward limits',
          Icons.alt_route_rounded,
          AppColors.accent,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAssignRouteScreen())),
        ),
        _buildAdvancedActionTile(
          context,
          'Verification Queue',
          'Process resident home location requests',
          Icons.playlist_add_check_rounded,
          Colors.tealAccent,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminHomeRequestsScreen())),
        ),
        _buildAdvancedActionTile(
          context,
          'System Diagnostics',
          'Optimize fleet and resident pickups',
          Icons.terminal_rounded,
          Colors.white70,
          () async {
            // Show Loading
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
            );
            
            try {
              await authService.pruneLegacyDrivers(); // Cleanup first
              await authService.seedDummyTrucks();    // Keep 1-5
              await authService.seedDemoResidents();  // Add pickups
              
              if (context.mounted) {
                Navigator.pop(context); // Close loading
                _showResultDialog(context, true, 'Environment Synced', 'Registry purged and demo data successfully seeded.');
              }
            } catch (e) {
              if (context.mounted) {
                Navigator.pop(context); // Close loading
                _showResultDialog(context, false, 'Sync Failed', 'Could not reach server. Please check your internet connection and try again.\n\nError: $e');
              }
            }
          },
        ),
        _buildAdvancedActionTile(
          context,
          'Community Hub',
          'Respond to resident complaints',
          Icons.forum_rounded,
          Colors.orangeAccent,
          () => onTabSelected?.call(2),
        ),
      ],
    );
  }

  void _showResultDialog(BuildContext context, bool success, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Color(0xFF1E293B),
        title: Row(
          children: [
            Icon(success ? Icons.check_circle_rounded : Icons.error_outline_rounded, color: success ? AppColors.success : AppColors.error),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: AppColors.textBody)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('UNDERSTOOD', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildAdvancedActionTile(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
