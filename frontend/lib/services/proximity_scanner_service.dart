import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';

// Smart truck BLE Service UUID - what residents scan for
const String smartBinServiceUuid = '0000FFE0-0000-1000-8000-00805F9B34FB';

/// Runs in the background on the RESIDENT's side.
/// Detects when a garbage truck is nearby via:
///   1. BLE scan — detects truck BLE beacon
///   2. GPS fallback — monitors truck Firestore location vs resident address
class ProximityScannerService {
  static final ProximityScannerService _instance = ProximityScannerService._internal();
  factory ProximityScannerService() => _instance;
  ProximityScannerService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _notifs = FlutterLocalNotificationsPlugin();

  StreamSubscription? _bleScanSubscription;
  StreamSubscription? _firestoreSubscription;
  bool _notifiedThisSession = false;
  bool _isActive = false;

  static const double proximityRadius = 500.0; // meters

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifs.initialize(initSettings);
  }

  /// Start monitoring — call this after resident logs in
  Future<void> startMonitoring({
    required double residentLat,
    required double residentLng,
    required String residentId,
  }) async {
    if (_isActive) return;
    _isActive = true;
    _notifiedThisSession = false;

    // Method 1: BLE scan for truck beacons
    _startBleScan(residentLat, residentLng);

    // Method 2: GPS fallback — listen to Firestore drivers collection
    _startGpsFallback(residentLat, residentLng);
  }

  void _startBleScan(double residentLat, double residentLng) {
    try {
      FlutterBluePlus.startScan(
        withServices: [Guid(smartBinServiceUuid)], // use same UUID trucks advertise
        timeout: const Duration(minutes: 5),
      );

      _bleScanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          // rssi > -80 means within ~50 meters
          if (r.rssi > -80 && !_notifiedThisSession) {
            _fireProximityNotification(source: 'bluetooth');
          }
        }
      });
    } catch (_) {
      // BLE not available, GPS fallback will handle it
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
          final driverName = data['driverName'] ?? 'The garbage truck';
          final distanceStr = distance < 100
              ? 'right outside!'
              : '${distance.toStringAsFixed(0)}m away';
          _fireProximityNotification(
            source: 'gps',
            driverName: driverName,
            distance: distanceStr,
          );
        }
      }
    });
  }

  Future<void> _fireProximityNotification({
    required String source,
    String? driverName,
    String? distance,
  }) async {
    _notifiedThisSession = true;

    final body = source == 'bluetooth'
        ? 'The garbage truck is very close to you! Please put your bin out now.'
        : '${driverName ?? "The truck"} is $distance. Put your bin out!';

    const androidDetails = AndroidNotificationDetails(
      'truck_proximity',
      'Truck Proximity Alert',
      channelDescription: 'Notifies when garbage truck is nearby',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    await _notifs.show(
      001,
      '🚛 Garbage Truck Nearby!',
      body,
      const NotificationDetails(android: androidDetails),
    );

    // Reset after 10 minutes so repeat alerts can fire for next round
    Future.delayed(const Duration(minutes: 10), () {
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
