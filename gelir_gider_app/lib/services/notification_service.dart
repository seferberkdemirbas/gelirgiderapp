// lib/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/services.dart'; // PlatformException için

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: androidInit),
    );
  }

  static Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) => _plugin.show(
    id,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'instant_channel',
        'Anında Bildirimler',
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
  );

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    final details = const NotificationDetails(
      android: AndroidNotificationDetails(
        'fatura_channel',
        'Fatura Bildirimleri',
        channelDescription: 'Fatura hatırlatma bildirimleri için kanal',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );

    try {
      // Öncelikle exactAllowWhileIdle ile dene
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } on PlatformException catch (e) {
      if (e.code == 'exact_alarms_not_permitted') {
        // Kullanıcı exact alarm izni vermediyse inexact moda geç
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          tzDate,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } else {
        rethrow;
      }
    }
  }

  static Future<void> cancel(int id) => _plugin.cancel(id);
  static Future<void> cancelAll() => _plugin.cancelAll();
}
