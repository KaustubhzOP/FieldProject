import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_colors.dart';
import '../resident/resident_home.dart';
import '../driver/driver_home.dart';
import '../admin/admin_home.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();
      
      bool success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (success && authProvider.currentUser != null) {
        _navigateToHome(authProvider.userRole!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Login failed'),
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
      default: homeScreen = const Scaffold(body: Center(child: Text('Invalid role')));
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => homeScreen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: AppColors.background),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  _buildHeader(),
                  const SizedBox(height: 50),
                  
                  _buildFieldLabel('Email Address'),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'name@example.com',
                      prefixIcon: Icon(Icons.email_outlined, size: 20),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : (!v.contains('@') ? 'Invalid email' : null),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  _buildFieldLabel('Password'),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
                  ),
                  
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                      child: const Text('Forgot Password?', style: TextStyle(color: AppColors.accent, fontSize: 13)),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) => ElevatedButton(
                      onPressed: auth.isLoading ? null : _handleLogin,
                      child: auth.isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Sign In'),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  _buildQuickSignIn(),
                  
                  const SizedBox(height: 32),
                  _buildFooterLink(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 60, width: 60,
          decoration: BoxDecoration(
            gradient: AppColors.accentGradient,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.4), blurRadius: 20)],
          ),
          child: const Icon(Icons.recycling_rounded, color: Colors.white, size: 35),
        ),
        const SizedBox(height: 24),
        const Text('Welcome Back', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 8),
        const Text('Enter your credentials to access the fleet monitoring system.', 
                   style: TextStyle(color: AppColors.textBody, fontSize: 15)),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14));
  }

  Widget _buildQuickSignIn() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('EXPLORE AS', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
            Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildRoleChip('Admin', 'superadmin@smartwaste.com', '123456'),
            const SizedBox(width: 12),
            _buildRoleChip('Driver', 'driver1@gmail.com', '123456'),
            const SizedBox(width: 12),
            _buildRoleChip('Resident', 'resident1@smartwaste.com', 'Demo@123'),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleChip(String label, String email, String password) {
    return InkWell(
      onTap: () {
        _emailController.text = email;
        _passwordController.text = password;
        _handleLogin();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFooterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("New to the system? ", style: TextStyle(color: AppColors.textBody)),
        TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
          child: const Text('Create Account', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
