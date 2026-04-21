import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../config/app_colors.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Resident Verifications'),
        backgroundColor: AppColors.secondary,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }

          // Safe parsing
          List<QueryDocumentSnapshot> pendingDocs = [];
          if (snapshot.hasData && snapshot.data != null) {
            for (var doc in snapshot.data!.docs) {
              try {
                final data = doc.data() as Map<String, dynamic>?;
                if (data != null && (data['homeStatus'] == 'pending_approval' || data['homeStatus'] == 'pending_removal')) {
                  pendingDocs.add(doc);
                }
              } catch (e) {
                 // ignore corrupted docs
              }
            }
          }

          if (pendingDocs.isEmpty) {
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
            itemCount: pendingDocs.length,
            itemBuilder: (context, index) {
              final doc = pendingDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              bool isRemoval = data['homeStatus'] == 'pending_removal';
              
              String locText = 'No Coordinate Data';
              if (data['pendingLat'] != null && data['pendingLng'] != null) {
                locText = '${data['pendingLat']} , ${data['pendingLng']}';
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                color: AppColors.secondary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isRemoval ? Colors.red.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                        child: Icon(isRemoval ? Icons.delete_forever : Icons.home, 
                                   color: isRemoval ? Colors.redAccent : Colors.blueAccent),
                      ),
                      title: Text(data['name'] ?? 'Resident', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      subtitle: Text(isRemoval ? 'Requested Removal' : 'Requested Setup', style: const TextStyle(color: AppColors.textMuted)),
                    ),
                    if (!isRemoval)
                      Container(
                        height: 120,
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(
                                (data['pendingLat'] as num).toDouble(),
                                (data['pendingLng'] as num).toDouble(),
                              ),
                              zoom: 15,
                            ),
                            liteModeEnabled: true,
                            zoomGesturesEnabled: false,
                            scrollGesturesEnabled: false,
                            myLocationButtonEnabled: false,
                            mapToolbarEnabled: false,
                            markers: {
                              Marker(
                                markerId: MarkerId('req_${doc.id}'),
                                position: LatLng(
                                  (data['pendingLat'] as num).toDouble(),
                                  (data['pendingLng'] as num).toDouble(),
                                ),
                              ),
                            },
                          ),
                        ),
                      ),
                    
                    if (!isRemoval)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.blueAccent, size: 14),
                            const SizedBox(width: 8),
                            Expanded(child: Text('GPS Target: [$locText]', style: const TextStyle(fontSize: 11, color: AppColors.textMuted))),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => _handleAction(doc.id, false, isRemoval),
                            child: const Text('Reject', style: TextStyle(color: Colors.grey)),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () => _handleAction(doc.id, true, isRemoval),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isRemoval ? Colors.redAccent : Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
          await FirebaseFirestore.instance.collection('users').doc(userId).update({'homeStatus': 'approved'});
        }
      } else {
        await _authService.handleHomeApproval(userId, approved);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(approved ? 'Request Approved' : 'Request Rejected'), backgroundColor: Colors.teal),
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
