import 'package:flutter/material.dart';

class AdminComplaintManagementScreen extends StatelessWidget {
  const AdminComplaintManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Complaint Management'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'In Progress'),
              Tab(text: 'Resolved'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildComplaintList(context, 'pending'),
            _buildComplaintList(context, 'in_progress'),
            _buildComplaintList(context, 'resolved'),
          ],
        ),
      ),
    );
  }

  Widget _buildComplaintList(BuildContext context, String status) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            leading: Icon(
              status == 'resolved' ? Icons.check_circle : Icons.pending,
              color: status == 'resolved' ? Colors.green : Colors.orange,
            ),
            title: Text('Complaint #${index + 1}'),
            subtitle: Text('Ward ${String.fromCharCode(65 + index)} • ${index + 1} hours ago'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Show complaint details
            },
          ),
        );
      },
    );
  }
}
