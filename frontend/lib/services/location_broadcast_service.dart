import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handles real-time GPS location publishing to Firestore +
/// BLE advertising so nearby residents can detect the truck.
class LocationBroadcastService {
  static final LocationBroadcastService _instance = LocationBroadcastService._internal();
  factory LocationBroadcastService() => _instance;
  LocationBroadcastService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<Position>? _positionSubscription;
  bool _isBroadcasting = false;

  // Unique BLE service UUID for this app's trucks
  // Format we advertise: custom manufacturer data with driverId
  static const String truckServiceUuid = '0000FFF0-0000-1000-8000-00805F9B34FB';

  bool get isBroadcasting => _isBroadcasting;

  /// Call this when driver taps "Start Duty"
  Future<void> startBroadcasting(String driverId, String driverName) async {
    if (_isBroadcasting) return;

    // 1. Request location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    // On Android 11+, background permission (Always) must be requested AFTER foreground permission
    if (permission == LocationPermission.whileInUse) {
      // Prompt user specifically for 'Allow all the time'
      permission = await Geolocator.requestPermission();
    }

    if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) {
      throw 'Operational clearance requires location access. Please enable in settings.';
    }

    // 2. Start high-frequency GPS stream writing to Firestore
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 1, // Update every 1 meter physically moved
      ),
    ).listen((Position position) async {
      await _firestore.collection('drivers').doc(driverId).set({
        'driverId': driverId,
        'driverName': driverName,
        'liveLocation': {
          'lat': position.latitude,
          'lng': position.longitude,
          'heading': position.heading,
          'speed': position.speed * 3.6, // convert m/s to km/h
          'accuracy': position.accuracy,
          'timestamp': FieldValue.serverTimestamp(),
        },
        'isOnDuty': true,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    // 3. Start BLE advertising (truck beacon)
    await _startBleAdvertising(driverId);

    _isBroadcasting = true;
  }

  /// Call this when driver taps "Stop Duty"
  Future<void> stopBroadcasting(String driverId) async {
    _positionSubscription?.cancel();
    _positionSubscription = null;

    // Stop BLE advertising
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}

    // Update Firestore: mark off duty
    await _firestore.collection('drivers').doc(driverId).update({
      'isOnDuty': false,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    _isBroadcasting = false;
  }

  Future<void> _startBleAdvertising(String driverId) async {
    try {
      // Check if BLE is supported and on
      if (await FlutterBluePlus.isSupported == false) return;
      if (await FlutterBluePlus.adapterState.first == BluetoothAdapterState.off) return; // Silent fallback if off
      // Note: flutter_blue_plus doesn't support advertising on all devices.
      // In production, use flutter_ble_peripheral package for advertising.
      // For now, the GPS → Firestore path is the primary mechanism.
      // BLE advertising can be added as a separate enhancement.
    } catch (e) {
      // BLE advertising not available on this device, GPS fallback is active
    }
  }

  /// Get a real-time stream of all active driver locations from Firestore
  Stream<QuerySnapshot> getActiveDriversStream() {
    return _firestore
        .collection('drivers')
        .where('isOnDuty', isEqualTo: true)
        .snapshots();
  }

  /// Get distance in meters between two lat/lng points
  static double getDistance(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }
}
