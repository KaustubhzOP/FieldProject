<<<<<<< HEAD
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../../config/app_colors.dart';
import 'dart:ui';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
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
                  _buildProfileAvatar(context, user),
                  const SizedBox(height: 40),
                  _buildGlassSection(
                    title: 'OPERATIONAL PROFILE',
                    children: [
                      _buildGlassTile(Icons.alternate_email_rounded, 'Email Address', user?.email ?? ''),
                      _buildGlassTile(Icons.phone_iphone_rounded, 'Contact Number', user?.phone ?? 'Not set'),
                      _buildGlassTile(Icons.door_front_door_rounded, 'Service Address', user?.address ?? 'Not set'),
                      _buildGlassTile(Icons.token_rounded, 'Assigned Ward', user?.ward ?? 'Pending Assignment'),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _buildEditProfileButton(context, user, authProvider),
                  const SizedBox(height: 16),
                  _buildSignOutButton(context, authProvider),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
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
            AppColors.accent,
            Color(0xFF0F172A),
            AppColors.background,
          ],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(
                width: 200, height: 200,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.teal.withOpacity(0.15)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context, dynamic user) {
    final initials = user?.name.substring(0, 1).toUpperCase() ?? 'U';
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.3), blurRadius: 40, spreadRadius: 5)],
              ),
            ),
            CircleAvatar(
              radius: 54,
              backgroundColor: AppColors.secondary,
              child: Text(initials, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(user?.name ?? 'Account User', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.accent.withOpacity(0.2))),
          child: const Text('RESIDENT ACCOUNT', style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
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

  Widget _buildGlassTile(IconData icon, String label, String value) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
        child: Icon(icon, color: AppColors.accent, size: 22),
      ),
      title: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
      subtitle: Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildEditProfileButton(BuildContext context, dynamic user, AuthProvider authProvider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _showEditProfileDialog(context, user, authProvider),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_rounded, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text('EDIT PROFILE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, dynamic user, AuthProvider authProvider) {
    if (user == null) return;
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone);
    final addressController = TextEditingController(text: user.address);
    final wardController = TextEditingController(text: user.ward);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          top: 24, left: 24, right: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Operational Profile', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildEditField('Full Name', Icons.person_rounded, nameController),
              const SizedBox(height: 16),
              _buildEditField('Contact Number', Icons.phone_iphone_rounded, phoneController),
              const SizedBox(height: 16),
              _buildEditField('Service Address', Icons.door_front_door_rounded, addressController),
              const SizedBox(height: 16),
              _buildEditField('Assigned Ward', Icons.token_rounded, wardController),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    FocusScope.of(ctx).unfocus();
                    bool success = await authProvider.updateUserProfile(
                      name: nameController.text.trim(),
                      phone: phoneController.text.trim(),
                      address: addressController.text.trim(),
                      ward: wardController.text.trim(),
                    );
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                        content: Text(success ? 'Profile Successfully Updated!' : 'Failed to Update.'),
                        backgroundColor: success ? Colors.teal : AppColors.error,
                      ));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text('SAVE CHANGES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditField(String label, IconData icon, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted),
        prefixIcon: Icon(icon, color: AppColors.accent, size: 20),
        filled: true,
        fillColor: AppColors.secondary,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: AppColors.accent)),
      ),
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
            Text('TERMINATE SESSION', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }
}
=======
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../../config/app_colors.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';
import 'dart:ui';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _wardController;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: user?.name);
    _phoneController = TextEditingController(text: user?.phone);
    _addressController = TextEditingController(text: user?.address);
    _wardController = TextEditingController(text: user?.ward);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _wardController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Reset to original values on cancel
        final user = context.read<AuthProvider>().currentUser;
        _nameController.text = user?.name ?? '';
        _phoneController.text = user?.phone ?? '';
        _addressController.text = user?.address ?? '';
        _wardController.text = user?.ward ?? '';
      }
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await context.read<AuthProvider>().updateProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      ward: _wardController.text.trim(),
    );

    if (mounted) {
      if (success) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.teal),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile, try again'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildNebulaHeader(context),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    _buildProfileAvatar(context, user),
                    const SizedBox(height: 40),
                    _buildGlassSection(
                      title: _isEditing ? 'EDITING PROFILE' : 'OPERATIONAL PROFILE',
                      action: IconButton(
                        icon: Icon(_isEditing ? Icons.close_rounded : Icons.edit_note_rounded, color: Colors.white70),
                        onPressed: _toggleEdit,
                      ),
                      children: [
                        _buildField(Icons.alternate_email_rounded, 'Email Address', user?.email ?? '', enabled: false),
                        _buildEditableField(
                          Icons.person_rounded, 
                          'Full Name', 
                          _nameController,
                          validator: (v) => v!.isEmpty ? 'Name required' : null,
                        ),
                        _buildEditableField(
                          Icons.phone_iphone_rounded, 
                          'Contact Number', 
                          _phoneController,
                          keyboardType: TextInputType.phone,
                          validator: (v) {
                            if (v!.isEmpty) return 'Phone required';
                            if (!RegExp(r'^[0-9+ ]+$').hasMatch(v)) return 'Numeric only';
                            if (v.length < 10) return 'Too short';
                            return null;
                          },
                        ),
                        _buildEditableField(
                          Icons.door_front_door_rounded, 
                          'Service Address', 
                          _addressController,
                          validator: (v) => v!.isEmpty ? 'Address required' : null,
                        ),
                        _buildEditableField(
                          Icons.token_rounded, 
                          'Assigned Ward', 
                          _wardController,
                          hint: 'Enter your Ward',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (_isEditing)
                      _buildSaveButton(authProvider.isLoading)
                    else ...[
                      _buildGlassSection(
                        title: 'DEMO CONTROLS',
                        children: [
                          _buildResetLocationTile(context, user?.id ?? ''),
                        ],
                      ),
                      const SizedBox(height: 30),
                      _buildSignOutButton(context, authProvider),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(IconData icon, String label, String value, {bool enabled = true}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: Colors.white24, size: 18),
      ),
      title: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
      subtitle: Text(value, style: const TextStyle(color: Colors.white38, fontSize: 15)),
    );
  }

  Widget _buildEditableField(
    IconData icon, 
    String label, 
    TextEditingController controller, 
    {String? Function(String?)? validator, TextInputType? keyboardType, String? hint}
  ) {
    if (!_isEditing) {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
          child: Icon(icon, color: AppColors.accent, size: 22),
        ),
        title: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
        subtitle: Text(controller.text.isEmpty ? 'Not set' : controller.text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.accent, size: 20),
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accent)),
        ),
      ),
    );
  }

  Widget _buildSaveButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 10,
          shadowColor: AppColors.accent.withOpacity(0.5),
        ),
        child: isLoading 
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
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
          colors: [AppColors.accent, Color(0xFF0F172A), AppColors.background],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50, right: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.teal.withOpacity(0.15))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context, dynamic user) {
    final initials = user?.name.isNotEmpty == true ? user!.name.substring(0, 1).toUpperCase() : 'U';
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.3), blurRadius: 40, spreadRadius: 5)],
              ),
            ),
            CircleAvatar(
              radius: 54,
              backgroundColor: AppColors.secondary,
              child: Text(initials, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(user?.name ?? 'Account User', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.accent.withOpacity(0.2))),
          child: const Text('RESIDENT ACCOUNT', style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        ),
      ],
    );
  }

  Widget _buildGlassSection({required String title, required List<Widget> children, Widget? action}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              if (action != null) action,
            ],
          ),
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

  Widget _buildResetLocationTile(BuildContext context, String userId) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
        child: const Icon(Icons.restart_alt_rounded, color: Colors.orange, size: 22),
      ),
      title: const Text('Reset Home Location', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: const Text('Clear location data for testing', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
      onTap: () => _resetLocation(context, userId),
    );
  }

  Future<void> _resetLocation(BuildContext context, String userId) async {
     final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.secondary,
        title: const Text('Reset Location?', style: TextStyle(color: Colors.white)),
        content: const Text('This will clear your coordinates for testing.', style: TextStyle(color: AppColors.textBody)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('RESET', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed == true) {
      await AuthService().resetHomeStatus(userId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location reset successful!')));
    }
  }

  Widget _buildSignOutButton(BuildContext context, AuthProvider authProvider) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () async {
          await authProvider.logout();
          if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.error, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: const Text('TERMINATE SESSION', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
      ),
    );
  }
}
>>>>>>> 0317ea7 (2nd changes)
