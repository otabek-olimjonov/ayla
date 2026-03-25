import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

part 'notification_service.g.dart';

@riverpod
NotificationService notificationService(NotificationServiceRef ref) {
  return NotificationService();
}

/// Wraps [FlutterLocalNotificationsPlugin].
///
/// Usage:
/// 1. Call [initialize] once in [main] after [WidgetsFlutterBinding.ensureInitialized].
/// 2. Call [requestPermissions] after the onboarding permission screen.
/// 3. Call schedule* methods after computing predictions on every app resume.
class NotificationService {
  NotificationService();

  static const _channelId = 'ayla_reminders';
  static const _channelName = 'Ayla Reminders';

  // Stable IDs — never reuse across different reminder types
  static const int periodReminderId = 1;
  static const int ovulationReminderId = 2;
  static const int pregnancyWeeklyId = 3;
  static const int dailyHealthLogId = 4;

  final _plugin = FlutterLocalNotificationsPlugin();

  // --------------------------------------------------------------------------
  // Init
  // --------------------------------------------------------------------------

  /// Call once in [main] after [WidgetsFlutterBinding.ensureInitialized].
  Future<void> initialize() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  /// Requests OS permission (Android 13+ / iOS). Returns true if granted.
  Future<bool> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    final androidGranted =
        await android?.requestNotificationsPermission() ?? true;
    final iosGranted =
        await ios?.requestPermissions(alert: true, sound: true) ?? true;

    return androidGranted && iosGranted;
  }

  // --------------------------------------------------------------------------
  // Schedule helpers
  // --------------------------------------------------------------------------

  /// Schedules a period reminder [daysBefore] days before [nextPeriodDate]
  /// at [hour]:[minute] local time. Silently ignored if the trigger is past.
  Future<void> schedulePeriodReminder({
    required DateTime nextPeriodDate,
    required int daysBefore,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final triggerDate = nextPeriodDate.subtract(Duration(days: daysBefore));
    await _schedule(
      id: periodReminderId,
      triggerDate: triggerDate,
      hour: hour,
      minute: minute,
      title: title,
      body: body,
    );
  }

  /// Schedules an ovulation-day reminder at [hour]:[minute] local time.
  Future<void> scheduleOvulationReminder({
    required DateTime ovulationDate,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await _schedule(
      id: ovulationReminderId,
      triggerDate: ovulationDate,
      hour: hour,
      minute: minute,
      title: title,
      body: body,
    );
  }

  /// Schedules a weekly pregnancy milestone notification.
  Future<void> schedulePregnancyWeeklyReminder({
    required DateTime triggerDate,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await _schedule(
      id: pregnancyWeeklyId,
      triggerDate: triggerDate,
      hour: hour,
      minute: minute,
      title: title,
      body: body,
    );
  }

  /// Cancels all scheduled notifications.
  Future<void> cancelAll() => _plugin.cancelAll();

  /// Cancels a single notification by [id].
  Future<void> cancel(int id) => _plugin.cancel(id);

  // --------------------------------------------------------------------------
  // Internal
  // --------------------------------------------------------------------------

  Future<void> _schedule({
    required int id,
    required DateTime triggerDate,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final location = tz.local;
    final scheduled = tz.TZDateTime(
      location,
      triggerDate.year,
      triggerDate.month,
      triggerDate.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(tz.TZDateTime.now(location))) return;

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      _details(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }
}
