import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/auth_provider.dart';
import '../../utils/map_styles.dart';
import '../../config/app_colors.dart';

class DriverRouteScreen extends StatefulWidget {
  const DriverRouteScreen({super.key});

  @override
  State<DriverRouteScreen> createState() => _DriverRouteScreenState();
}

class _DriverRouteScreenState extends State<DriverRouteScreen> {
  GoogleMapController? _mapController;
  Position? _currentPos;
  BitmapDescriptor? _truckIcon;
  final Set<String> _collectedIds = {};
  
  @override
  void initState() {
    super.initState();
    _loadIcons();
    _initLocation();
    _startTracking();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadIcons() async {
    final icon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/icons/truck_nav.png',
    );
    if (mounted) setState(() => _truckIcon = icon);
  }

  void _startTracking() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
    ).listen((pos) {
      if (mounted) {
        setState(() => _currentPos = pos);
        _checkProximity(pos);
        _mapController?.animateCamera(CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)));
      }
    });
  }

  void _checkProximity(Position pos) {
    // This logic will be triggered in the build path handlers
  }

  Future<void> _initLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) setState(() => _currentPos = pos);
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return const Scaffold(backgroundColor: Colors.white, body: Center(child: Text('Unauthorized Access')));

    // --- INSTANT DEMO MODE (Offline Failsafe) ---
    // Detect demo drivers by email and bypass the Firestore stall
    String demoWard = '';
    if (user.email == 'driver1@gmail.com') demoWard = 'Ward 1';
    if (user.email == 'driver2@gmail.com') demoWard = 'Ward 2';
    if (user.email == 'driver3@gmail.com') demoWard = 'Ward 3';
    if (user.email == 'driver4@gmail.com') demoWard = 'Ward 1'; 
    if (user.email == 'driver5@gmail.com') demoWard = 'Ward 2';

    if (demoWard.isNotEmpty) {
      final List<Map<String, dynamic>> localFallbackResidents = {
        'Ward 1': [
          {'id': 'static_1_1', 'name': '12 Hill Road', 'homeLat': 19.0596, 'homeLng': 72.8295, 'address': 'Bandra West, Mumbai'},
          {'id': 'road_1_1_2a', 'name': '', 'homeLat': 19.0595, 'homeLng': 72.8315, 'isWayPoint': true},
          {'id': 'road_1_1_2b', 'name': '', 'homeLat': 19.0605, 'homeLng': 72.8318, 'isWayPoint': true},
          {'id': 'static_1_2', 'name': 'Turner Heights', 'homeLat': 19.0620, 'homeLng': 72.8350, 'address': 'Turner Road, Bandra'},
          {'id': 'road_1_2_3a', 'name': '', 'homeLat': 19.0625, 'homeLng': 72.8360, 'isWayPoint': true},
          {'id': 'road_1_2_3b', 'name': '', 'homeLat': 19.0645, 'homeLng': 72.8340, 'isWayPoint': true},
          {'id': 'static_1_3', 'name': 'Sea View Apts', 'homeLat': 19.0650, 'homeLng': 72.8300, 'address': 'Perry Cross Road'},
          {'id': 'road_1_3_4a', 'name': '', 'homeLat': 19.0610, 'homeLng': 72.8260, 'isWayPoint': true},
          {'id': 'road_1_3_4b', 'name': '', 'homeLat': 19.0585, 'homeLng': 72.8255, 'isWayPoint': true},
          {'id': 'static_1_4', 'name': 'Garden View', 'homeLat': 19.0570, 'homeLng': 72.8250, 'address': 'St. Andrews Road'},
        ],
        'Ward 2': [
          {'id': 'static_2_1', 'name': 'Dharavi Point 1', 'homeLat': 19.0400, 'homeLng': 72.8500, 'address': '90 Feet Road'},
          {'id': 'road_2_1_2a', 'name': '', 'homeLat': 19.0420, 'homeLng': 72.8520, 'isWayPoint': true},
          {'id': 'road_2_1_2b', 'name': '', 'homeLat': 19.0440, 'homeLng': 72.8540, 'isWayPoint': true},
          {'id': 'static_2_2', 'name': 'Sion Circle Res', 'homeLat': 19.0450, 'homeLng': 72.8550, 'address': 'Sion East'},
          {'id': 'road_2_2_3', 'name': '', 'homeLat': 19.0470, 'homeLng': 72.8530, 'isWayPoint': true},
          {'id': 'static_2_3', 'name': 'Link Road Apts', 'homeLat': 19.0480, 'homeLng': 72.8520, 'address': 'Bandra Link Rd'},
          {'id': 'road_2_3_4', 'name': '', 'homeLat': 19.0370, 'homeLng': 72.8460, 'isWayPoint': true},
          {'id': 'static_2_4', 'name': 'Sector 7 Res', 'homeLat': 19.0350, 'homeLng': 72.8450, 'address': 'Dharavi Sector 7'},
        ],
        'Ward 3': [
          {'id': 'static_3_1', 'name': 'BKC One Stop', 'homeLat': 19.0760, 'homeLng': 72.8777, 'address': 'BKC G Block'},
          {'id': 'road_3_1_2', 'name': '', 'homeLat': 19.0780, 'homeLng': 72.8820, 'isWayPoint': true},
          {'id': 'static_3_2', 'name': 'Kurla West Res', 'homeLat': 19.0800, 'homeLng': 72.8850, 'address': 'LBS Marg'},
          {'id': 'road_3_2_3a', 'name': '', 'homeLat': 19.0830, 'homeLng': 72.8840, 'isWayPoint': true},
          {'id': 'road_3_2_3b', 'name': '', 'homeLat': 19.0845, 'homeLng': 72.8830, 'isWayPoint': true},
          {'id': 'static_3_3', 'name': 'Ind Estate Res', 'homeLat': 19.0850, 'homeLng': 72.8820, 'address': 'Kurla Industrial Estate'},
          {'id': 'road_3_3_4', 'name': '', 'homeLat': 19.0740, 'homeLng': 72.8730, 'isWayPoint': true},
          {'id': 'static_3_4', 'name': 'BKC North Res', 'homeLat': 19.0720, 'homeLng': 72.8700, 'address': 'BKC North'},
        ],
      }[demoWard] ?? [];

      return Scaffold(
        backgroundColor: Colors.white,
        body: _buildRouteMapFromData(demoWard, localFallbackResidents),
      );
    }
    // --- END DEMO MODE ---

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('drivers').doc(user.id).snapshots(),
        builder: (context, driverSnapshot) {
          if (!driverSnapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final driverData = driverSnapshot.data!.data() as Map<String, dynamic>?;
          final String assignedWard = driverData?['ward'] ?? '';
          
          if (assignedWard.isEmpty) return _buildEmptyState('No Ward Assigned', 'Contact Admin');

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('homeStatus', isEqualTo: 'approved')
                .where('ward', isEqualTo: assignedWard)
                .snapshots(),
            builder: (context, housesSnapshot) {
              final houseDocs = housesSnapshot.data?.docs ?? [];
              if (houseDocs.isEmpty) return _buildEmptyState('Completed', 'All pickups synced');
              return _buildRouteMap(assignedWard, houseDocs);
            },
          );
        },
      ),
    );
  }

  Widget _buildRouteMap(String ward, List<QueryDocumentSnapshot> houses) {
    final Set<Marker> markers = {};
    final List<LatLng> polylinePoints = [];
    
    for (var i = 0; i < houses.length; i++) {
      final data = houses[i].data() as Map<String, dynamic>;
      final LatLng pos = LatLng(data['homeLat'], data['homeLng']);
      
      // Automatic Proximity Mark
      if (_currentPos != null) {
        final dist = Geolocator.distanceBetween(_currentPos!.latitude, _currentPos!.longitude, pos.latitude, pos.longitude);
        if (dist < 30) _collectedIds.add(houses[i].id); 
      }

      if (!_collectedIds.contains(houses[i].id)) {
        polylinePoints.add(pos);
        markers.add(Marker(
          markerId: MarkerId(houses[i].id),
          position: pos,
          infoWindow: InfoWindow(title: data['name'] ?? 'Pickup'),
        ));
      }
    }

    if (_currentPos != null) {
      markers.add(Marker(
        markerId: const MarkerId('driver_truck'),
        position: LatLng(_currentPos!.latitude, _currentPos!.longitude),
        icon: _truckIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        anchor: const Offset(0.5, 0.5),
        flat: true,
        rotation: _currentPos!.heading,
      ));
    }

    final pendingHouses = houses.where((h) => !_collectedIds.contains(h.id)).toList();
    final String nextTarget = pendingHouses.isNotEmpty ? (pendingHouses.first.data() as Map<String, dynamic>)['name'] : 'Route Completed';

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _currentPos != null ? LatLng(_currentPos!.latitude, _currentPos!.longitude) : const LatLng(19.076, 72.877), zoom: 17),
          markers: markers,
          polylines: {
            Polyline(polylineId: const PolylineId('path'), points: polylinePoints, color: const Color(0xFF2979FF), width: 6),
          },
          myLocationEnabled: false, // Using our truck instead
          onMapCreated: (c) => _mapController = c,
        ),
        Positioned(top: 50, left: 16, right: 16, child: _buildUberHeader(ward, pendingHouses.length, nextTarget)),
        _buildPickupSheet(pendingHouses),
      ],
    );
  }

  Widget _buildRouteMapFromData(String ward, List<Map<String, dynamic>> houses) {
    final Set<Marker> markers = {};
    final List<LatLng> polylinePoints = [];
    
    for (var i = 0; i < houses.length; i++) {
      final data = houses[i];
      final LatLng pos = LatLng(data['homeLat'], data['homeLng']);
      
      if (data['isWayPoint'] == true) {
        polylinePoints.add(pos);
        continue;
      }

      // Automatic Proximity Mark (Bluetooth simulation)
      if (_currentPos != null) {
        final dist = Geolocator.distanceBetween(_currentPos!.latitude, _currentPos!.longitude, pos.latitude, pos.longitude);
        if (dist < 30) _collectedIds.add(data['id']); 
      }

      if (!_collectedIds.contains(data['id'])) {
        polylinePoints.add(pos);
        markers.add(Marker(
          markerId: MarkerId(data['id']),
          position: pos,
          infoWindow: InfoWindow(title: data['name']),
        ));
      }
    }

    if (_currentPos != null) {
      markers.add(Marker(
        markerId: const MarkerId('driver_truck'),
        position: LatLng(_currentPos!.latitude, _currentPos!.longitude),
        icon: _truckIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        anchor: const Offset(0.5, 0.5),
        flat: true,
        rotation: _currentPos!.heading,
      ));
    }

    final pendingHouses = houses.where((h) => h['isWayPoint'] != true && !_collectedIds.contains(h['id'])).toList();
    final String nextTarget = pendingHouses.isNotEmpty ? pendingHouses.first['name'] : 'Route Completed';

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _currentPos != null ? LatLng(_currentPos!.latitude, _currentPos!.longitude) : const LatLng(19.076, 72.877), zoom: 17),
          markers: markers,
          polylines: {
            Polyline(polylineId: const PolylineId('path'), points: polylinePoints, color: const Color(0xFF2979FF), width: 6),
          },
          myLocationEnabled: false, 
          onMapCreated: (c) => _mapController = c,
        ),
        Positioned(top: 50, left: 16, right: 16, child: _buildUberHeader(ward, pendingHouses.length, nextTarget)),
        _buildPickupSheetFromData(pendingHouses),
      ],
    );
  }

  Widget _buildUberHeader(String ward, int count, String nextTarget) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF2979FF), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(nextTarget.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1A237E))),
                Text('$count TOTAL PICKUPS REMAINING', style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              ],
            ),
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('4 min', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2E7D32))),
                Text('0.8 km', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
          ),
        ],
      ),
    );
  }

  Widget _buildPickupSheet(List<QueryDocumentSnapshot> houses) {
    return DraggableScrollableSheet(
      initialChildSize: 0.2,
      minChildSize: 0.15,
      maxChildSize: 0.6,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
          ),
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: houses.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) return _buildSheetHandle();
              final data = houses[index - 1].data() as Map<String, dynamic>;
              return _buildPickupItem(index, data);
            },
          ),
        );
      },
    );
  }

  Widget _buildPickupSheetFromData(List<Map<String, dynamic>> houses) {
    return DraggableScrollableSheet(
      initialChildSize: 0.2,
        minChildSize: 0.15,
      maxChildSize: 0.6,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
          ),
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: houses.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) return _buildSheetHandle();
              final data = houses[index - 1];
              return _buildPickupItem(index, data);
            },
          ),
        );
      },
    );
  }

  Widget _buildSheetHandle() {
    return Center(child: Container(margin: const EdgeInsets.only(bottom: 20, top: 10), width: 30, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))));
  }

  Widget _buildPickupItem(int index, Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _mapController?.animateCamera(CameraUpdate.newLatLng(LatLng(data['homeLat'], data['homeLng']))),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFFE3F2FD), shape: BoxShape.circle), child: const Icon(Icons.home_work_rounded, color: Color(0xFF2979FF), size: 20)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['name'] ?? 'Resident', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                    Text(data['address'] ?? 'Tap to view location', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String sub) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.check_circle_rounded, size: 60, color: Color(0xFF2E7D32)), const SizedBox(height: 16), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), Text(sub, style: const TextStyle(color: Colors.grey))]));
  }
}
