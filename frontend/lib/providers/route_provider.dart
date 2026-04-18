import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/route.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';

class RouteProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  List<RouteModel> _routes = [];
  RouteModel? _currentRoute;
  bool _isLoading = false;
  String? _error;

  List<RouteModel> get routes => _routes;
  RouteModel? get currentRoute => _currentRoute;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get routes by driver
  Stream<List<RouteModel>> getRoutesByDriver(String driverId) {
    return _firestoreService.getRoutesByDriver(driverId).map((snapshot) {
      return snapshot.docs.map((doc) {
        return RouteModel.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Get all routes
  Stream<List<RouteModel>> getAllRoutes() {
    return _firestoreService.getAllRoutes().map((snapshot) {
      return snapshot.docs.map((doc) {
        return RouteModel.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Create route
  Future<bool> createRoute(RouteModel route) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestoreService.addDocument(
        AppConstants.routesCollection,
        route.toJson(),
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

  // Update route
  Future<bool> updateRoute(RouteModel route) async {
    try {
      await _firestoreService.updateDocument(
        AppConstants.routesCollection,
        route.id,
        route.toJson(),
      );
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Assign driver to route
  Future<bool> assignDriver(String routeId, String driverId) async {
    try {
      await _firestoreService.updateDocument(
        AppConstants.routesCollection,
        routeId,
        {
          'assignedDriver': driverId,
          'status': AppConstants.routeAssigned,
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

  // Mark waypoint as completed
  Future<bool> markWaypointCompleted(String routeId, int waypointIndex) async {
    try {
      await _firestoreService.markWaypointCompleted(routeId, waypointIndex);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update route status
  Future<bool> updateRouteStatus(String routeId, String status) async {
    try {
      await _firestoreService.updateDocument(
        AppConstants.routesCollection,
        routeId,
        {'status': status},
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
