import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                user?.name.substring(0, 1).toUpperCase() ?? 'A',
                style: const TextStyle(fontSize: 40, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(user?.name ?? 'Admin', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 32),
            Card(
              child: Column(
                children: [
                  ListTile(leading: const Icon(Icons.email), title: const Text('Email'), subtitle: Text(user?.email ?? '')),
                  ListTile(leading: const Icon(Icons.phone), title: const Text('Phone'), subtitle: Text(user?.phone ?? '')),
                  ListTile(leading: const Icon(Icons.admin_panel_settings), title: const Text('Role'), subtitle: const Text('Administrator')),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await authProvider.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.all(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
