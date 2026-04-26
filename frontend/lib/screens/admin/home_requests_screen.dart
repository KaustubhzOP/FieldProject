import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../config/app_colors.dart';

class AdminHomeRequestsScreen extends StatefulWidget {
  const AdminHomeRequestsScreen({super.key});

  @override
  State<AdminHomeRequestsScreen> createState() => _AdminHomeRequestsScreenState();
}

class _AdminHomeRequestsScreenState extends State<AdminHomeRequestsScreen> {
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    print('DEBUG: Building HomeRequestsScreen');
    
    return Scaffold(
      backgroundColor: Colors.white, // Force extreme contrast for testing
      appBar: AppBar(
        title: const Text('Resident Verifications '),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('homeStatus', whereIn: ['pending_approval', 'pending_removal'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('FIREBASE ERROR: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          print('DEBUG: Found ${docs.length} pending requests');

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified, size: 100, color: Colors.green),
                  const SizedBox(height: 20),
                  Text('NO PENDING REQUESTS', style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final String userId = doc.id;
              final bool isRemoval = data['homeStatus'] == 'pending_removal';
              final String name = data['name'] ?? 'Unknown Resident';

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                    Text(isRemoval ? 'ACTION: REMOVE LOCATION' : 'ACTION: NEW SETUP', 
                         style: TextStyle(color: isRemoval ? Colors.red : Colors.blue, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _handleAction(userId, true, isRemoval),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                            child: const Text('APPROVE'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _handleAction(userId, false, isRemoval),
                            child: const Text('REJECT'),
                          ),
                        ),
                      ],
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
    } catch (e) {
      print('ERROR IN ACTION: $e');
    }
  }
}
