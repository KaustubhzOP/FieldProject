import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_colors.dart';
import '../../services/proximity_scanner_service.dart';
import '../../services/auth_service.dart';
import '../../utils/map_styles.dart';

class ResidentHomeScreen extends StatefulWidget {
  const ResidentHomeScreen({super.key});

  @override
  State<ResidentHomeScreen> createState() => _ResidentHomeScreenState();
}

class _ResidentHomeScreenState extends State<ResidentHomeScreen> {
  GoogleMapController? _mapController;
  StreamSubscription? _driversSubscription;
  final _proximityService = ProximityScannerService();
  final _authService = AuthService();

  final Map<String, Map<String, dynamic>> _liveDrivers = {};
  LatLng? _residentHouse;
  String _homeStatus = 'none';
  String _etaText = 'Calculating...';
  double _nearestDistance = double.infinity;
  String _nearestDriverName = '';
  String _wardDriverName = '';
  String _residentWard = '';
  bool _truckArriving = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startTracking();
    _initProximityMonitoring();
  }

  void _startTracking() {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    FirebaseFirestore.instance.collection('users').doc(user.id).snapshots().listen((doc) {
      if (!mounted || !doc.exists) return;
      final data = doc.data()!;
      setState(() {
        _homeStatus = data['homeStatus'] ?? 'none';
        _residentWard = data['ward'] ?? '';
        if (data['homeLat'] != null && data['homeLng'] != null) {
          _residentHouse = LatLng(data['homeLat'], data['homeLng']);
        } else if (data['pendingLat'] != null && data['pendingLng'] != null) {
          _residentHouse = LatLng(data['pendingLat'], data['pendingLng']);
        } else {
          _residentHouse = null;
        }
      });
    });

    _driversSubscription = FirebaseFirestore.instance.collection('drivers').where('isOnDuty', isEqualTo: true).snapshots().listen((snapshot) {
      if (!mounted) return;
      _liveDrivers.clear();
      double nearest = double.infinity;
      String nearestName = '';
      String foundWardDriver = '';

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (_residentWard.isNotEmpty && data['ward'] == _residentWard) {
          foundWardDriver = data['driverName'] ?? 'Assigned Driver';
        }
        _liveDrivers[doc.id] = data;
        final location = data['liveLocation'];
        if (location == null || _residentHouse == null) continue;
        final dist = Geolocator.distanceBetween(_residentHouse!.latitude, _residentHouse!.longitude, (location['lat'] as num).toDouble(), (location['lng'] as num).toDouble());
        if (dist < nearest) {
          nearest = dist;
          nearestName = data['driverName'] ?? 'Truck';
        }
      }

      setState(() {
        _nearestDistance = nearest;
        _nearestDriverName = nearestName;
        _wardDriverName = foundWardDriver;
        if (nearest == double.infinity) {
          _etaText = 'Offline';
          _truckArriving = false;
        } else {
          final etaMinutes = (nearest / 1000 / 20 * 60).round();
          _etaText = nearest < 100 ? 'Arriving Now!' : '$etaMinutes min away';
          _truckArriving = nearest < 200;
        }
      });
    });
  }

  Future<void> _registerHome() async {
    setState(() => _isLoading = true);
    try {
      final pos = await Geolocator.getCurrentPosition();
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        await _authService.requestHomeVerification(user.id, pos.latitude, pos.longitude);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _initProximityMonitoring() async {
    await _proximityService.initialize();
    if (_residentHouse != null) {
      await _proximityService.startMonitoring(
        residentLat: _residentHouse!.latitude, residentLng: _residentHouse!.longitude,
        residentId: context.read<AuthProvider>().currentUser?.id ?? '',
      );
    }
  }

  @override
  void dispose() {
    _driversSubscription?.cancel();
    _proximityService.stopMonitoring();
    super.dispose();
  }

  Set<Marker> _buildMarkers() {
    final Set<Marker> markers = {};
    if (_residentHouse != null) {
      markers.add(Marker(
        markerId: const MarkerId('home'),
        position: _residentHouse!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        infoWindow: const InfoWindow(title: 'My House'),
      ));
    }
    for (var entry in _liveDrivers.entries) {
      final data = entry.value;
      if (_residentWard.isNotEmpty && data['ward'] != _residentWard) continue;
      final location = data['liveLocation'];
      if (location == null) continue;
      markers.add(Marker(
        markerId: MarkerId(entry.key),
        position: LatLng(location['lat'], location['lng']),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        rotation: (location['heading'] as num?)?.toDouble() ?? 0,
      ));
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Fleet Map'),
        actions: [
          if (_homeStatus == 'approved')
            IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white), onPressed: () => _startTracking()),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _residentHouse ?? const LatLng(19.0760, 72.8777), zoom: 15),
            markers: _buildMarkers(),
            style: MapStyles.darkStyle,
            myLocationEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (c) => _mapController = c,
          ),

          // Glass Overlays
          if (_homeStatus != 'approved') _buildWelcomeOverlay(),
          if (_homeStatus == 'approved') _buildTrackingOverlay(),
          
          _buildZoomControls(),
        ],
      ),
    );
  }

  Widget _buildWelcomeOverlay() {
    bool isPending = _homeStatus == 'pending_approval' || _homeStatus == 'pending_removal';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.8), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withOpacity(0.1))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(isPending ? Icons.hourglass_top_rounded : Icons.home_work_rounded, size: 40, color: AppColors.accent),
                  ),
                  const SizedBox(height: 24),
                  Text(isPending ? 'Verification Active' : 'Setup Location', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  Text(
                    isPending ? 'Our admin is currently verifying your home location. Real-time fleet tracking will be enabled once approved.' : 'Ready to start tracking? Register your house location to see exactly where the garbage trucks are in your ward.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textBody, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  if (!isPending)
                    ElevatedButton(
                      onPressed: _isLoading ? null : _registerHome,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                      child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Register Home Now'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrackingOverlay() {
    return Positioned(
      bottom: 24, left: 16, right: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.85), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.white10)),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(gradient: _truckArriving ? const LinearGradient(colors: [Colors.red, Colors.orange]) : AppColors.accentGradient, borderRadius: BorderRadius.circular(15)),
                      child: Icon(_truckArriving ? Icons.notifications_active_rounded : Icons.local_shipping_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_wardDriverName.isNotEmpty ? 'Driver: $_wardDriverName' : 'Searching truck...', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 4),
                          Text('Ward Area: $_residentWard', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: _truckArriving ? Colors.red.withOpacity(0.2) : AppColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Text(_etaText, style: TextStyle(color: _truckArriving ? Colors.redAccent : AppColors.accent, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
                if (_truckArriving) ...[
                  const SizedBox(height: 20),
                  const LinearProgressIndicator(backgroundColor: Colors.white10, valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent)),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Positioned(
      right: 16, top: MediaQuery.of(context).size.height * 0.4,
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
    return InkWell(
      onTap: tap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.8), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
