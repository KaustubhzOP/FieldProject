import 'package:cloud_firestore/cloud_firestore.dart';

class QrScannerService {
  static final QrScannerService _instance = QrScannerService._internal();
  factory QrScannerService() => _instance;
  QrScannerService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Logs a bin collection to Firestore when scanned via QR code.
  Future<void> logCollection({
    required String binId,
    required String driverId,
    required String driverName,
  }) async {
    final collectionRef = _firestore.collection('collections');
    
    // For QR codes, we might not have real-time weight/fill data unless 
    // the QR code itself contains it or we prompt the driver to enter it.
    // For now, let's assume valid scan = 100% capacity collected.
    
    await collectionRef.add({
      'binId': binId,
      'driverId': driverId,
      'driverName': driverName,
      'collectedAt': FieldValue.serverTimestamp(),
      'status': 'collected',
      'source': 'qr_code',
    });

    // Update the bin status in Firestore
    await _firestore.collection('bins').doc(binId).set({
      'binId': binId,
      'lastCollected': FieldValue.serverTimestamp(),
      'lastCollectedBy': driverName,
      'status': 'empty',
    }, SetOptions(merge: true));
  }
}
