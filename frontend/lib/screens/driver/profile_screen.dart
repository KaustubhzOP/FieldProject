import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../../config/app_colors.dart';
import 'dart:ui';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) return const Center(child: Text('Loading Profile...'));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('drivers').doc(user.id).snapshots(),
        builder: (context, snapshot) {
          final driverData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final bool isOnDuty = driverData['isOnDuty'] ?? false;
          final String truckNo = driverData['truckNumber'] ?? 'Not Assigned';
          final String ward = driverData['ward'] ?? 'Not Assigned';

          return Stack(
            children: [
              // 1. Nebula Background Header
              _buildNebulaHeader(context),
              
              // 2. Scrollable Content
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      _buildProfileAvatar(context, user.name, isOnDuty),
                      const SizedBox(height: 40),
                      _buildGlassSection(
                        title: 'OPERATIONAL STATUS',
                        children: [
                          _buildGlassTile(Icons.local_shipping_rounded, 'Fleet Asset', truckNo),
                          _buildGlassTile(Icons.map_rounded, 'Assigned Zone', ward),
                          _buildGlassTile(
                            Icons.timer_rounded, 
                            'Duty Session', 
                            isOnDuty ? 'ACTIVE ON DUTY' : 'OFF DUTY',
                            valueColor: isOnDuty ? AppColors.success : AppColors.textMuted
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildGlassSection(
                        title: 'ACCOUNT CREDENTIALS',
                        children: [
                          _buildGlassTile(Icons.badge_rounded, 'Operator ID', user.id.substring(0, 8).toUpperCase()),
                          _buildGlassTile(Icons.alternate_email_rounded, 'Access Email', user.email),
                        ],
                      ),
                      const SizedBox(height: 30),
                      _buildSignOutButton(context, authProvider),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNebulaHeader(BuildContext context) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF6366F1), // Indigo
            Color(0xFF0F172A),
            AppColors.background,
          ],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                width: 150, height: 150,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Color(0xFF6366F1).withOpacity(0.1)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context, String name, bool isOnDuty) {
    final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'D';
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.indigoAccent.withOpacity(0.2), width: 1.5),
                boxShadow: [BoxShadow(color: Colors.indigoAccent.withOpacity(0.2), blurRadius: 40, spreadRadius: 5)],
              ),
            ),
            CircleAvatar(
              radius: 54,
              backgroundColor: AppColors.secondary,
              child: Text(initials, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: isOnDuty ? AppColors.success : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 3),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(name, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(color: Colors.indigoAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.indigoAccent.withOpacity(0.2))),
          child: const Text('FLEET OPERATOR', style: TextStyle(color: Colors.indigoAccent, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        ),
      ],
    );
  }

  Widget _buildGlassSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
              ),
              child: Column(children: children),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassTile(IconData icon, String label, String value, {Color? valueColor}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.indigoAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
        child: Icon(icon, color: Colors.indigoAccent, size: 22),
      ),
      title: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
      subtitle: Text(value, style: TextStyle(color: valueColor ?? Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildSignOutButton(BuildContext context, AuthProvider authProvider) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () async {
          await authProvider.logout();
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
          }
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.error, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
            SizedBox(width: 12),
            Text('QUIT SYSTEM', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }
}
