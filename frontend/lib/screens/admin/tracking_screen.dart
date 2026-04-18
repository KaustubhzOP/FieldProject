import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../utils/map_helper.dart';

class AdminTrackingScreen extends StatefulWidget {
  const AdminTrackingScreen({super.key});

  @override
  State<AdminTrackingScreen> createState() => _AdminTrackingScreenState();
}

class _AdminTrackingScreenState extends State<AdminTrackingScreen> {
  GoogleMapController? _mapController;
  Timer? _timer;
  BitmapDescriptor? _busIcon;
  BitmapDescriptor? _pickupIcon;
  
  // Multiple drivers state
  final List<DriverLocation> _drivers = [
    DriverLocation(id: 'd1', name: 'Truck 1 (Mumbai South)', initialLocation: const LatLng(18.9220, 72.8347), color: Colors.orange),
    DriverLocation(id: 'd2', name: 'Truck 2 (Dadar/Worli)', initialLocation: const LatLng(19.0178, 72.8478), color: Colors.blue),
    DriverLocation(id: 'd3', name: 'Truck 3 (Andheri)', initialLocation: const LatLng(19.1136, 72.8697), color: Colors.green),
  ];

  // Static Pickup Points
  final List<Map<String, dynamic>> _pickupPoints = [
    {'id': 'p1', 'name': 'Bandra West Stop', 'lat': 19.0596, 'lng': 72.8295},
    {'id': 'p2', 'name': 'Juhu Beach Point', 'lat': 19.0988, 'lng': 72.8264},
    {'id': 'p3', 'name': 'Powai Lake Hub', 'lat': 19.1290, 'lng': 72.9042},
    {'id': 'p4', 'name': 'Versova Ward', 'lat': 19.1383, 'lng': 72.8106},
  ];

  @override
  void initState() {
    super.initState();
    _loadIcons();
    _startLiveTracking();
  }

  Future<void> _loadIcons() async {
    final busIcon = await MapHelper.getMarkerIconFromIcon(Icons.directions_bus, Colors.orange, 90);
    final pickupIcon = await MapHelper.getMarkerIconFromIcon(Icons.location_on, Colors.red, 70);
    if (mounted) {
      setState(() {
        _busIcon = busIcon;
        _pickupIcon = pickupIcon;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startLiveTracking() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          for (var driver in _drivers) {
            driver.moveSlightly();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Set<Marker> markers = {};

    // 1. Add Pickup Point Markers
    for (var point in _pickupPoints) {
      markers.add(
        Marker(
          markerId: MarkerId(point['id']),
          position: LatLng(point['lat'], point['lng']),
          icon: _pickupIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: point['name'], snippet: 'Pickup Point'),
        ),
      );
    }

    // 2. Add Multiple Live Driver Markers
    for (var driver in _drivers) {
      markers.add(
        Marker(
          markerId: MarkerId(driver.id),
          position: driver.currentLocation,
          rotation: driver.heading,
          icon: _busIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: driver.name,
            snippet: 'Status: On Route • Speed: 32 km/h',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Fleet Live Tracking')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(19.0760, 72.8777),
              zoom: 12,
            ),
            markers: markers,
            myLocationEnabled: true,
            onMapCreated: (controller) => _mapController = controller,
          ),
          // Legend/Status Card
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _drivers.length,
                itemBuilder: (context, index) {
                  final driver = _drivers[index];
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Container(
                      width: 160,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(width: 8, height: 8, decoration: BoxDecoration(color: driver.color, shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(driver.name.split(' (').first, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => _mapController?.animateCamera(CameraUpdate.newLatLng(driver.currentLocation)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: driver.color.withOpacity(0.1),
                              foregroundColor: driver.color,
                              elevation: 0,
                              minimumSize: const Size(double.infinity, 30),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text('Track', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DriverLocation {
  final String id;
  final String name;
  LatLng currentLocation;
  final Color color;
  double heading = 0.0;
  final Random _random = Random();

  DriverLocation({required this.id, required this.name, required LatLng initialLocation, required this.color}) : currentLocation = initialLocation;

  void moveSlightly() {
    // Random move between -0.0005 and 0.0005
    double latOffset = (_random.nextDouble() - 0.5) * 0.001;
    double lngOffset = (_random.nextDouble() - 0.5) * 0.001;
    currentLocation = LatLng(currentLocation.latitude + latOffset, currentLocation.longitude + lngOffset);
    heading = _random.nextDouble() * 360;
  }
}
