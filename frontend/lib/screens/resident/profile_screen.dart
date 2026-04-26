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
          const SnackBar(content: Text('Profile updated successfully'), backgroundColor: AppColors.success),
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
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.card,
        elevation: 0,
        actions: [
          _isEditing 
            ? IconButton(icon: const Icon(Icons.check_rounded), onPressed: _handleSave)
            : IconButton(icon: const Icon(Icons.edit_note_rounded), onPressed: _toggleEdit),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
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
                  child: _buildProfileAvatar(context, user),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildProfileSection(
                      title: _isEditing ? 'EDITING PROFILE' : 'OPERATIONAL PROFILE',
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
                    const SizedBox(height: 20),
                    if (!_isEditing) ...[
                      _buildProfileSection(
                        title: 'ACCOUNT ACTIONS',
                        children: [
                          _buildResetLocationTile(context, user?.id ?? ''),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _buildSignOutButton(context, authProvider),
                    ] else ...[
                      const SizedBox(height: 20),
                      _buildSaveButton(authProvider.isLoading),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _toggleEdit,
                        child: Text('CANCEL CHANGES', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(IconData icon, String label, String value, {bool enabled = true}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: AppColors.primary, size: 18),
      ),
      title: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
      subtitle: Text(value, style: const TextStyle(color: AppColors.textBody, fontSize: 15)),
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
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
        subtitle: Text(controller.text.isEmpty ? 'Not set' : controller.text, style: const TextStyle(color: AppColors.textHeader, fontSize: 16, fontWeight: FontWeight.w600)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppColors.textHeader, fontSize: 16, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
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
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.card,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
        ),
        child: isLoading 
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.card, strokeWidth: 2))
          : const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context, dynamic user) {
    final initials = user?.name.isNotEmpty == true ? user!.name.substring(0, 1).toUpperCase() : 'U';
    return Column(
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
        const SizedBox(height: 16),
        Text(user?.name ?? 'Account User', style: const TextStyle(color: AppColors.textHeader, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.teal.withOpacity(0.1), 
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: AppColors.teal.withOpacity(0.2)),
          ),
          child: const Text('RESIDENT ACCOUNT', style: TextStyle(color: AppColors.teal, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
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

  Widget _buildResetLocationTile(BuildContext context, String userId) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.location_disabled_rounded, color: AppColors.warning, size: 24),
      ),
      title: const Text('Reset Home Location', style: TextStyle(color: AppColors.textHeader, fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: const Text('Clear verified location data', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
      onTap: () => _resetLocation(context, userId),
    );
  }

  Future<void> _resetLocation(BuildContext context, String userId) async {
     final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Reset Location?', style: TextStyle(color: AppColors.textHeader)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text('TERMINATE SESSION', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
      ),
    );
  }
}
