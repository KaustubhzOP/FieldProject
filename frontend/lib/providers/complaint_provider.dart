import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/complaint.dart';
import '../services/firestore_service.dart';
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

  // Get complaints by user
  Stream<List<ComplaintModel>> getComplaintsByUser(String userId) {
    // Bypass buggy Firebase Web single-index constraints by dropping the argument and filtering here
    return _firestoreService.getAllComplaints().map((snapshot) {
      final docs = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data() as Map); // Mutable copy!
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
    // Drop the status filter from the Firebase query to avoid index/cache bugs on Flutter Web
    return _firestoreService.getAllComplaints().map((snapshot) {
      var list = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data() as Map); // Mutable copy!
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

  // Update complaint status
  Future<bool> updateComplaintStatus(String complaintId, String status) async {
    try {
      Map<String, dynamic> data = {'status': status};
      
      if (status == AppConstants.statusResolved) {
        data['resolvedAt'] = DateTime.now().toIso8601String();
      }
      
      await _firestoreService.updateDocument(
        AppConstants.complaintsCollection,
        complaintId,
        data,
      );
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
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
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Add rating and feedback
  Future<bool> addFeedback(
    String complaintId,
    int rating,
    String feedback,
  ) async {
    try {
      await _firestoreService.updateDocument(
        AppConstants.complaintsCollection,
        complaintId,
        {
          'rating': rating,
          'feedback': feedback,
          'status': 'resolved',
        },
      );
      
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
      await _firestoreService.deleteDocument(
        AppConstants.complaintsCollection,
        complaintId,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
