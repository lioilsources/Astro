import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Evening reminder to rate the day (plan 10.3). Opt-in, off by default.
class ReminderSettings {
  final bool enabled;

  /// Minutes after local midnight.
  final int minutes;
  const ReminderSettings({this.enabled = false, this.minutes = 20 * 60 + 30});

  ReminderSettings copyWith({bool? enabled, int? minutes}) =>
      ReminderSettings(enabled: enabled ?? this.enabled, minutes: minutes ?? this.minutes);

  static Future<ReminderSettings> load() async {
    final p = await SharedPreferences.getInstance();
    return ReminderSettings(
      enabled: p.getBool('journalReminder') ?? false,
      minutes: p.getInt('journalReminderMinutes') ?? 20 * 60 + 30,
    );
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('journalReminder', enabled);
    await p.setInt('journalReminderMinutes', minutes);
  }
}

/// Local notifications only; nothing goes over the network.
abstract interface class Reminders {
  /// Schedules the daily reminder; false when the user denied the permission.
  Future<bool> schedule(int minutes, {required String title, required String body});
  Future<void> cancel();
}

class LocalReminders implements Reminders {
  static const _id = 1003;
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> _init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation((await FlutterTimezone.getLocalTimezone()).identifier));
    } catch (e) {
      debugPrint('reminder: local time zone unknown, using UTC offset ($e)');
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false),
      ),
    );
    _ready = true;
  }

  @override
  Future<bool> schedule(int minutes, {required String title, required String body}) async {
    await _init();
    final granted = await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission() ??
        await _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, sound: true) ??
        true;
    if (!granted) return false;
    final now = tz.TZDateTime.now(tz.local);
    var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, minutes ~/ 60, minutes % 60);
    if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
    await _plugin.cancel(id: _id);
    await _plugin.zonedSchedule(
      id: _id,
      scheduledDate: at,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails('journal', title, importance: Importance.defaultImportance),
        iOS: const DarwinNotificationDetails(),
      ),
      // Inexact is enough for a reminder and needs no exact-alarm permission.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    return true;
  }

  @override
  Future<void> cancel() async {
    await _init();
    await _plugin.cancel(id: _id);
  }
}
