import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';
import '../main.dart';
import '../screens/admin/complaint_management_screen.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _listenersAttached = false;
  String? _pendingComplaintId;
  StreamSubscription? _complaintWatcher;
  StreamSubscription? _userWatcher;
  final Set<String> _processedEvents = {}; // Deduplication for the current session

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  void processPendingNotifications() {
    if (_pendingComplaintId != null) {
      final id = _pendingComplaintId!;
      _pendingComplaintId = null;
      Future.delayed(const Duration(milliseconds: 800), () => _navigateToComplaint(id));
    }
  }

  Future<void> initialize(String userId) async {
    String? token = await _messaging.getToken();
    if (token != null && userId.isNotEmpty) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({'fcmToken': token});
    }

    if (_listenersAttached) return;
    _listenersAttached = true;
    
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: (res) {
        if (res.payload != null) _handleNotificationClick(Uri.splitQueryString(res.payload!));
      },
    );

    FirebaseMessaging.onMessage.listen((msg) {
      if (msg.notification != null) showLocalNotification(msg.notification!.title, msg.notification!.body, msg.data);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((msg) => _handleNotificationClick(msg.data));

    RemoteMessage? initial = await _messaging.getInitialMessage();
    if (initial != null) _handleNotificationClick(initial.data);

    // ── WEB-TO-MOBILE BRIDGE ────────────────────────────────────────────────
    // Because Web browsers cannot send Push pulses to phones for free, 
    // the Mobile app will "watch" the database and ping ITSELF if a 
    // new complaint appears. This ensures you always get a "Ping"!
    _startComplaintWatcher(userId);
  }

  void _startComplaintWatcher(String userId) async {
    _complaintWatcher?.cancel();

    // Check user role to decide what to watch
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final role = userDoc.data()?['role'] ?? 'resident';

    if (role == 'admin') {
      // ADMIN WATCHER: Notify for ANY new complaint
      _complaintWatcher = FirebaseFirestore.instance
          .collection('complaints')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots()
          .listen((snap) {
        for (var change in snap.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final id = change.doc.id;
            final data = change.doc.data();
            // Prevent showing notification for old data on first load
            final createdAt = DateTime.tryParse(data?['createdAt'] ?? '');
            if (createdAt != null && DateTime.now().difference(createdAt).inMinutes < 2) {
               _pingIfNew('new_$id', '🚨 New Complaint Alert', 'Resident ${data?['raisedBy']} raised a ${data?['type']}.', id);
            }
          }
        }
      });
    } else {
      // RESIDENT WATCHER: Notify for status changes on THEIR complaints
      _complaintWatcher = FirebaseFirestore.instance
          .collection('complaints')
          .where('raisedBy', isEqualTo: userId)
          .snapshots()
          .listen((snap) {
        for (var change in snap.docChanges) {
          if (change.type == DocumentChangeType.modified) {
            final id = change.doc.id;
            final status = change.doc.data()?['status'];
            _pingIfNew('update_${id}_$status', '📋 Status Updated', 'Your complaint #$id is now $status.', id);
          }
        }
      });

      // USER WATCHER: Notify for profile changes (Home Verification)
      _userWatcher?.cancel();
      _userWatcher = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots()
          .listen((snap) {
        if (!snap.exists) return;
        final data = snap.data();
        final String? homeStatus = data?['homeStatus'];
        
        if (homeStatus == 'approved') {
          _pingIfNew('home_verified_$userId', '✅ Home Verified', 'Your location has been approved! Your digital bin is now active.', 'home');
        } else if (homeStatus == 'none' && data?['pendingLat'] == null) {
          // If status moved to none and no pending data, it was likely rejected
          _pingIfNew('home_rejected_$userId', '❌ Verification Declined', 'Your location request was declined. Please try again with a clearer position.', 'home');
        }
      });
    }
  }

  void _pingIfNew(String eventKey, String title, String body, String complaintId) async {
    if (_processedEvents.contains(eventKey)) return;
    
    // Check SharedPreferences for persistent deduplication
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('notif_$eventKey') == true) return;

    _processedEvents.add(eventKey);
    await prefs.setBool('notif_$eventKey', true);
    
    showLocalNotification(title, body, {'type': 'status_update', 'complaintId': complaintId});
  }

  void _handleNotificationClick(Map<String, dynamic> data) {
    final complaintId = data['complaintId'];
    if (complaintId != null && complaintId != 'home') {
      if (SmartWasteApp.navigatorKey.currentState == null) _pendingComplaintId = complaintId;
      else _navigateToComplaint(complaintId);
    }
  }

  void _navigateToComplaint(String complaintId) {
    SmartWasteApp.navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => ComplaintDetailScreen(complaintId: complaintId)),
    );
  }

  Future<void> showLocalNotification(String? title, String? body, Map<String, dynamic> data) async {
    const android = AndroidNotificationDetails(
      'smart_waste_channel', 'Smart Waste Notifications',
      importance: Importance.max, priority: Priority.high, playSound: true,
    );
    await _localNotifications.show(
      notificationIdCounter++, title, body, const NotificationDetails(android: android),
      payload: Uri(queryParameters: data.map((k, v) => MapEntry(k, v.toString()))).query,
    );
  }
  static int notificationIdCounter = 0;
}
