import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

class LocationService {
  bool _isTracking = false;
  
  // Check and request location permission
  Future<bool> checkPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // Get current position
  Future<Position?> getCurrentPosition() async {
    bool hasPermission = await checkPermission();
    if (!hasPermission) {
      throw AppConstants.errorLocation;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      throw AppConstants.errorLocation;
    }
  }

  // Start tracking location
  Stream<Position> startTracking() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    );
  }

  // Stop tracking
  void stopTracking() {
    _isTracking = false;
  }

  // Calculate distance between two points (in meters)
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  // Calculate ETA (in minutes)
  int calculateETA(double distanceInMeters) {
    // Assuming average speed of 30 km/h in city
    double speedInMetersPerMinute = 500; // 30 km/h = 500 m/min
    return (distanceInMeters / speedInMetersPerMinute).ceil();
  }

  // Get address from coordinates
  Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return '${place.street}, ${place.locality}, ${place.administrativeArea}';
      }
    } catch (e) {
      return 'Unknown Location';
    }
    return 'Unknown Location';
  }
}
