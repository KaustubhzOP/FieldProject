import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import 'package:provider/provider.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/auth_provider.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../../models/complaint.dart';
import '../../models/driver.dart';

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
  String? _base64Image;

  Future<void> _pickImage(StateSetter setModalState, ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 25);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setModalState(() {
        _base64Image = base64Encode(bytes);
      });
      setState(() {
        _base64Image = _base64Image;
      });
    }
  }

  void _showImagePickerOptions(StateSetter setModalState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.secondary,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(15))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.accent),
              title: const Text('Take Photo', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(setModalState, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.accent),
              title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(setModalState, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

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
    bool isPending = status == 'pending';
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<List<ComplaintModel>>(
      stream: context.read<ComplaintProvider>().getComplaintsByUser(user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accent));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text(isPending ? 'No active issues' : 'No resolved requests', style: const TextStyle(color: AppColors.textMuted)));
        }

        final filtered = snapshot.data!.where((c) {
           if (isPending) return c.status == 'pending' || c.status == 'in_progress';
           return c.status == 'resolved';
        }).toList();

        if (filtered.isEmpty) {
          return Center(child: Text(isPending ? 'No active issues' : 'No resolved requests', style: const TextStyle(color: AppColors.textMuted)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final c = filtered[index];
            final color = c.status == 'resolved' ? Colors.green : (c.status == 'in_progress' ? Colors.blue : Colors.orange);
            final timeStr = "${c.createdAt.day}/${c.createdAt.month}/${c.createdAt.year}";
            return _complaintSummaryItem(c.id, c.type, c.status.toUpperCase(), color, timeStr, c.description);
          },
        );
      },
    );
  }

  Widget _complaintSummaryItem(String id, String type, String status, Color color, String time, String desc) {
    return Card(
      elevation: 0,
      color: AppColors.secondary,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15), 
        side: BorderSide(color: Colors.white.withOpacity(0.05))
      ),
      child: ListTile(
        title: Text(id, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$type • $time', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 4),
            Text(desc, style: const TextStyle(color: AppColors.textBody, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
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
      backgroundColor: AppColors.background,
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
                  const Text('Raise New Complaint', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
                  const SizedBox(height: 20),
                  const Text('Complaint Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textMuted)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    dropdownColor: AppColors.secondary,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white24)),
                    ),
                    items: _complaintTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                    onChanged: (value) => setModalState(() => _selectedType = value!),
                  ),
                  const SizedBox(height: 16),
                  const Text('Priority Level', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textMuted)),
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
                        selectedColor: AppColors.accent.withOpacity(0.2),
                        backgroundColor: AppColors.secondary,
                        labelStyle: TextStyle(color: isSelected ? AppColors.accent : Colors.white),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Description', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textMuted)),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter details here...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white24)),
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'Description required' : null,
                  ),
                  const SizedBox(height: 16),
                  const Text('Attach Photo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textMuted)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _showImagePickerOptions(setModalState),
                    child: Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: _base64Image != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(base64Decode(_base64Image!), fit: BoxFit.cover),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, color: Colors.white54, size: 32),
                                SizedBox(height: 8),
                                Text('Tap to Upload', style: TextStyle(color: Colors.white54, fontSize: 12)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final userId = context.read<AuthProvider>().currentUser?.id ?? 'unknown';
                          final newComplaint = ComplaintModel(
                            id: 'CMP-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                            type: _selectedType,
                            description: '[Priority: $_priority]\n${_descriptionController.text}',
                            location: LocationModel(latitude: 0, longitude: 0),
                            status: 'pending',
                            raisedBy: userId,
                            createdAt: DateTime.now(),
                            imageUrl: _base64Image,
                          );
                          
                          context.read<ComplaintProvider>().createComplaint(newComplaint).then((success) {
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(success ? 'Complaint Submitted!' : 'Submission Failed'),
                                backgroundColor: success ? Colors.teal : AppColors.error,
                              ));
                              _descriptionController.clear();
                              setState(() => _base64Image = null);
                            }
                          });
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
