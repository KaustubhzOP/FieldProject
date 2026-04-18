import 'package:flutter/material.dart';

class ComplaintScreen extends StatefulWidget {
  const ComplaintScreen({super.key});

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedType = 'Missed Collection';
  String _priority = 'Standard';
  final _descriptionController = TextEditingController();

  final List<String> _complaintTypes = [
    'Missed Collection',
    'Late Arrival',
    'Staff Behavior',
    'Incomplete Collection',
    'Spillage Issues',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text('Complaints & Requests'),
          bottom: const TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Resolved'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTabContent('pending'),
            _buildTabContent('resolved'),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showNewComplaintDialog(),
          label: const Text('New Complaint'),
          icon: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildTabContent(String status) {
    // Dummy filters for demo
    bool isPending = status == 'pending';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPending ? 'Active Issues' : 'Completed Requests',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),
          if (isPending) ...[
            _complaintSummaryItem('CMP-101', 'Missed Collection', 'Under Review', Colors.orange, '2 hrs ago'),
            _complaintSummaryItem('CMP-105', 'Late Arrival', 'In Progress', Colors.blue, '5 hrs ago'),
          ] else ...[
            _complaintSummaryItem('CMP-099', 'Spillage Issues', 'Resolved', Colors.green, '昨天'),
            _complaintSummaryItem('CMP-092', 'Staff Behavior', 'Closed', Colors.grey, '3 days ago'),
          ],
        ],
      ),
    );
  }

  Widget _complaintSummaryItem(String id, String type, String status, Color color, String time) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15), 
        side: BorderSide(color: Colors.grey.shade200)
      ),
      child: ListTile(
        title: Text(id, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$type • $time'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(
            status, 
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ),
    );
  }

  void _showNewComplaintDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20, left: 20, right: 20,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Raise New Complaint', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  const SizedBox(height: 20),
                  const Text('Complaint Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: _complaintTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                    onChanged: (value) => setModalState(() => _selectedType = value!),
                  ),
                  const SizedBox(height: 16),
                  const Text('Priority Level', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  // Fix for Overflow: use Wrap instead of Row
                  Wrap(
                    spacing: 8,
                    children: ['Standard', 'Urgent', 'Emergency'].map((p) {
                      bool isSelected = _priority == p;
                      return ChoiceChip(
                        label: Text(p),
                        selected: isSelected,
                        onSelected: (val) {
                          setModalState(() => _priority = p);
                          setState(() => _priority = p);
                        },
                        selectedColor: Colors.blue.withOpacity(0.2),
                        labelStyle: TextStyle(color: isSelected ? Colors.blue : Colors.black),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Description', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Enter details here...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'Description required' : null,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complaint Submitted!')));
                          _descriptionController.clear();
                        }
                      },
                      icon: const Icon(Icons.send),
                      label: const Text('Submit Complaint'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
