import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/complaint_provider.dart';
import '../../models/complaint.dart';
import '../../config/app_colors.dart';

class AdminComplaintManagementScreen extends StatelessWidget {
  const AdminComplaintManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
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
    return StreamBuilder<List<ComplaintModel>>(
      stream: context.read<ComplaintProvider>().getAllComplaints(status: status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accent));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No complaints found in this category.', style: TextStyle(color: AppColors.textMuted)));
        }

        final complaints = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: complaints.length,
          itemBuilder: (context, index) {
             final c = complaints[index];
             return Card(
               color: AppColors.secondary,
               margin: const EdgeInsets.only(bottom: 12),
               child: ListTile(
                 leading: Icon(
                   status == 'resolved' ? Icons.check_circle : (status == 'in_progress' ? Icons.autorenew : Icons.pending),
                   color: status == 'resolved' ? Colors.green : (status == 'in_progress' ? Colors.blue : Colors.orange),
                 ),
                 title: Text(c.id, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                 subtitle: Text('${c.type} • ${c.createdAt.day}/${c.createdAt.month}/${c.createdAt.year}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                 trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
                 onTap: () => _showComplaintDetails(context, c),
               ),
             );
          },
        );
      },
    );
  }

  void _showComplaintDetails(BuildContext context, ComplaintModel complaint) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.secondary,
        title: Text('${complaint.id} - ${complaint.type}', style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Details:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent)),
            const SizedBox(height: 4),
            Text(complaint.description, style: const TextStyle(color: AppColors.textBody)),
            const SizedBox(height: 16),
            const Text('Raised By (User ID):', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent)),
            const SizedBox(height: 4),
            Text(complaint.raisedBy, style: const TextStyle(color: AppColors.textBody, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE', style: TextStyle(color: Colors.white54)),
          ),
          if (complaint.status != 'resolved')
            ElevatedButton(
              onPressed: () {
                final newStatus = complaint.status == 'pending' ? 'in_progress' : 'resolved';
                context.read<ComplaintProvider>().updateComplaintStatus(complaint.id, newStatus);
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
              child: Text(complaint.status == 'pending' ? 'MARK IN PROGRESS' : 'MARK RESOLVED', style: const TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}
