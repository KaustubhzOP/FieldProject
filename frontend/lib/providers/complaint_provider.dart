import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/complaint.dart';
import '../services/firestore_service.dart';
import '../services/email_service.dart';
import '../services/fcm_service.dart';
import '../utils/constants.dart';

class ComplaintProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  List<ComplaintModel> _complaints = [];
  bool _isLoading = false;
  String? _error;

  List<ComplaintModel> get complaints => _complaints;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Create complaint
  Future<bool> createComplaint(ComplaintModel complaint) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestoreService.setDocument(
        AppConstants.complaintsCollection,
        complaint.id,
        complaint.toJson(),
      );

      // Trigger Alerts (with deduplication inside methods)
      _triggerNewComplaintAlerts(complaint);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update complaint status
  Future<bool> updateComplaintStatus(String complaintId, String status, {String? remarks}) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection(AppConstants.complaintsCollection)
          .doc(complaintId)
          .get();
      final cData = snap.data() ?? {};
      final oldStatus = cData['status'] as String?;

      if (oldStatus == status) return true; // No change

      Map<String, dynamic> update = {'status': status};
      if (status == AppConstants.statusResolved) {
        update['resolvedAt'] = DateTime.now().toIso8601String();
      }
      if (remarks != null && remarks.isNotEmpty) {
        update['adminRemarks'] = remarks;
      }
      
      await _firestoreService.updateDocument(
        AppConstants.complaintsCollection,
        complaintId,
        update,
      );

      // Trigger Alerts (with deduplication inside methods)
      final updatedComplaintData = Map<String, dynamic>.from(cData);
      updatedComplaintData['status'] = status;
      updatedComplaintData['adminRemarks'] = remarks;
      
      _triggerStatusUpdateAlerts(complaintId, updatedComplaintData);

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Alert Triggers ─────────────────────────────────────────────────────────

  Future<void> _triggerNewComplaintAlerts(ComplaintModel c) async {
    // 1. Email Resident
    _emailForUser(
      userId: c.raisedBy,
      action: (email, name) => EmailService().sendComplaintRegistered(
        toEmail: email, toName: name,
        complaintId: c.id, type: c.type, description: c.description,
      ),
    );

    // 2. Alert Admins (Email + Push)
    _emailAllAdmins(
      residentId: c.raisedBy,
      complaintId: c.id,
      type: c.type,
      description: c.description,
      ward: 'Shared Area',
    );

    _pushToAllAdmins(
      complaintId: c.id,
      type: c.type,
      description: c.description,
      residentId: c.raisedBy,
    );
  }

  Future<void> _triggerStatusUpdateAlerts(String id, Map<String, dynamic> data) async {
    final status = data['status'];
    final userId = data['raisedBy'] ?? '';
    final remarks = data['adminRemarks'];
    print('[Provider] Triggering Alerts for $id | Status: $status | User: $userId');

    // 1. Email Resident
    _emailForUser(
      userId: userId,
      action: (email, name) async {
        print('[Provider] Resident Lookup Success: $email');
        if (status == AppConstants.statusInProgress) {
          await EmailService().sendComplaintInProgress(
            toEmail: email, toName: name, complaintId: id,
            type: data['type'] ?? 'General',
            description: data['description'] ?? '',
            remarks: remarks,
          );
        } else if (status == AppConstants.statusResolved || status == 'resolved') {
          await EmailService().sendComplaintResolved(
            toEmail: email, toName: name, complaintId: id,
            type: data['type'] ?? 'General',
            description: data['description'] ?? '',
            remarks: remarks,
          );
        }
      },
    );

    // 2. Push Resident
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final token = doc.data()?['fcmToken'] as String?;
    if (token != null && token.isNotEmpty) {
      String label = status == 'resolved' ? 'Resolved' : (status == 'in_progress' ? 'In Progress' : status);
      FcmService().sendDirectPush(
        token: token,
        title: '📋 Complaint Status Updated',
        body: 'Your complaint #$id is now $label.',
        data: {
          'type': 'status_update',
          'complaintId': id,
          'status': status,
        },
      );
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  // Get complaints by user
  Stream<List<ComplaintModel>> getComplaintsByUser(String userId) {
    return _firestoreService.getAllComplaints().map((snapshot) {
      final docs = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data() as Map);
        data['id'] = doc.id;
        return ComplaintModel.fromJson(data);
      });
      var list = docs.where((c) => c.raisedBy == userId).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // Get all complaints
  Stream<List<ComplaintModel>> getAllComplaints({String? status}) {
    return _firestoreService.getAllComplaints().map((snapshot) {
      var list = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data() as Map);
        data['id'] = doc.id;
        return ComplaintModel.fromJson(data);
      }).toList();
      if (status != null) {
        list = list.where((c) => c.status == status).toList();
      }
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // Fetch user name+email from Firestore, then call action
  Future<void> _emailForUser({
    required String userId,
    required Future<void> Function(String email, String name) action,
  }) async {
    if (userId.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (!doc.exists) return;
      final d = doc.data()!;
      final email = d['email'] as String? ?? '';
      final name  = d['name']  as String? ?? 'Resident';
      if (email.isEmpty) return;
      await action(email, name);
    } catch (e) {
      print('[Email] Error: $e');
    }
  }

  // Assign complaint to driver
  Future<bool> assignComplaint(String complaintId, String driverId) async {
    try {
      await _firestoreService.updateDocument(
        AppConstants.complaintsCollection,
        complaintId,
        {
          'assignedTo': driverId,
          'status': AppConstants.statusInProgress,
        },
      );
      
      // Trigger status update alert
      final snap = await FirebaseFirestore.instance.collection(AppConstants.complaintsCollection).doc(complaintId).get();
      _triggerStatusUpdateAlerts(complaintId, snap.data() ?? {});

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Add rating and feedback
  Future<bool> addFeedback(String complaintId, int rating, String feedback) async {
    try {
      await _firestoreService.updateDocument(AppConstants.complaintsCollection, complaintId, {
        'rating': rating,
        'feedback': feedback,
        'status': 'resolved',
      });
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete complaint
  Future<bool> deleteComplaint(String complaintId) async {
    try {
      await _firestoreService.deleteDocument(AppConstants.complaintsCollection, complaintId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() => notifyListeners();

  Future<void> _emailAllAdmins({
    required String residentId,
    required String complaintId,
    required String type,
    required String description,
    required String ward,
  }) async {
    try {
      String residentName = 'A Resident';
      String residentEmail = '';
      final resDoc = await FirebaseFirestore.instance.collection('users').doc(residentId).get();
      if (resDoc.exists) {
        residentName = resDoc.data()?['name'] as String? ?? 'A Resident';
        residentEmail = resDoc.data()?['email'] as String? ?? '';
      }

      final adminSnapshot = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'admin').get();
      print('[Email] Discovery: Found ${adminSnapshot.docs.length} admins in database.');
      
      for (final doc in adminSnapshot.docs) {
        final adminEmail = doc.data()['email'] as String? ?? '';
        if (adminEmail.isEmpty) continue;
        print('[Email] Attempting to alert admin: $adminEmail');
        EmailService().sendNewComplaintAlertToAdmin(
          adminEmail: adminEmail,
          residentName: residentName,
          residentEmail: residentEmail,
          complaintId: complaintId,
          type: type,
          description: description,
          ward: ward,
        ).catchError((e) => print('[Email] Admin alert failed: $e'));
      }
    } catch (e) {
      print('[Email] _emailAllAdmins error: $e');
    }
  }

  Future<void> _pushToAllAdmins({
    required String complaintId,
    required String type,
    required String description,
    required String residentId,
  }) async {
    try {
      String residentName = 'A Resident';
      final resDoc = await FirebaseFirestore.instance.collection('users').doc(residentId).get();
      if (resDoc.exists) residentName = resDoc.data()?['name'] ?? 'A Resident';

      final admins = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'admin').get();
      for (final doc in admins.docs) {
        final token = doc.data()['fcmToken'] as String? ?? '';
        if (token.isEmpty) continue;
        FcmService().sendDirectPush(
          token: token,
          title: '🚨 New Complaint — $type',
          body: '$residentName: $description',
          data: {'type': 'new_complaint', 'complaintId': complaintId},
        );
      }
    } catch (e) {
      print('[FCM] _pushToAllAdmins error: $e');
    }
  }
}
