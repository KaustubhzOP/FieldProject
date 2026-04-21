import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/auth_service.dart';
import '../../config/app_colors.dart';
import '../../utils/map_styles.dart';

class AdminAssignRouteScreen extends StatefulWidget {
  const AdminAssignRouteScreen({super.key});

  @override
  State<AdminAssignRouteScreen> createState() => _AdminAssignRouteScreenState();
}

class _AdminAssignRouteScreenState extends State<AdminAssignRouteScreen> {
  final _authService = AuthService();
  String? _selectedDriverId;
  String? _selectedDriverName;
  Map<String, dynamic>? _selectedRoute;
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _predefinedRoutes = [
    {
      'name': 'Bandra West Cycle', 'id': 'route_bandra', 'ward': 'Ward 1',
      'description': 'Main market and residential loop',
      'path': [{'lat': 19.0596, 'lng': 72.8295}, {'lat': 19.0620, 'lng': 72.8350}, {'lat': 19.0650, 'lng': 72.8300}, {'lat': 19.0596, 'lng': 72.8295}],
      'color': Colors.blueAccent,
    },
    {
      'name': 'Dharavi Sector 4', 'id': 'route_dharavi', 'ward': 'Ward 2',
      'description': 'High density waste collection',
      'path': [{'lat': 19.0400, 'lng': 72.8500}, {'lat': 19.0450, 'lng': 72.8550}, {'lat': 19.0480, 'lng': 72.8520}, {'lat': 19.0400, 'lng': 72.8500}],
      'color': Colors.orangeAccent,
    },
    {
      'name': 'Kurla North Line', 'id': 'route_kurla', 'ward': 'Ward 3',
      'description': 'Industrial area sweep',
      'path': [{'lat': 19.0760, 'lng': 72.8777}, {'lat': 19.0800, 'lng': 72.8850}, {'lat': 19.0850, 'lng': 72.8820}, {'lat': 19.0760, 'lng': 72.8777}],
      'color': Colors.greenAccent,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Route Management')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 10), 
            child: Text('SELECT FIELD OPERATOR', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2))
          ),
          _buildDriverSelector(),
          const SizedBox(height: 20),
          Expanded(
            child: _selectedDriverId == null 
              ? _buildEmptyState('Choose a driver to see available routes')
              : _buildRouteSelection(),
          ),
          if (_selectedDriverId != null && _selectedRoute != null) _buildAssignmentFooter(),
        ],
      ),
    );
  }

  Widget _buildDriverSelector() {
    // These are the official 5 drivers we always want to show
    final List<Map<String, String>> fallbackDrivers = [
      {'id': 'driver_1', 'name': 'Driver 1 (Alpha)', 'truck': 'Truck Alpha'},
      {'id': 'driver_2', 'name': 'Driver 2 (Beta)', 'truck': 'Truck Beta'},
      {'id': 'driver_3', 'name': 'Driver 3 (Gamma)', 'truck': 'Truck Gamma'},
      {'id': 'driver_4', 'name': 'Driver 4 (Delta)', 'truck': 'Truck Delta'},
      {'id': 'driver_5', 'name': 'Driver 5 (Epsilon)', 'truck': 'Truck Epsilon'},
    ];

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('drivers').snapshots(),
      builder: (context, snapshot) {
        // Collect drivers from Firestore
        final List<Map<String, String>> displayDrivers = [];
        final Set<String> existingIds = {};

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final id = doc.id;
            existingIds.add(id);
            displayDrivers.add({
              'id': id,
              'name': data['name'] ?? 'Unknown Driver',
              'truck': data['truckLabel'] ?? 'No Truck',
            });
          }
        }

        // Fill remaining from fallback list (if database is empty or quota hit)
        for (var fallback in fallbackDrivers) {
          if (!existingIds.contains(fallback['id'])) {
            displayDrivers.add(fallback);
          }
        }

        // Sort them driver_1 to driver_5
        displayDrivers.sort((a, b) => a['id']!.compareTo(b['id']!));

        return SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: displayDrivers.length,
            itemBuilder: (context, index) {
              final driver = displayDrivers[index];
              final String id = driver['id']!;
              final String name = driver['name']!;
              final String truck = driver['truck']!;
              
              bool isSelected = _selectedDriverId == id;

              return GestureDetector(
                onTap: () => setState(() { 
                  _selectedDriverId = id; 
                  _selectedDriverName = name; 
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 110,
                  margin: const EdgeInsets.only(right: 15),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accent : AppColors.secondary,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? Colors.white24 : Colors.transparent),
                    boxShadow: isSelected ? [BoxShadow(color: AppColors.accent.withOpacity(0.3), blurRadius: 10)] : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_shipping_rounded, color: isSelected ? Colors.white : AppColors.textMuted, size: 24),
                      const SizedBox(height: 8),
                      Text(name, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(truck, style: TextStyle(fontSize: 9, color: isSelected ? Colors.white70 : AppColors.textMuted)),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRouteSelection() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const Text('ASSIGN COLLECTION PATH', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 16),
        ..._predefinedRoutes.map((route) {
          bool isSelected = _selectedRoute?['id'] == route['id'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              onTap: () => setState(() => _selectedRoute = route),
              borderRadius: BorderRadius.circular(25),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: isSelected ? AppColors.accent : Colors.white.withOpacity(0.05), width: 1.5),
                ),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: (route['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.map_rounded, color: route['color'])),
                      title: Text(route['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(route['description'], style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.accent) : const Icon(Icons.circle_outlined, color: Colors.white10),
                    ),
                    if (isSelected) 
                      Container(
                        height: 180, width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(target: LatLng(route['path'][0]['lat'], route['path'][0]['lng']), zoom: 13),
                            polylines: {Polyline(polylineId: const PolylineId('preview'), points: (route['path'] as List).map((p) => LatLng(p['lat'], p['lng'])).toList(), color: route['color'], width: 4)},
                            style: MapStyles.darkStyle, liteModeEnabled: true, zoomControlsEnabled: false,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAssignmentFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
      decoration: BoxDecoration(
        color: AppColors.secondary, 
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20)]
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text('Confirming ${_selectedRoute!['name']} for Operator $_selectedDriverName', style: const TextStyle(color: AppColors.textBody, fontSize: 13))),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _assignRoute,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: _isSubmitting 
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                  : const Text('DEPLOY ASSIGNMENT', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignRoute() async {
    setState(() => _isSubmitting = true);
    try {
      final sanitizedRoute = Map<String, dynamic>.from(_selectedRoute!);
      sanitizedRoute.remove('color');
      
      await _authService.assignRouteToDriver(_selectedDriverId!, sanitizedRoute, ward: _selectedRoute!['ward']);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deployment successful!'), backgroundColor: Colors.teal, behavior: SnackBarBehavior.floating)
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('[ASSIGN] Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Critical Error: $e'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating)
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hub_outlined, size: 80, color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 20),
          Text(message, style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
        ],
      ),
    );
  }
}
