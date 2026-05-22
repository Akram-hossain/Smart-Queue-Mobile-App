import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;
    try {
      tz.initializeTimeZones();

      const androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );
      await _plugin.initialize(initSettings);
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }

  /// Request the user-visible POST_NOTIFICATIONS permission on Android 13+.
  Future<bool> requestPermission() async {
    if (!_initialized) await init();
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? true;
    }
    return true;
  }

  NotificationDetails _details({String channelId = 'reminders'}) {
    final android = AndroidNotificationDetails(
      channelId,
      'SemesterMate reminders',
      channelDescription: 'Reminders for exams, assignments and fee deadlines',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const ios = DarwinNotificationDetails();
    return NotificationDetails(android: android, iOS: ios);
  }

  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_initialized) await init();
    await _plugin.show(id, title, body, _details());
  }

  /// Schedule a one-shot notification. Falls back to inexact scheduling so we
  /// don't need the user to grant SCHEDULE_EXACT_ALARM at runtime.
  Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    if (!_initialized) await init();
    if (when.isBefore(DateTime.now())) return;
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(when, tz.local),
        _details(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // swallow — scheduling failure shouldn't crash the app
    }
  }

  Future<void> cancel(int id) async {
    if (!_initialized) return;
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    if (!_initialized) return;
    await _plugin.cancelAll();
  }
}
