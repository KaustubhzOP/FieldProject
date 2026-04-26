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

class _ResidentHomeScreenState extends State<ResidentHomeScreen> with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  StreamSubscription? _driversSubscription;
  final _proximityService = ProximityScannerService();
  final _authService = AuthService();

  final Map<String, Map<String, dynamic>> _liveDrivers = {};
  final Map<String, LatLng> _oldTruckPositions = {};
  late AnimationController _markerAnimator;

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
    _markerAnimator = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _markerAnimator.addListener(() => setState(() {}));
    _loadIcons();
    _startTracking();
    _initProximityMonitoring();
  }

  Future<void> _loadIcons() async {
    final truck = await MapMarkerUtil.createCustomMarker(
      icon: Icons.local_shipping_rounded,
      color: AppColors.primary,
      size: 100,
    );
    final home = await MapMarkerUtil.createCustomMarker(
      icon: Icons.home_rounded,
      color: AppColors.error,
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
          final newPos = LatLng((data['homeLat'] as num).toDouble(), (data['homeLng'] as num).toDouble());
          if (_residentHouse == null || (_residentHouse!.latitude - newPos.latitude).abs() > 0.00001) {
             _residentHouse = newPos;
             _initProximityMonitoring(); // Refresh Radar (only on major change)
             
             // Auto-zoom to home on first approval
             Future.delayed(const Duration(milliseconds: 500), () {
               _mapController?.animateCamera(CameraUpdate.newLatLngZoom(newPos, 16));
             });
          }
        } else {
          _residentHouse = null;
        }
      });
    });

    _driversSubscription = FirebaseFirestore.instance.collection('drivers').where('isOnDuty', isEqualTo: true).snapshots().listen((snapshot) {
      if (!mounted) return;
      
      for (var key in _liveDrivers.keys) {
        final loc = _liveDrivers[key]?['liveLocation'];
        if (loc != null) _oldTruckPositions[key] = LatLng((loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble());
      }
      
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
        
        if (!_oldTruckPositions.containsKey(doc.id)) {
          final loc = data['liveLocation'];
          if (loc != null) _oldTruckPositions[doc.id] = LatLng((loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble());
        }
        
        final location = data['liveLocation'];
        if (location == null || _residentHouse == null) continue;
        
        try {
          final dist = Geolocator.distanceBetween(
            _residentHouse!.latitude, 
            _residentHouse!.longitude, 
            (location['lat'] as num).toDouble(), 
            (location['lng'] as num).toDouble()
          );
          if (dist < nearest) {
            nearest = dist;
            nearestName = data['driverName'] ?? 'Truck';
          }
        } catch (e) {
          debugPrint('Distance calculation error: $e');
        }
      }

      _oldTruckPositions.removeWhere((key, _) => !_liveDrivers.containsKey(key));
      _markerAnimator.forward(from: 0.0);

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

  Future<void> _promptResetLocation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Update Home Location?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('This will clear your current approved location and let you pick a new one on the map.', style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('RESET & UPDATE'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        await _authService.resetHomeStatus(user.id);
        setState(() {
          _homeStatus = 'none';
          _residentHouse = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location Unlocked! Please pick your new spot.')));
      }
    }
  }

  Future<void> _summonTruckForTest() async {
    if (_residentHouse == null) return;
    
    // Teleport driver_1 to EXACTLY ~420 meters away
    // We only shift latitude for precise distance calculation
    final testCoords = {
      'lat': _residentHouse!.latitude + 0.00378, // ~420m
      'lng': _residentHouse!.longitude
    };
    
    await FirebaseFirestore.instance.collection('drivers').doc('driver_1').update({
      'liveLocation': {
        'lat': testCoords['lat'],
        'lng': testCoords['lng'],
        'heading': 225.0
      },
      'targetLat': _residentHouse!.latitude,
      'targetLng': _residentHouse!.longitude,
      'ward': _residentWard,
      'isOnDuty': true
    });
    
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Truck Alpha Summoned 70m away!'),
      backgroundColor: Colors.blueAccent,
    ));
  }

  Future<void> _initProximityMonitoring() async {
    if (_residentHouse != null) {
      try {
        await _proximityService.startMonitoring(
          residentLat: _residentHouse!.latitude, 
          residentLng: _residentHouse!.longitude,
          residentId: context.read<AuthProvider>().currentUser?.id ?? '',
        );
      } catch (e) {
        debugPrint('Proximity monitoring start failed: $e');
      }
    }
  }

  @override
  void dispose() {
    _markerAnimator.dispose();
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
      
      LatLng target = LatLng((location['lat'] as num).toDouble(), (location['lng'] as num).toDouble());
      LatLng old = _oldTruckPositions[entry.key] ?? target;
      double t = _markerAnimator.value;
      LatLng animatedPos = LatLng(
        old.latitude + (target.latitude - old.latitude) * t,
        old.longitude + (target.longitude - old.longitude) * t,
      );

      markers.add(Marker(
        markerId: MarkerId(entry.key),
        position: animatedPos,
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
        title: const Text('Smart Waste Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.airport_shuttle_rounded, color: Colors.yellowAccent, size: 22), 
            onPressed: () => _summonTruckForTest(), 
            tooltip: 'Summon Truck (Test 50m Radius)'
          ),
          IconButton(
            icon: const Icon(Icons.edit_location_alt_rounded, color: AppColors.card, size: 22), 
            onPressed: () => _promptResetLocation(), 
            tooltip: 'Update Home Location'
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.card, size: 22), 
            onPressed: () => _startTracking()
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _residentHouse ?? const LatLng(19.0760, 72.8777), zoom: 15),
            markers: _buildMarkers(),
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
          // Main Location Setup Overlay
          if (_homeStatus.trim().toLowerCase() != 'approved') 
            _buildWelcomeOverlay(),

          // Tracking Overlay for Approved Residents
          if (_homeStatus.trim().toLowerCase() == 'approved') 
            _buildTrackingOverlay(),
        ],
      ),
    );
  }

  Widget _buildWelcomeOverlay() {
    final String status = _homeStatus.trim().toLowerCase();
    final bool isPending = status == 'pending_approval' || status == 'pending_removal';
    
    // Hard Exit: If approved, return an empty space
    if (status == 'approved') return const SizedBox.shrink();

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.card.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPending ? Icons.hourglass_top_rounded : Icons.location_on_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isPending ? 'Verification in Progress' : 'Start Your Journey',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textHeader,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isPending
                        ? 'We are verifying your address. Real-time truck tracking will activate shortly.'
                        : 'To get distance alerts, please pin your house location on the map.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textBody,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (!isPending)
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _registerHome,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Auto-Pin My Location', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'OR Long-Press anywhere on map',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoHouseBanner() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.home_outlined, size: 40, color: AppColors.primary),
            const SizedBox(height: 12),
            const Text(
              'House Location Not Set',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Long-press on the map to mark exactly where your house is located.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Focus on current location to help them pin
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Got it', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingOverlay() {
    double minDistance = double.infinity;
    String truckLabel = 'Scanning for trucks...';
    bool hasTruck = false;

    if (_liveDrivers.isNotEmpty && _residentHouse != null) {
      for (var entry in _liveDrivers.entries) {
        if (entry.value['ward'] != _residentWard) continue;
        final loc = entry.value['liveLocation'];
        if (loc == null) continue;
        
        double d = Geolocator.distanceBetween(
          _residentHouse!.latitude, _residentHouse!.longitude,
          (loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble(),
        );

        if (d < minDistance) {
          minDistance = d;
          truckLabel = entry.value['truckLabel'] ?? entry.value['name'];
          hasTruck = true;
        }
      }
    }

    final bool isVeryClose = minDistance <= 400.0;
    final String distanceText = hasTruck ? '${minDistance.toStringAsFixed(0)}m away' : 'No trucks in ward';

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
          border: Border.all(color: isVeryClose ? AppColors.error.withOpacity(0.3) : Colors.transparent, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isVeryClose ? AppColors.error.withOpacity(0.1) : AppColors.primary.withOpacity(0.1), 
                    shape: BoxShape.circle
                  ),
                  child: Icon(
                    isVeryClose ? Icons.notifications_active_rounded : Icons.local_shipping_rounded, 
                    color: isVeryClose ? AppColors.error : AppColors.primary
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(truckLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textHeader)),
                      Text(distanceText, style: TextStyle(color: isVeryClose ? AppColors.error : AppColors.teal, fontWeight: FontWeight.w900, fontSize: 18)),
                    ],
                  ),
                ),
                if (hasTruck)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(100)),
                    child: const Text('LIVE', style: TextStyle(color: AppColors.teal, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
              ],
            ),
            if (isVeryClose) ...[
              const SizedBox(height: 16),
              const Text('TRUCK IN RANGE (400M)', style: TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              const LinearProgressIndicator(backgroundColor: AppColors.background, valueColor: AlwaysStoppedAnimation<Color>(AppColors.error)),
            ]
          ],
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
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface, 
            borderRadius: BorderRadius.circular(8), 
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
      ),
    );
  }
}
