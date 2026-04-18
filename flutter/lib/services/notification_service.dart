import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const int _dailyReminderId = 7001;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (kIsWeb) {
      _initialized = true;
      return;
    }
    if (_initialized) {
      return;
    }

    tz.initializeTimeZones();
    try {
      final String timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) {
      return false;
    }
    await initialize();

    bool granted = true;

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final bool? androidResult = await androidPlugin
        ?.requestNotificationsPermission();
    if (androidResult != null) {
      granted = granted && androidResult;
    }

    final IOSFlutterLocalNotificationsPlugin? iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final bool? iosResult = await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    if (iosResult != null) {
      granted = granted && iosResult;
    }

    final MacOSFlutterLocalNotificationsPlugin? macPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    final bool? macResult = await macPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    if (macResult != null) {
      granted = granted && macResult;
    }

    return granted;
  }

  Future<void> scheduleDailyReminder({required int hour}) async {
    if (kIsWeb) {
      return;
    }
    await initialize();

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _dailyReminderId,
      'Study reminder',
      'Open All in One Coaching and keep your streak alive today.',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_study_reminders',
          'Daily Study Reminders',
          channelDescription: 'Daily reminders to continue learning.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelDailyReminder() async {
    if (kIsWeb) {
      return;
    }
    await initialize();
    await _plugin.cancel(_dailyReminderId);
  }

  Future<void> syncDailyReminder({
    required bool enabled,
    required int hour,
    bool requestPermission = false,
  }) async {
    if (!enabled) {
      await cancelDailyReminder();
      return;
    }

    if (kIsWeb) {
      return;
    }

    if (requestPermission) {
      final bool granted = await requestPermissions();
      if (!granted) {
        throw StateError('Notification permission not granted');
      }
    }
    await scheduleDailyReminder(hour: hour);
  }
}
