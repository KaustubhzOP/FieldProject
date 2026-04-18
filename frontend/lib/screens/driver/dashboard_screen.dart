import 'package:flutter/material.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  bool _isOnDuty = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Duty Toggle Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      _isOnDuty ? Icons.check_circle : Icons.cancel,
                      size: 60,
                      color: _isOnDuty ? Colors.green : Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isOnDuty ? 'You are ON DUTY' : 'You are OFF DUTY',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _isOnDuty = !_isOnDuty);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_isOnDuty ? 'Duty started!' : 'Duty ended!'),
                              backgroundColor: _isOnDuty ? Colors.green : Colors.orange,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isOnDuty ? Colors.red : Colors.green,
                          padding: const EdgeInsets.all(16),
                        ),
                        child: Text(_isOnDuty ? 'Stop Duty' : 'Start Duty'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Stats Cards
            Row(
              children: [
                Expanded(child: _buildStatCard('Collections', '5', Icons.check_circle)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard('Pending', '3', Icons.pending)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatCard('Distance', '12 km', Icons.location_on)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard('Time', '2.5 hrs', Icons.access_time)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 30, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
