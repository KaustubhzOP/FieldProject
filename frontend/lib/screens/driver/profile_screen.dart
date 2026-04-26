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
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.card,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('drivers').doc(user.id).snapshots(),
        builder: (context, snapshot) {
          final driverData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final bool isOnDuty = driverData['isOnDuty'] ?? false;
          final String truckNo = driverData['truckNumber'] ?? 'Not Assigned';
          final String ward = driverData['ward'] ?? 'Not Assigned';

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header with Avatar
                Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Container(
                      height: 100,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: _buildProfileAvatar(context, user.name, isOnDuty),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildProfileSection(
                        title: 'OPERATIONAL STATUS',
                        children: [
                          _buildProfileTile(Icons.local_shipping_rounded, 'Fleet Asset', truckNo),
                          _buildProfileTile(Icons.map_rounded, 'Assigned Zone', ward),
                          _buildProfileTile(
                            Icons.timer_rounded, 
                            'Duty Session', 
                            isOnDuty ? 'ACTIVE ON DUTY' : 'OFF DUTY',
                            valueColor: isOnDuty ? AppColors.success : AppColors.textMuted
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildProfileSection(
                        title: 'ACCOUNT CREDENTIALS',
                        children: [
                          _buildProfileTile(Icons.badge_rounded, 'Operator ID', user.id.substring(0, 8).toUpperCase()),
                          _buildProfileTile(Icons.alternate_email_rounded, 'Access Email', user.email),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _buildSignOutButton(context, authProvider),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 54,
                backgroundColor: AppColors.primary,
                child: Text(initials, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppColors.card, letterSpacing: -1)),
              ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: isOnDuty ? AppColors.success : AppColors.textMuted,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.card, width: 4),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(name, style: const TextStyle(color: AppColors.textHeader, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1), 
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: const Text('FLEET OPERATOR', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        ),
      ],
    );
  }

  Widget _buildProfileSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(children: _addDividers(children)),
        ),
      ],
    );
  }

  List<Widget> _addDividers(List<Widget> items) {
    List<Widget> result = [];
    for (int i = 0; i < items.length; i++) {
      result.add(items[i]);
      if (i < items.length - 1) {
        result.add(const Divider(height: 1, indent: 64, endIndent: 20, color: AppColors.border));
      }
    }
    return result;
  }

  Widget _buildProfileTile(IconData icon, String label, String value, {Color? valueColor}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: AppColors.primary, size: 24),
      ),
      title: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
      subtitle: Text(value, style: TextStyle(color: valueColor ?? AppColors.textHeader, fontSize: 15, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSignOutButton(BuildContext context, AuthProvider authProvider) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          await authProvider.logout();
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
          }
        },
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text('QUIT SYSTEM SESSION', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
