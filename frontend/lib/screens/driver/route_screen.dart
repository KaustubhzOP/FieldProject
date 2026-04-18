import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DriverRouteScreen extends StatelessWidget {
  const DriverRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // These markers represent resident pickup locations as requested
    final Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('p1'),
        position: const LatLng(19.0760, 72.8777),
        infoWindow: const InfoWindow(title: 'Resident: Sharma House', snippet: 'Pickup: 1 Bin • Status: Pending'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
      Marker(
        markerId: const MarkerId('p2'),
        position: const LatLng(19.0830, 72.8850),
        infoWindow: const InfoWindow(title: 'Resident: Patil Apt', snippet: 'Pickup: 2 Bins • Status: High Priority'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
      Marker(
        markerId: const MarkerId('p3'),
        position: const LatLng(19.0860, 72.8877),
        infoWindow: const InfoWindow(title: 'Resident: Green Villa', snippet: 'Pickup: 1 Bin • Status: Completed'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Assigned Pickup Route')),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(19.0815, 72.8825),
                    zoom: 14,
                  ),
                  markers: markers,
                  myLocationEnabled: true,
                ),
                // Map Color Legend
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _legendRow(Colors.green, 'Completed'),
                        _legendRow(Colors.orange, 'High Priority'),
                        _legendRow(Colors.blue, 'Pending'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pending Pickups (3)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: [
                        _pickupItem('Sharma House', 'Area 5B, Bandra East', '1 Bin', Colors.blue),
                        _pickupItem('Patil Apt', 'Plot 42, Mahim West', '2 Bins', Colors.orange),
                        _pickupItem('Green Villa', 'Road 3, Matunga', '1 Bin', Colors.green),
                      ],
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

  Widget _legendRow(Color color, String text) {
    return Row(
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _pickupItem(String name, String address, String bins, Color color) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.home, color: color),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(address),
        trailing: Text(bins, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
