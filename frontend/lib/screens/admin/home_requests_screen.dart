import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/auth_service.dart';
import '../../utils/map_styles.dart';

class AdminHomeRequestsScreen extends StatefulWidget {
  const AdminHomeRequestsScreen({super.key});

  @override
  State<AdminHomeRequestsScreen> createState() => _AdminHomeRequestsScreenState();
}

class _AdminHomeRequestsScreenState extends State<AdminHomeRequestsScreen> {
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resident Verifications'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          // Filter locally to avoid index or parsing bugs!
          final docs = snapshot.data!.docs.where((doc) {
            final status = (doc.data() as Map<String, dynamic>)['homeStatus'];
            return status == 'pending_approval' || status == 'pending_removal';
          }).toList();
          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.done_all, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text('All clear! No pending requests.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              bool isRemoval = data['homeStatus'] == 'pending_removal';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isRemoval ? Colors.red.shade100 : Colors.blue.shade100,
                        child: Icon(isRemoval ? Icons.delete_forever : Icons.home, 
                                   color: isRemoval ? Colors.red : Colors.blue),
                      ),
                      title: Text(data['name'] ?? 'Resident', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(isRemoval ? 'Requested Removal' : 'Requested New Setup'),
                      trailing: Text(
                        isRemoval ? 'REMOVE' : 'VERIFY',
                        style: TextStyle(
                          color: isRemoval ? Colors.red : Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (!isRemoval)
                      SizedBox(
                        height: 150,
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(data['pendingLat'], data['pendingLng']),
                            zoom: 15,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('pending'),
                              position: LatLng(data['pendingLat'], data['pendingLng']),
                            ),
                          },
                          style: MapStyles.silverStyle,
                          liteModeEnabled: true,
                          zoomControlsEnabled: false,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => _handleAction(doc.id, false, isRemoval),
                            child: const Text('Reject', style: TextStyle(color: Colors.grey)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _handleAction(doc.id, true, isRemoval),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isRemoval ? Colors.red : Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(isRemoval ? 'Approve Removal' : 'Approve Location'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleAction(String userId, bool approved, bool isRemoval) async {
    try {
      if (isRemoval) {
        if (approved) {
          await _authService.approveHomeRemoval(userId);
        } else {
          // Rejecting removal just resets back to approved
          await FirebaseFirestore.instance.collection('users').doc(userId).update({'homeStatus': 'approved'});
        }
      } else {
        await _authService.handleHomeApproval(userId, approved);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(approved ? 'Request Approved' : 'Request Rejected')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
