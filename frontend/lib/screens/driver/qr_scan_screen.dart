import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../providers/auth_provider.dart';
import '../../services/qr_scanner_service.dart';
import '../../config/app_colors.dart';
import 'dart:ui';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final MobileScannerController controller = MobileScannerController();
  final QrScannerService _qrService = QrScannerService();
  bool _isProcessing = false;
  bool _hasPermission = false;
  bool _isCheckingPermission = true;

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    if (mounted) {
      setState(() {
        _hasPermission = status.isGranted;
        _isCheckingPermission = false;
      });
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final String? code = barcodes.first.displayValue;
    if (code == null) return;

    setState(() => _isProcessing = true);
    controller.stop();

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    if (user != null) {
      try {
        await _qrService.logCollection(
          binId: code,
          driverId: user.id,
          driverName: user.name,
        );
        if (mounted) _showResultDialog(true, 'Collection Success', 'Bin $code has been logged.');
      } catch (e) {
        if (mounted) _showResultDialog(false, 'Collection Failed', 'Error: $e');
      }
    }
  }

  void _showResultDialog(bool success, String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(success ? Icons.check_circle : Icons.error, color: success ? AppColors.success : AppColors.error),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: AppColors.textBody)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isProcessing = false);
              controller.start();
            },
            child: const Text('CONTINUE', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bin Collection Scanner'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isCheckingPermission) return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    if (!_hasPermission) return _buildNoPermissionUI();

    return Stack(
      children: [
        MobileScanner(
          controller: controller,
          onDetect: _onDetect,
        ),
        _buildScannerOverlay(),
        if (_isProcessing) 
          Container(
            color: Colors.black54,
            child: const Center(child: CircularProgressIndicator(color: AppColors.accent)),
          ),
      ],
    );
  }

  Widget _buildNoPermissionUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_alt_outlined, size: 80, color: AppColors.textMuted),
          const SizedBox(height: 24),
          const Text('Camera Access Required', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Please enable camera permissions to scan QR codes.', style: TextStyle(color: AppColors.textBody)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _requestPermission,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('Grant Permission'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => openAppSettings(),
            child: const Text('Open App Settings', style: TextStyle(color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Stack(
      children: [
        Center(
          child: Container(
            width: 260, height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.accent, width: 2),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.2), blurRadius: 40, spreadRadius: 5)],
            ),
          ),
        ),
        Positioned(
          bottom: 60, left: 0, right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white10),
              ),
              child: const Text('Center the Bin QR code to log collection', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
