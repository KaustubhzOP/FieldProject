import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/constants.dart';

class FleetSimulationService {
  static final FleetSimulationService _instance = FleetSimulationService._internal();
  factory FleetSimulationService() => _instance;
  FleetSimulationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _movementTimer;
  Timer? _historyTimer;
  StreamSubscription? _approvalSubscription;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // 1. Initial Seed (ensure trucks exist)
    await _seedInitialDrivers();

    // 2. Start Approval Watcher (simulates back-office processing)
    _startApprovalWatcher();

    // 3. Start Movement Simulation (updates GPS coordinates periodically)
    _startMovementSimulation();

    // 4. Start Notification Logic (simulation only)
    _startNotificationWatcher();

    // 5. Start History Generation (simulates past collections)
    _startHistoryGeneration();
    
    print('🚀 FleetSimulationService Initialized');
  }

  Future<void> _seedInitialDrivers() async {
    final List<Map<String, dynamic>> officialDrivers = [
      {'id': 'driver_1', 'name': 'Driver 1 (Alpha)', 'truckLabel': 'Truck Alpha', 'isOnDuty': true, 'ward': 'Ward 1', 'liveLocation': {'lat': 19.0596, 'lng': 72.8295, 'heading': 0.0}},
      {'id': 'driver_2', 'name': 'Driver 2 (Beta)', 'truckLabel': 'Truck Beta', 'isOnDuty': true, 'ward': 'Ward 2', 'liveLocation': {'lat': 19.0400, 'lng': 72.8500, 'heading': 45.0}},
      {'id': 'driver_3', 'name': 'Driver 3 (Gamma)', 'truckLabel': 'Truck Gamma', 'isOnDuty': true, 'ward': 'Ward 3', 'liveLocation': {'lat': 19.0760, 'lng': 72.8777, 'heading': 180.0}},
      {'id': 'driver_4', 'name': 'Driver 4 (Delta)', 'truckLabel': 'Truck Delta', 'isOnDuty': true, 'ward': 'Ward 4', 'liveLocation': {'lat': 19.0800, 'lng': 72.8800, 'heading': 90.0}},
      {'id': 'driver_5', 'name': 'Driver 5 (Epsilon)', 'truckLabel': 'Truck Epsilon', 'isOnDuty': true, 'ward': 'Ward 5', 'liveLocation': {'lat': 19.0700, 'lng': 72.8700, 'heading': 270.0}},
    ];

    try {
      final batch = _firestore.batch();
      for (var truck in officialDrivers) {
        batch.set(_firestore.collection('drivers').doc(truck['id']), truck, SetOptions(merge: true));
      }
      await batch.commit();
    } catch (e) {
      print('⚠️ Simulation seed failed (Quota likely hit): $e');
    }
  }

  void _startApprovalWatcher() {
    _approvalSubscription = _firestore
        .collection('users')
        .where('homeStatus', isEqualTo: 'pending_approval')
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data();
        /* 
        // DISABLED AUTO-APPROVAL: Let the admin use the Verification Queue manually!
        Future.delayed(const Duration(seconds: 3), () async {
          if (doc.exists) {
            await _firestore.collection('users').doc(doc.id).update({
              'homeLat': data['pendingLat'],
              'homeLng': data['pendingLng'],
              'homeStatus': 'approved',
              'pendingLat': FieldValue.delete(),
              'pendingLng': FieldValue.delete(),
            });
            print('✅ Auto-Approved Resident: ${doc.id}');
          }
        });
        */
        print('⏳ Resident ${doc.id} is waiting in the Verification Queue...');
      }
    });
  }

  void _startMovementSimulation() {
    double angle = 0;
    _movementTimer = Timer.periodic(const Duration(seconds: 8), (timer) async {
      angle += 0.1;
      final batch = _firestore.batch();
      
      final trucks = ['driver_1', 'driver_2', 'driver_3', 'driver_4', 'driver_5'];
      for (int i = 0; i < trucks.length; i++) {
        final truckDoc = await _firestore.collection('drivers').doc(trucks[i]).get();
        final truckData = truckDoc.data();
        
        // If truck is summoned (pinned), move towards the pin instead of circular path
        double lat, lng, heading;
        final targetLat = truckData?['targetLat'] as double?;
        final targetLng = truckData?['targetLng'] as double?;
        
        if (targetLat != null && targetLng != null) {
          final currentLoc = truckData!['liveLocation'];
          double curLat = (currentLoc['lat'] as num).toDouble();
          double curLng = (currentLoc['lng'] as num).toDouble();
          
          // Move 20% towards target (Faster approach for testing)
          lat = curLat + (targetLat - curLat) * 0.2;
          lng = curLng + (targetLng - curLng) * 0.2;
          heading = 225.0; // Inbound
          
          print('DEBUG: Truck Alpha is approaching... Current Dist: ${Geolocator.distanceBetween(curLat, curLng, targetLat, targetLng).toStringAsFixed(1)}m');
        } else {
          // Normal circular path
          final double radius = 0.005 + (i * 0.002);
          lat = AppConstants.defaultLatitude + (radius * sin(angle + i));
          lng = AppConstants.defaultLongitude + (radius * cos(angle + i));
          heading = (angle * 180 / pi) % 360;
        }

        batch.update(_firestore.collection('drivers').doc(trucks[i]), {
          'liveLocation': {
            'lat': lat,
            'lng': lng,
            'heading': heading,
            'speed': 20.0,
          }
        });
      }
      await batch.commit();
    });
  }

  void _startNotificationWatcher() {
    _firestore.collection('complaints').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final data = change.doc.data();
          final status = data?['status'];
          // Real email/push logic is now handled in ComplaintProvider.dart
          print('📝 Status Update Detected: #${change.doc.id} is now $status');
        }
      }
    });
  }

  void _startHistoryGeneration() {
    // Generate a new history record every 15 seconds to populate the dashboard fast
    _historyTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      final truckIndex = Random().nextInt(5) + 1;
      final truckId = 'driver_$truckIndex';
      final docId = 'HIST-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      
      final record = {
        'id': docId,
        'driverId': truckId,
        'routeId': 'route_sim_${Random().nextInt(100)}',
        'startTime': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
        'endTime': DateTime.now().toIso8601String(),
        'status': Random().nextDouble() > 0.15 ? 'collected' : 'missed',
        'pointsCollected': 8 + Random().nextInt(5),
        'totalPoints': 12,
        'ward': 'Ward $truckIndex', // Matches our 5-ward setup
      };

      await _firestore.collection(AppConstants.collectionsCollection).doc(docId).set(record);
      print('📝 [SIM] Generated History Record for $truckId');
    });
  }

  void dispose() {
    _movementTimer?.cancel();
    _historyTimer?.cancel();
    _approvalSubscription?.cancel();
    _isInitialized = false;
  }
}
