import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:hybrid_app/modules/native_dashboard/presentation/tracker_controller.dart';

/// Schedules one daily local notification at each habit's clock time.
class LocalHabitAlarms implements HabitAlarmScheduler {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> _ensure() async {
    if (_ready) return;
    useDeviceTimeZone();
    await _plugin.initialize(
      settings: const InitializationSettings(
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  @override
  Future<void> sync(List<Habit> habits) async {
    if (kIsWeb) return;
    try {
      await _ensure();
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: false, sound: true);
      await cancelAll();
      for (final habit in habits) {
        final when = nextReminder(
          reminder: habit.reminder,
          location: tz.local,
          now: tz.TZDateTime.now(tz.local),
        );
        await _plugin.zonedSchedule(
          id: alarmIdFor(habit.id),
          title: habit.title,
          body: 'Reminder at ${habit.reminder}',
          scheduledDate: when,
          notificationDetails: const NotificationDetails(
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    } catch (error, stack) {
      log(
        'Habit reminder was not scheduled',
        name: 'HabitAlarms',
        error: error,
        stackTrace: stack,
      );
    }
  }

  @override
  Future<void> cancelAll() async {
    if (kIsWeb) return;
    try {
      await _plugin.cancelAll();
    } catch (error, stack) {
      log(
        'Habit reminders were not cleared',
        name: 'HabitAlarms',
        error: error,
        stackTrace: stack,
      );
    }
  }
}

/// Picks a timezone database entry that matches the phone's current offset.
///
/// `tz.local` starts as UTC. Scheduling against UTC fires the alert hours
/// away from the clock time shown on the habit.
void useDeviceTimeZone() {
  tz_data.initializeTimeZones();
  final now = DateTime.now();
  final offset = now.timeZoneOffset;
  final abbreviation = now.timeZoneName;
  tz.Location? sameOffset;
  tz.Location? sameName;
  for (final location in tz.timeZoneDatabase.locations.values) {
    if (location.name.startsWith('Etc/')) continue;
    final there = tz.TZDateTime.now(location);
    if (there.timeZoneOffset != offset) continue;
    sameOffset ??= location;
    if (there.timeZoneName == abbreviation) {
      sameName = location;
      break;
    }
  }
  tz.setLocalLocation(sameName ?? sameOffset ?? tz.UTC);
}

/// Next wall-clock occurrence of [reminder] (`HH:mm`) in [location].
tz.TZDateTime nextReminder({
  required String reminder,
  required tz.Location location,
  required tz.TZDateTime now,
}) {
  final parts = reminder.split(':');
  final hour = int.tryParse(parts.first) ?? 8;
  final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
  var scheduled = tz.TZDateTime(
    location,
    now.year,
    now.month,
    now.day,
    hour.clamp(0, 23),
    minute.clamp(0, 59),
  );
  if (!scheduled.isAfter(now)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }
  return scheduled;
}

int alarmIdFor(String habitId) => habitId.hashCode & 0x3fffffff;
