import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/collection_record.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';

class CollectionProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  List<CollectionRecordModel> _collections = [];
  bool _isLoading = false;
  String? _error;

  List<CollectionRecordModel> get collections => _collections;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get collection history for a specific driver (or all)
  Stream<List<CollectionRecordModel>> getCollectionHistory({String? driverId}) {
    return _firestoreService.getCollectionRecords(driverId: driverId).map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Ensure ID is included if missing
        if (data['id'] == null) data['id'] = doc.id;
        return CollectionRecordModel.fromJson(data);
      }).toList();
    });
  }

  // Helper stream specifically for residents (all collections in their ward)
  Stream<List<CollectionRecordModel>> getWardCollectionHistory(String ward) {
    // We remove .orderBy() to avoid the "Missing Index" error on Web.
    // Instead, we sort the list in-memory in the .map() block.
    return FirebaseFirestore.instance
        .collection(AppConstants.collectionsCollection)
        .where('ward', isEqualTo: ward)
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs.map((doc) {
        final data = doc.data();
        if (data['id'] == null) data['id'] = doc.id;
        return CollectionRecordModel.fromJson(data);
      }).toList();
      
      // Sort in-memory: Newer dates first
      docs.sort((a, b) => b.startTime.compareTo(a.startTime));
      return docs;
    });
  }

  // Helper stream for all recent collections
  Stream<List<CollectionRecordModel>> getRecentCollections(int limit) {
    return FirebaseFirestore.instance
        .collection(AppConstants.collectionsCollection)
        .orderBy('startTime', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        if (data['id'] == null) data['id'] = doc.id;
        return CollectionRecordModel.fromJson(data);
      }).toList();
    });
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
