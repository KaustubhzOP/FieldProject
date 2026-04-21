import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import 'package:provider/provider.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/auth_provider.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 10,   // Very low quality to keep under Firestore 1MB limit
      maxWidth: 400,      // Cap dimensions to further reduce file size
      maxHeight: 400,
    );
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
            return _complaintSummaryItem(context, c.id, c.type, c.status.toUpperCase(), color, timeStr, c.description);
          },
        );
      },
    );
  }

  Widget _complaintSummaryItem(BuildContext context, String id, String type, String status, Color color, String time, String desc) {
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(
                status, 
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
              onPressed: () => _confirmDeletion(context, id),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletion(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.secondary,
        title: const Text('Delete Complaint?', style: TextStyle(color: Colors.white)),
        content: const Text('This action cannot be undone.', style: TextStyle(color: AppColors.textBody)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              context.read<ComplaintProvider>().deleteComplaint(id);
              Navigator.pop(ctx);
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Raise New Complaint', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () {
                          _resetForm();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildLocationIndicator(),
                  const SizedBox(height: 16),
                  _buildMiniMapPreview(),
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
                        helperText: '📍 Location attached successfully',
                        helperStyle: const TextStyle(color: Colors.teal, fontSize: 10),
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
                          final auth = context.read<AuthProvider>();
                          final user = auth.currentUser;
                          final userId = user?.id ?? 'unknown';
                          
                          // Senior Logic: Sync from current map session first, then home profile
                          final syncLat = auth.sessionSelection?.latitude;
                          final syncLng = auth.sessionSelection?.longitude;
                          
                          final lat = syncLat ?? user?.homeLat ?? user?.pendingLat ?? 0.0;
                          final lng = syncLng ?? user?.homeLng ?? user?.pendingLng ?? 0.0;

                          final newComplaint = ComplaintModel(
                            id: 'CMP-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                            type: _selectedType,
                            description: '[Priority: $_priority]\n${_descriptionController.text}',
                            location: LocationModel(latitude: lat, longitude: lng),
                            latitude: lat,
                            longitude: lng,
                            status: 'pending',
                            raisedBy: userId,
                            createdAt: DateTime.now(),
                            imageUrl: _base64Image,
                          );
                          
                          context.read<ComplaintProvider>().createComplaint(newComplaint).then((success) {
                            if (mounted) {
                              Navigator.pop(context); // Close Form
                              if (success) {
                                _showSuccessPopup();
                                _resetForm();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submission Failed'), backgroundColor: AppColors.error));
                              }
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
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        _resetForm();
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
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

  void _resetForm() {
    _descriptionController.clear();
    _base64Image = null;
    _selectedType = 'Missed Collection';
    _priority = 'Standard';
    setState(() {});
  }

  void _showSuccessPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.teal.withOpacity(0.5))),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline, color: Colors.teal, size: 60),
              SizedBox(height: 20),
              Text('Complaint Submitted!', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
              SizedBox(height: 8),
              Text('Our team will address this soon.', style: TextStyle(fontSize: 13, color: AppColors.textMuted, decoration: TextDecoration.none)),
            ],
          ),
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
    });
  }

  Widget _buildLocationIndicator() {
    final user = context.read<AuthProvider>().currentUser;
    final hasLoc = user?.homeLat != null || user?.pendingLat != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: hasLoc ? Colors.teal.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hasLoc ? Colors.teal.withOpacity(0.3) : Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(hasLoc ? Icons.location_on : Icons.location_off, color: hasLoc ? Colors.teal : Colors.orange, size: 14),
          const SizedBox(width: 8),
          Text(
            hasLoc ? 'Home Location Attached' : 'No Location Set (Register Home for Precision)',
            style: TextStyle(color: hasLoc ? Colors.teal : Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMapPreview() {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    final pos = auth.sessionSelection ?? 
              (user?.homeLat != null ? LatLng(user!.homeLat!, user.homeLng!) : null) ??
              (user?.pendingLat != null ? LatLng(user!.pendingLat!, user.pendingLng!) : null);

    if (pos == null) {
      return Container(
        height: 80,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, color: Colors.orange, size: 24),
            SizedBox(height: 8),
            Text('No Location Selected. Tap Main Map First.', style: TextStyle(color: Colors.orange, fontSize: 11)),
          ],
        ),
      );
    }

    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: GoogleMap(
          key: const Key('complaint_preview_map'),
          initialCameraPosition: CameraPosition(target: pos, zoom: 15),
          zoomGesturesEnabled: false,
          scrollGesturesEnabled: false,
          tiltGesturesEnabled: false,
          rotateGesturesEnabled: false,
          myLocationButtonEnabled: false,
          mapToolbarEnabled: false,
          markers: {
            Marker(markerId: const MarkerId('preview'), position: pos),
          },
        ),
      ),
    );
  }
}
