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
import '../../models/user.dart';
import '../../utils/map_styles.dart';
import '../../utils/map_marker_util.dart';

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
  LatLng? _selectedPoint;
  bool _isLoading = false;
  BitmapDescriptor? _truckIcon;
  BitmapDescriptor? _homeIcon;

  @override
  void initState() {
    super.initState();
    _loadIcons();
    _startTracking();
    _initProximityMonitoring();
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
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
            throw 'Location permissions are denied';
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied.';
      }

      final pos = await Geolocator.getCurrentPosition();
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        await _authService.requestHomeVerification(user.id, pos.latitude, pos.longitude);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sent to Admin for Verification!'), backgroundColor: Colors.teal));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmManualLocation() async {
    if (_selectedPoint == null) return;
    setState(() => _isLoading = true);
    try {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        await _authService.requestHomeVerification(user.id, _selectedPoint!.latitude, _selectedPoint!.longitude);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location Submitted for Verification!'), backgroundColor: Colors.teal));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
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
        icon: _homeIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        infoWindow: const InfoWindow(title: 'My House'),
      ));
    }

    if (_homeStatus == 'none' && _selectedPoint != null) {
      markers.add(Marker(
        markerId: const MarkerId('selection'),
        position: _selectedPoint!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Selected Home Location'),
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
        icon: _truckIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
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
        title: const Text('FLEET MAP (SYNC TEST)'),
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
            onTap: _homeStatus == 'none' ? (p) {
              setState(() => _selectedPoint = p);
              context.read<AuthProvider>().setSessionSelection(p);
              _mapController?.animateCamera(CameraUpdate.newLatLng(p));
            } : (p) {
              context.read<AuthProvider>().setSessionSelection(p);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location Captured for Complaint'), duration: Duration(seconds: 1)));
            },
          ),

          // Zoom Controls (Moved above overlays for hit-test priority)
          _buildZoomControls(),

          // Glass Overlays
          if (_homeStatus != 'approved') _buildWelcomeOverlay(),
          if (_homeStatus == 'approved') _buildTrackingOverlay(),
        ],
      ),
    );
  }

  Widget _buildWelcomeOverlay() {
    bool isPending = _homeStatus == 'pending_approval' || _homeStatus == 'pending_removal';
    
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      top: isPending ? 0 : (_selectedPoint == null ? MediaQuery.of(context).size.height * 0.3 : MediaQuery.of(context).size.height * 0.7),
      left: 0, right: 0, bottom: 0,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.85), 
                  borderRadius: BorderRadius.circular(30), 
                  border: Border.all(color: Colors.white.withOpacity(0.1))
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(isPending ? Icons.hourglass_top_rounded : Icons.add_location_alt_rounded, size: 36, color: AppColors.accent),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isPending ? 'Verification Active' : (_selectedPoint == null ? 'Setup Location' : 'Confirm Location'), 
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isPending 
                        ? 'Our admin is currently verifying your home location. Real-time fleet tracking will be enabled once approved.' 
                        : (_selectedPoint == null 
                            ? 'Ready to start tracking? Tap anywhere on the map to pick your home location.' 
                            : 'Is this the correct location for your home? Trucks will be tracked relative to this point.'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textBody, height: 1.4, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    if (!isPending)
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _registerHome,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              icon: _isLoading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.my_location_rounded, size: 20),
                              label: const Text('ENABLE CURRENT LOCATION', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('Tapping above will share your precise GPS coordinates with the collection fleet.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                        ],
                      ),
                  ],
                ),
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
                  const Text('TRUCK IS APPROACHING', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: tap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.8), 
            borderRadius: BorderRadius.circular(12), 
            border: Border.all(color: Colors.white10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
