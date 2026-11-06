import 'package:flutter_test/flutter_test.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/habit_alarms.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(tz_data.initializeTimeZones);

  test('a morning reminder later today stays on that clock', () {
    final kyiv = tz.getLocation('Europe/Kyiv');
    final now = tz.TZDateTime(kyiv, 2026, 11, 6, 6, 0);
    final next = nextReminder(reminder: '07:30', location: kyiv, now: now);

    expect(next.location, kyiv);
    expect(next.year, 2026);
    expect(next.month, 11);
    expect(next.day, 6);
    expect(next.hour, 7);
    expect(next.minute, 30);
  });

  test('a reminder that already passed moves to the next day', () {
    final kyiv = tz.getLocation('Europe/Kyiv');
    final now = tz.TZDateTime(kyiv, 2026, 11, 6, 10, 15);
    final next = nextReminder(reminder: '07:30', location: kyiv, now: now);

    expect(next.day, 7);
    expect(next.hour, 7);
    expect(next.minute, 30);
    expect(next.isAfter(now), isTrue);
  });

  test('each habit keeps its own alarm id', () {
    expect(alarmIdFor('morning'), isNot(alarmIdFor('evening')));
    expect(alarmIdFor('morning'), alarmIdFor('morning'));
  });
}
