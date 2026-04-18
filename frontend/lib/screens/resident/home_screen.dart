import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../utils/constants.dart';
import '../../utils/map_helper.dart';

class ResidentHomeScreen extends StatefulWidget {
  const ResidentHomeScreen({super.key});

  @override
  State<ResidentHomeScreen> createState() => _ResidentHomeScreenState();
}

class _ResidentHomeScreenState extends State<ResidentHomeScreen> {
  GoogleMapController? _mapController;
  Timer? _timer;
  BitmapDescriptor? _busIcon;
  BitmapDescriptor? _pickupIcon;
  
  // Track location state
  LatLng _busLocation = const LatLng(19.0760, 72.8777);
  int _eta = 8;
  int _distance = 2; // km

  // Static Pickup Point
  final LatLng _residentHouse = const LatLng(19.0880, 72.8890);

  @override
  void initState() {
    super.initState();
    _loadIcons();
    _startLiveTracking();
  }

  Future<void> _loadIcons() async {
    final busIcon = await MapHelper.getMarkerIconFromIcon(Icons.directions_bus, Colors.orange, 100);
    final pickupIcon = await MapHelper.getMarkerIconFromIcon(Icons.home, Colors.blue, 80);
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
          // Move Bus towards Resident House
          double latStep = (_residentHouse.latitude - _busLocation.latitude) * 0.05;
          double lngStep = (_residentHouse.longitude - _busLocation.longitude) * 0.05;
          
          _busLocation = LatLng(
            _busLocation.latitude + latStep,
            _busLocation.longitude + lngStep,
          );
          
          if (_eta > 1) {
            _eta -= 1;
            if (_eta % 2 == 0) _distance -= 1;
          } else {
            _eta = 1;
            _distance = 0;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Set<Marker> markers = {};

    markers.add(
      Marker(
        markerId: const MarkerId('resident_house'),
        position: _residentHouse,
        icon: _pickupIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'My House', snippet: 'Pickup Point'),
      ),
    );

    markers.add(
      Marker(
        markerId: const MarkerId('live_bus'),
        position: _busLocation,
        icon: _busIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(
          title: 'Smart Waste Truck MH-01-AB-1234',
          snippet: 'ETA: $_eta mins',
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Truck Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(_busLocation, 14),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(AppConstants.defaultLatitude, AppConstants.defaultLongitude),
              zoom: 14,
            ),
            markers: markers,
            myLocationEnabled: true,
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),
          
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _legendItem(Icons.directions_bus, Colors.orange, 'Waste Truck'),
                  _legendItem(Icons.home, Colors.blue, 'My House'),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.orange,
                        radius: 25,
                        child: Icon(Icons.bus_alert, color: Colors.white),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Truck MH-01-AB-1234', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            Text('Status: Approaching your area (Approx. $_distance km)'),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                        child: Text('$_eta MINS', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_active),
                    label: const Text('Notify me when near'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
