import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_colors.dart';
import '../resident/resident_home.dart';
import '../driver/driver_home.dart';
import '../admin/admin_home.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  final _wardController = TextEditingController(text: 'Ward 1');
  final String _selectedRole = 'resident';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _wardController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();
      
      bool success = await authProvider.signup(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _selectedRole,
        address: _addressController.text.trim(),
        ward: _wardController.text,
      );

      if (!mounted) return;

      if (success && authProvider.currentUser != null) {
        _navigateToHome(authProvider.userRole!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Signup failed'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _navigateToHome(String role) {
    Widget homeScreen;
    switch (role) {
      case 'resident': homeScreen = const ResidentHome(); break;
      case 'driver': homeScreen = const DriverHome(); break;
      case 'admin': homeScreen = const AdminHome(); break;
      default: homeScreen = const LoginScreen();
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => homeScreen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(height: 30),
                const Text('Create Account', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                const Text('Join the smart waste management community today.', style: TextStyle(color: AppColors.textBody, fontSize: 15)),
                const SizedBox(height: 40),
                
                _buildFieldLabel('Full Name'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(hintText: 'John Doe', prefixIcon: Icon(Icons.person_outline_rounded, size: 20)),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                
                const SizedBox(height: 20),
                _buildFieldLabel('Email Address'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'name@example.com', prefixIcon: Icon(Icons.email_outlined, size: 20)),
                  validator: (v) => v!.isEmpty ? 'Required' : (!v.contains('@') ? 'Invalid email' : null),
                ),

                const SizedBox(height: 20),
                _buildFieldLabel('Primary Ward'),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _wardController.text,
                  items: ['Ward 1', 'Ward 2', 'Ward 3', 'Ward 4', 'Ward 5']
                      .map((w) => DropdownMenuItem(value: w, child: Text(w, style: const TextStyle(color: Colors.white))))
                      .toList(),
                  onChanged: (val) => setState(() => _wardController.text = val ?? 'Ward 1'),
                  dropdownColor: AppColors.secondary,
                  iconEnabledColor: AppColors.accent,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.business_rounded, size: 20)),
                ),
                
                const SizedBox(height: 20),
                _buildFieldLabel('Password'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: 'Min 6 characters', prefixIcon: Icon(Icons.lock_outline_rounded, size: 20)),
                  validator: (v) => v!.length < 6 ? 'Too short' : null,
                ),
                
                const SizedBox(height: 20),
                _buildFieldLabel('Confirm Password'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: 'Repeat password', prefixIcon: Icon(Icons.lock_rounded, size: 20)),
                  validator: (v) => v != _passwordController.text ? 'Mismatch' : null,
                ),
                
                const SizedBox(height: 40),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) => ElevatedButton(
                    onPressed: auth.isLoading ? null : _handleSignup,
                    child: auth.isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Create Account'),
                  ),
                ),
                const SizedBox(height: 30),
                _buildFooterLink(),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14));
  }

  Widget _buildFooterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Already a member? ", style: TextStyle(color: AppColors.textBody)),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Sign In', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
