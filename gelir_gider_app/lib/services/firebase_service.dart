import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  void init() async {
    // Local notifications init
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initSettings);

    // Request permission
    await _messaging.requestPermission();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((msg) {
      _showLocalNotification(msg.notification?.title, msg.notification?.body);
    });
  }

  void _showLocalNotification(String? title, String? body) async {
    const androidDetails = AndroidNotificationDetails(
      'bill_reminder', 'Bill Reminders', importance: Importance.max,
    );
    const generalNotificationDetails = NotificationDetails(android: androidDetails);
    await _localNotifications.show(0, title, body, generalNotificationDetails);
  }
}