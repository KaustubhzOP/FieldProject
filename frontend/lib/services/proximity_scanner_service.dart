import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';

import 'fcm_service.dart';

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
  StreamSubscription? _firestoreSubscription;
  bool _notifiedThisSession = false;
  bool _isActive = false;
  String _residentId = '';

  static const double proximityRadius = 50.0; // meters

  /// Call this after the resident logs in.
  Future<void> startMonitoring({
    required double residentLat,
    required double residentLng,
    required String residentId,
  }) async {
    if (_isActive) return;
    _isActive = true;
    _residentId = residentId;
    _notifiedThisSession = false;

    _startBleScan();
    _startGpsFallback(residentLat, residentLng);
  }

  void _startBleScan() {
    try {
      FlutterBluePlus.startScan(
        withServices: [Guid(smartBinServiceUuid)],
        timeout: const Duration(minutes: 5),
      );

      _bleScanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          if (r.rssi > -80 && !_notifiedThisSession) {
            _triggerFcmArrivalAlert();
          }
        }
      });
    } catch (_) {
      // BLE unavailable — GPS fallback covers it
    }
  }

  void _startGpsFallback(double residentLat, double residentLng) {
    _firestoreSubscription = _firestore
        .collection('drivers')
        .where('isOnDuty', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final location = data['liveLocation'];
        if (location == null) continue;

        final double driverLat = (location['lat'] as num).toDouble();
        final double driverLng = (location['lng'] as num).toDouble();

        final double distance = Geolocator.distanceBetween(
          residentLat, residentLng,
          driverLat, driverLng,
        );

        if (distance <= proximityRadius && !_notifiedThisSession) {
          _triggerFcmArrivalAlert();
        }
      }
    });
  }

  /// Fires an FCM push to this resident's registered device token via FcmService.
  void _triggerFcmArrivalAlert() {
    _notifiedThisSession = true;
    FcmService().sendArrivalAlert(_residentId);

    // Reset after 30 minutes — allows notification on the next truck visit
    Future.delayed(const Duration(minutes: 30), () {
      _notifiedThisSession = false;
    });
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

