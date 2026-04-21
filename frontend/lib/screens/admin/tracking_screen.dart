import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/location_broadcast_service.dart';
import '../../config/app_colors.dart';
import '../../utils/map_styles.dart';
import '../../utils/map_marker_util.dart';

class AdminTrackingScreen extends StatefulWidget {
  const AdminTrackingScreen({super.key});

  @override
  State<AdminTrackingScreen> createState() => _AdminTrackingScreenState();
}

class _AdminTrackingScreenState extends State<AdminTrackingScreen> {
  GoogleMapController? _mapController;
  StreamSubscription? _driversSubscription;
  final _broadcastService = LocationBroadcastService();

  final Map<String, Map<String, dynamic>> _liveDrivers = {};
  final Map<String, Map<String, dynamic>> _liveHouses = {};
  final Map<String, Map<String, dynamic>> _pendingResidents = {};

  bool _showTrucks = true;
  bool _showHouses = true;
  BitmapDescriptor? _truckIcon;
  BitmapDescriptor? _homeIcon;

  @override
  void initState() {
    super.initState();
    _loadIcons();
    _startLiveTracking();
  }

  Future<void> _loadIcons() async {
    final truck = await MapMarkerUtil.createCustomMarker(
      icon: Icons.local_shipping_rounded,
      color: AppColors.accent,
      size: 100,
    );
    final home = await MapMarkerUtil.createCustomMarker(
      icon: Icons.home_rounded,
      color: Colors.redAccent,
      size: 100,
    );
    if (mounted) {
      setState(() {
        _truckIcon = truck;
        _homeIcon = home;
      });
    }
  }

  void _startLiveTracking() {
    _driversSubscription = _broadcastService.getActiveDriversStream().listen((snapshot) {
      if (!mounted) return;
      setState(() {
        _liveDrivers.clear();
        for (var doc in snapshot.docs) {
          _liveDrivers[doc.id] = doc.data() as Map<String, dynamic>;
        }
      });
    });

    FirebaseFirestore.instance.collection('users').where('homeStatus', isEqualTo: 'approved').snapshots().listen((snapshot) {
      if (!mounted) return;
      setState(() {
        _liveHouses.clear();
        for (var doc in snapshot.docs) {
          _liveHouses[doc.id] = doc.data();
        }
      });
    });

    FirebaseFirestore.instance.collection('users').where('homeStatus', isEqualTo: 'pending_approval').snapshots().listen((snapshot) {
      if (!mounted) return;
      setState(() {
        _pendingResidents.clear();
        for (var doc in snapshot.docs) {
          _pendingResidents[doc.id] = doc.data();
        }
      });
    });
  }

  @override
  void dispose() {
    _driversSubscription?.cancel();
    super.dispose();
  }

  Set<Marker> _buildMarkers() {
    final Set<Marker> markers = {};

    if (_showHouses) {
      for (var entry in _liveHouses.entries) {
        final data = entry.value;
        if (data['homeLat'] == null) continue;
        markers.add(Marker(
          markerId: MarkerId('house_${entry.key}'),
          position: LatLng(data['homeLat'], data['homeLng']),
          icon: _homeIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
          infoWindow: InfoWindow(title: data['name'] ?? 'Resident'),
        ));
      }
      
      // Add Pending Residents as Pulsing Yellow/Orange Markers
      for (var entry in _pendingResidents.entries) {
        final data = entry.value;
        if (data['pendingLat'] == null) continue;
        markers.add(Marker(
          markerId: MarkerId('pending_${entry.key}'),
          position: LatLng(data['pendingLat'], data['pendingLng']),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: 'VERIFICATION PENDING',
            snippet: data['name'] ?? 'Guest Resident',
          ),
        ));
      }
    }

    if (_showTrucks) {
      for (var entry in _liveDrivers.entries) {
        final data = entry.value;
        final location = data['liveLocation'];
        if (location == null) continue;
        markers.add(Marker(
          markerId: MarkerId(entry.key),
          position: LatLng((location['lat'] as num).toDouble(), (location['lng'] as num).toDouble()),
          rotation: (location['heading'] as num?)?.toDouble() ?? 0,
          icon: _truckIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
            title: data['name'] ?? data['driverName'] ?? 'Truck',
            snippet: data['truckLabel'] ?? 'Fleet Vehicle',
          ),
        ));
      }
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Fleet Intelligence'),
        actions: [
          _buildToggle(Icons.local_shipping_rounded, _showTrucks, () => setState(() => _showTrucks = !_showTrucks)),
          _buildToggle(Icons.home_rounded, _showHouses, () => setState(() => _showHouses = !_showHouses)),
          const SizedBox(width: 12),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(target: LatLng(19.0760, 72.8777), zoom: 12),
            markers: _buildMarkers(),
            style: MapStyles.darkStyle,
            zoomControlsEnabled: false,
            onMapCreated: (c) => _mapController = c,
          ),
          
          if (_liveDrivers.isNotEmpty) _buildFleetScanner(),
          
          _buildZoomControls(),
        ],
      ),
    );
  }

  Widget _buildToggle(IconData icon, bool active, VoidCallback tap) {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: active ? AppColors.accent.withOpacity(0.2) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: active ? AppColors.accent : AppColors.textMuted, size: 20),
      ),
      onPressed: tap,
    );
  }

  Widget _buildFleetScanner() {
    return Positioned(
      top: 100, left: 16, right: 16,
      child: SizedBox(
        height: 90,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _liveDrivers.length,
          itemBuilder: (context, index) {
            final entry = _liveDrivers.entries.elementAt(index);
            final data = entry.value;
            final location = data['liveLocation'];
            final name = data['name'] ?? data['driverName'] ?? 'Driver ${index + 1}';
            final truck = data['truckLabel'] ?? 'Truck';
            
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: InkWell(
                    onTap: () {
                      if (location != null) {
                        _mapController?.animateCamera(CameraUpdate.newLatLng(LatLng(location['lat'], location['lng'])));
                      }
                    },
                    child: Container(
                      width: 160,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.8), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                              Text(truck, style: TextStyle(color: AppColors.textMuted.withOpacity(0.7), fontSize: 10)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.speed_rounded, color: AppColors.accent, size: 12),
                                  const SizedBox(width: 4),
                                  Text('${(location?['speed'] ?? 0).toStringAsFixed(0)} km/h', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Icon(Icons.radar_rounded, color: AppColors.accent, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Positioned(
      right: 16, bottom: 40,
      child: Column(
        children: [
          _buildMapBtn(Icons.add, () => _mapController?.animateCamera(CameraUpdate.zoomIn())),
          const SizedBox(height: 8),
          _buildMapBtn(Icons.remove, () => _mapController?.animateCamera(CameraUpdate.zoomOut())),
        ],
      ),
    );
  }

  Widget _buildMapBtn(IconData icon, VoidCallback tap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: tap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.8), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
