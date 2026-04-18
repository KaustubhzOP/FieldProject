import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatelessWidget {
  final Function(int)? onTabSelected;
  const AdminDashboardScreen({super.key, this.onTabSelected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Stats Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(context, 'Active Drivers', '8', Icons.directions_car, Colors.green),
                _buildStatCard(context, 'Pending Complaints', '15', Icons.report, Colors.orange),
                _buildStatCard(context, 'Collections Today', '42', Icons.check_circle, Colors.blue),
                _buildStatCard(context, 'Avg Response', '12 min', Icons.timer, Colors.purple),
              ],
            ),
            const SizedBox(height: 24),
            // Quick Actions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    _buildActionTile(
                      context,
                      'Assign Routes',
                      Icons.route,
                      Colors.blue,
                      () => onTabSelected?.call(1),
                    ),
                    _buildActionTile(
                      context,
                      'View All Complaints',
                      Icons.report,
                      Colors.orange,
                      () => onTabSelected?.call(2),
                    ),
                    _buildActionTile(
                      context,
                      'Driver Performance',
                      Icons.people,
                      Colors.green,
                      () => onTabSelected?.call(3),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
