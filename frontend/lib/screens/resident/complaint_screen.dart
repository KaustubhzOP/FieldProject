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
    return Scaffold(
      appBar: AppBar(title: const Text('Complaints & Requests')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Dummy Previous Complaints as requested (#1 and #2)
            _buildPreviousComplaints(),
            const SizedBox(height: 24),
            // Raise New Complaint Card
            _buildRaiseComplaintForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviousComplaints() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Complaints', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        _complaintSummaryItem('Complaint #1', 'Missed Collection', 'Pending', Colors.orange, '2 days ago'),
        _complaintSummaryItem('Complaint #2', 'Late Arrival', 'Resolved', Colors.green, '5 days ago'),
      ],
    );
  }

  Widget _complaintSummaryItem(String id, String type, String status, Color color, String time) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        title: Text(id, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$type • $time'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ),
    );
  }

  Widget _buildRaiseComplaintForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Raise New Complaint', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
              const SizedBox(height: 16),
              const Text('Priority Level', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: ['Standard', 'Urgent', 'Emergency'].map((p) {
                  bool isSelected = _priority == p;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(p),
                      selected: isSelected,
                      onSelected: (val) => setState(() => _priority = p),
                      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    ),
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
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complaint Submitted!')));
                      _descriptionController.clear();
                    }
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Submit Complaint'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
