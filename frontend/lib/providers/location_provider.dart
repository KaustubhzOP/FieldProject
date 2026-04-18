import 'package:flutter/material.dart';
import '../models/driver.dart';
import '../services/location_service.dart';

class LocationProvider with ChangeNotifier {
  final LocationService _locationService = LocationService();
  
  LocationModel? _currentLocation;
  bool _isTracking = false;
  String? _error;

  LocationModel? get currentLocation => _currentLocation;
  bool get isTracking => _isTracking;
  String? get error => _error;

  // Initialize location
  Future<void> initializeLocation() async {
    try {
      _error = null;
      notifyListeners();

      var position = await _locationService.getCurrentPosition();
      if (position != null) {
        _currentLocation = LocationModel(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Start tracking
  void startTracking() {
    _isTracking = true;
    notifyListeners();

    _locationService.startTracking().listen((position) {
      _currentLocation = LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      notifyListeners();
    });
  }

  // Stop tracking
  void stopTracking() {
    _isTracking = false;
    _locationService.stopTracking();
    notifyListeners();
  }

  // Calculate distance
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return _locationService.calculateDistance(lat1, lon1, lat2, lon2);
  }

  // Calculate ETA
  int calculateETA(double distanceInMeters) {
    return _locationService.calculateETA(distanceInMeters);
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
