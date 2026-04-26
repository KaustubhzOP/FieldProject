import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';

import 'fcm_service.dart';
import 'notification_service.dart';

// Smart truck BLE Service UUID - what residents scan for
const String smartBinServiceUuid = '0000FFE0-0000-1000-8000-00805F9B34FB';

/// Monitors driver proximity on the RESIDENT's device.
/// When a driver comes within [proximityRadius] meters:
///   → Sends an FCM push notification to this resident's device.
class ProximityScannerService {
  static final ProximityScannerService _instance = ProximityScannerService._internal();
  factory ProximityScannerService() => _instance;
  ProximityScannerService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription? _bleScanSubscription;
  bool _isActive = false;
  String _residentId = '';
  // Track which levels have been notified per truck (TruckID -> Set of Milestones)
  final Map<String, Set<int>> _notifiedMilestones = {};

  static const double proximityRadius = 400.0; // meters (Expanded for testing)

  /// Call this after the resident logs in.
  Future<void> startMonitoring({
    required double residentLat,
    required double residentLng,
    required String residentId,
  }) async {
    if (_residentId == residentId && _isActive) return;
    
    _residentId = residentId;
    await stopMonitoring();
    _isActive = true;
    _notifiedMilestones.clear();

    // BLE disabled — GPS/Firestore handles all proximity alerts
    _startGpsFallback(residentLat, residentLng);
  }

  Future<void> _startBleScan() async {
    try {
      await FlutterBluePlus.startScan(
        withServices: [Guid(smartBinServiceUuid)],
        timeout: const Duration(minutes: 5),
      );
      _bleScanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          if (r.rssi > -80) {
            _checkMilestones('ble_truck', 50.0);
          }
        }
      });
    } on Exception catch (_) {
      // BLE unavailable (Bluetooth off, no permission, etc.) — GPS fallback handles everything
    }
  }

  StreamSubscription? _firestoreSubscription;

  void _startGpsFallback(double residentLat, double residentLng) {
    _firestoreSubscription = _firestore
        .collection('drivers')
        .where('isOnDuty', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final String truckId = doc.id;
        final location = data['liveLocation'];
        if (location == null) continue;

        final double driverLat = (location['lat'] as num).toDouble();
        final double driverLng = (location['lng'] as num).toDouble();

        final double distance = Geolocator.distanceBetween(
          residentLat, residentLng,
          driverLat, driverLng,
        );

        _checkMilestones(truckId, distance);
      }
    });
  }

  void _checkMilestones(String truckId, double distance) {
    if (!_notifiedMilestones.containsKey(truckId)) {
      _notifiedMilestones[truckId] = {};
    }

    final milestones = [400, 300, 200, 100];
    for (int milestone in milestones) {
      if (distance <= milestone && !_notifiedMilestones[truckId]!.contains(milestone)) {
        _notifiedMilestones[truckId]!.add(milestone);
        _triggerMilestoneAlert(milestone);
        break; // Only trigger one milestone per check
      }
    }

    // Reset milestones if truck moves far away again (e.g. > 600m)
    if (distance > 600) {
      _notifiedMilestones[truckId]?.clear();
    }
  }

  void _triggerMilestoneAlert(int distance) {
    String message = 'The truck is $distance meters away from your house.';
    if (distance == 100) message = 'Truck is almost here! ($distance meters away)';
    
    NotificationService().showLocalNotification(
      'Truck Approaching', 
      message,
      {'type': 'arrival', 'distance': distance.toString()}
    );
  }

  Future<void> stopMonitoring() async {
    await _bleScanSubscription?.cancel();
    await _firestoreSubscription?.cancel();
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    _bleScanSubscription = null;
    _firestoreSubscription = null;
    _isActive = false;
  }
}

