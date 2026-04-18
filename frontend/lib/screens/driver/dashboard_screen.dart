import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/location_broadcast_service.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen>
    with SingleTickerProviderStateMixin {
  final _broadcastService = LocationBroadcastService();
  bool _isOnDuty = false;
  bool _isLoading = false;
  String _statusMessage = 'Tap to start duty';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _toggleDuty() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      if (_isOnDuty) {
        await _broadcastService.stopBroadcasting(user.id);
        setState(() {
          _isOnDuty = false;
          _statusMessage = 'Duty ended. Location sharing stopped.';
        });
      } else {
        await _broadcastService.startBroadcasting(user.id, user.name);
        setState(() {
          _isOnDuty = true;
          _statusMessage = 'Broadcasting live location & BLE signal';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        actions: [
          if (_isOnDuty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ScaleTransition(
                scale: _pulseAnimation,
                child: const Icon(Icons.broadcast_on_personal,
                    color: Colors.greenAccent),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 12),

            // ── DUTY TOGGLE CARD ──
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    ScaleTransition(
                      scale: _isOnDuty ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isOnDuty ? Colors.green.shade100 : Colors.red.shade100,
                          boxShadow: [
                            BoxShadow(
                              color: (_isOnDuty ? Colors.green : Colors.red).withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 4,
                            )
                          ],
                        ),
                        child: Icon(
                          _isOnDuty ? Icons.wifi_tethering : Icons.wifi_tethering_off,
                          size: 44,
                          color: _isOnDuty ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isOnDuty ? 'ON DUTY — LIVE' : 'OFF DUTY',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _isOnDuty ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(_statusMessage,
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _toggleDuty,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Icon(_isOnDuty ? Icons.stop_circle : Icons.play_circle),
                        label: Text(_isOnDuty ? 'Stop Duty' : 'Start Duty',
                            style: const TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isOnDuty ? Colors.red : Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── BROADCAST STATUS CARD ──
            if (_isOnDuty)
              Card(
                color: Colors.green.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.green),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'GPS location updating every 10m movement',
                              style: TextStyle(fontSize: 13, color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.bluetooth, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'BLE beacon active — residents can detect your truck',
                              style: TextStyle(fontSize: 13, color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // ── STATS CARDS ──
            Row(
              children: [
                Expanded(child: _buildStatCard('Collections', '5', Icons.check_circle, Colors.green)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard('Pending', '3', Icons.pending, Colors.orange)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildStatCard('Distance', '12 km', Icons.location_on, Colors.blue)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatCard('Time', '2.5 hrs', Icons.access_time, Colors.purple)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
