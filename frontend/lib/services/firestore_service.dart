import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generic get document
  Future<DocumentSnapshot> getDocument(String collection, String docId) async {
    return await _firestore.collection(collection).doc(docId).get();
  }

  // Generic add document
  Future<String> addDocument(String collection, Map<String, dynamic> data) async {
    DocumentReference docRef = await _firestore.collection(collection).add(data);
    return docRef.id;
  }

  // Generic set document with specific ID
  Future<void> setDocument(String collection, String docId, Map<String, dynamic> data) async {
    await _firestore.collection(collection).doc(docId).set(data);
  }

  // Generic update document
  Future<void> updateDocument(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection(collection).doc(docId).update(data);
  }

  // Generic delete document
  Future<void> deleteDocument(String collection, String docId) async {
    await _firestore.collection(collection).doc(docId).delete();
  }

  // Generic get collection stream
  Stream<QuerySnapshot> getCollectionStream(String collection) {
    return _firestore.collection(collection).snapshots();
  }

  // Generic query with filters
  Stream<QuerySnapshot> queryCollection(
    String collection, {
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    if (filters != null) {
      for (var filter in filters) {
        query = query.where(filter.field, isEqualTo: filter.value);
      }
    }

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots();
  }

  // Get drivers on duty
  Stream<QuerySnapshot> getDriversOnDuty() {
    return _firestore
        .collection(AppConstants.driversCollection)
        .where('isOnDuty', isEqualTo: true)
        .snapshots();
  }

  // Get complaints by user
  Stream<QuerySnapshot> getComplaintsByUser(String userId) {
    return _firestore
        .collection(AppConstants.complaintsCollection)
        .where('raisedBy', isEqualTo: userId)
        .snapshots();
  }

  // Get all complaints (Drop single-field filters to avoid Firebase Web Index constraints)
  Stream<QuerySnapshot> getAllComplaints() {
    return _firestore.collection(AppConstants.complaintsCollection).snapshots();
  }

  // Get routes by driver
  Stream<QuerySnapshot> getRoutesByDriver(String driverId) {
    return _firestore
        .collection(AppConstants.routesCollection)
        .where('assignedDriver', isEqualTo: driverId)
        .snapshots();
  }

  // Get all routes
  Stream<QuerySnapshot> getAllRoutes() {
    return _firestore
        .collection(AppConstants.routesCollection)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get collection records
  Stream<QuerySnapshot> getCollectionRecords({String? driverId}) {
    Query query = _firestore
        .collection(AppConstants.collectionsCollection)
        .orderBy('startTime', descending: true);

    if (driverId != null) {
      query = query.where('driverId', isEqualTo: driverId);
    }

    return query.snapshots();
  }

  // Update driver location
  Future<void> updateDriverLocation(String driverId, Map<String, dynamic> location) async {
    await _firestore
        .collection(AppConstants.driversCollection)
        .doc(driverId)
        .update({
      'lastLocation': location,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Mark waypoint as completed
  Future<void> markWaypointCompleted(
    String routeId,
    int waypointIndex,
  ) async {
    DocumentSnapshot doc = await _firestore
        .collection(AppConstants.routesCollection)
        .doc(routeId)
        .get();

    if (doc.exists) {
      List<dynamic> waypoints = doc['waypoints'];
      waypoints[waypointIndex]['completed'] = true;

      await _firestore
          .collection(AppConstants.routesCollection)
          .doc(routeId)
          .update({'waypoints': waypoints});
    }
  }

  // Get statistics
  Future<Map<String, int>> getStatistics() async {
    try {
      QuerySnapshot drivers = await _firestore
          .collection(AppConstants.driversCollection)
          .where('isOnDuty', isEqualTo: true)
          .get();

      QuerySnapshot pendingComplaints = await _firestore
          .collection(AppConstants.complaintsCollection)
          .where('status', isEqualTo: AppConstants.statusPending)
          .get();

      QuerySnapshot todayCollections = await _firestore
          .collection(AppConstants.collectionsCollection)
          .where('startTime', isGreaterThanOrEqualTo: DateTime.now().subtract(const Duration(hours: 24)).toIso8601String())
          .get();

      return {
        'activeDrivers': drivers.docs.length,
        'pendingComplaints': pendingComplaints.docs.length,
        'collectionsToday': todayCollections.docs.length,
      };
    } catch (e) {
      return {
        'activeDrivers': 0,
        'pendingComplaints': 0,
        'collectionsToday': 0,
      };
    }
  }
}

class QueryFilter {
  final String field;
  final dynamic value;

  QueryFilter({required this.field, required this.value});
}
