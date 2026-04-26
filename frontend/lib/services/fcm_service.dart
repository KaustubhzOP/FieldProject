import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Sends FCM push notifications using the FCM HTTP v1 API.
class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  static const String _projectId = 'smart-waste-collection-6a2f0';
  static const String _fcmScope  = 'https://www.googleapis.com/auth/firebase.messaging';

  Future<void> sendArrivalAlert(String residentId) async {
    if (kIsWeb) {
      print('[FCM] Skipping push from Web browser (not supported for direct client-to-client).');
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(residentId).get();
      if (!doc.exists) return;
      final token = doc.data()?['fcmToken'] as String?;
      if (token == null || token.isEmpty) return;
      
      bool lead = await _takeLead('arrival_$residentId', durationMinutes: 10);
      if (!lead) return;

      await sendDirectPush(
        token: token,
        title: 'Arrival Alert 🚛',
        body: 'Garbage truck has arrived near your location.',
        data: {'type': 'truck_arrival', 'residentId': residentId},
      );
    } catch (e) {
      print('[FCM] Error: $e');
    }
  }

  Future<void> sendDirectPush({
    required String token,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    if (kIsWeb) {
      print('[FCM] Push notifications cannot be sent directly FROM the web browser for security reasons.');
      return;
    }
    try {
      await _send(token: token, title: title, body: body, data: data);
    } catch (e) {
      print('[FCM] Error: $e');
    }
  }

  Future<bool> _takeLead(String eventId, {int durationMinutes = 5}) async {
    try {
      final ref = FirebaseFirestore.instance.collection('notification_logs').doc(eventId);
      final doc = await ref.get();
      if (doc.exists) {
        final ts = (doc.data()?['timestamp'] as Timestamp?)?.toDate();
        if (ts != null && DateTime.now().difference(ts).inMinutes < durationMinutes) return false;
      }
      await ref.set({'timestamp': FieldValue.serverTimestamp()});
      return true;
    } catch (_) { return false; }
  }

  Future<String> _getAccessToken() async {
    // This part requires dart:io (auth.clientViaServiceAccount), which is not for web.
    final jsonString = await rootBundle.loadString('assets/smart-waste-collection-6a2f0-firebase-adminsdk-fbsvc-04712bc14c.json');
    final credentials = auth.ServiceAccountCredentials.fromJson(jsonDecode(jsonString));
    final client = await auth.clientViaServiceAccount(credentials, [_fcmScope]);
    final token = client.credentials.accessToken.data;
    client.close();
    return token;
  }

  Future<void> _send({required String token, required String title, required String body, Map<String, String>? data}) async {
    final accessToken = await _getAccessToken();
    final url = Uri.parse('https://fcm.googleapis.com/v1/projects/$_projectId/messages:send');
    
    final enhancedData = Map<String, String>.from(data ?? {});
    enhancedData['click_action'] = 'FLUTTER_NOTIFICATION_CLICK';

    final payload = jsonEncode({
      'message': {
        'token': token,
        'notification': {'title': title, 'body': body},
        'android': {
          'notification': {'channel_id': 'smart_waste_channel', 'sound': 'default', 'priority': 'HIGH'},
        },
        'data': enhancedData,
      },
    });

    final res = await http.post(url, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'}, body: payload);
    if (res.statusCode == 200) print('[FCM] ✓ Push sent');
    else print('[FCM] ✗ Push failed: ${res.body}');
  }
}
