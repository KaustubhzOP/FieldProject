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
      await _firestoreService.addDocument(
        AppConstants.complaintsCollection,
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
    return _firestoreService.getComplaintsByUser(userId).map((snapshot) {
      return snapshot.docs.map((doc) {
        return ComplaintModel.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Get all complaints
  Stream<List<ComplaintModel>> getAllComplaints({String? status}) {
    return _firestoreService.getAllComplaints(status: status).map((snapshot) {
      return snapshot.docs.map((doc) {
        return ComplaintModel.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
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

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
