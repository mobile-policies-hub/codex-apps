import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hybrid_app/core/config/app_brand_config.dart';
import 'package:hybrid_app/modules/native_dashboard/domain/tracker_format.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/native_dashboard_screen.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/tracker_controller.dart';

void main() {
  final thursday = DateTime(2026, 10, 8);

  test('formats counts, dates, and English plurals', () {
    expect(thursday.weekday, DateTime.thursday);
    expect(formatCount(7420), '7\u00A0420');
    expect(formatCount(8000), '8\u00A0000');
    expect(formatKilometers(5.565), '5.6');
    expect(formatLongDate(thursday), 'Thursday, October 8');
    expect(pluralize(1, 'step', 'steps'), 'step');
    expect(pluralize(2, 'step', 'steps'), 'steps');
    expect(pluralize(5, 'day', 'days'), 'days');
  });

  test('builds Thursday focus score from habits and finished sessions', () {
    final tracker = TrackerController(today: thursday);

    expect(tracker.focusScore, 0);
    expect(tracker.scorePercent, 0);
    expect(tracker.pointsRemaining, 100);
    expect(tracker.scoreGoalReached, isFalse);
    expect(tracker.weekScores, [0, 0, 0, 0, 0, 0, 0]);

    tracker.toggleHabit('morning');
    expect(tracker.habitPoints, 11);
    expect(tracker.focusScore, 11);
    expect(tracker.weekScores[DateTime.thursday - 1], 11);
    expect(tracker.weekScores.where((score) => score == 0), hasLength(6));
  });

  test('a finished focus block adds ten points', () {
    final tracker = TrackerController(today: thursday);
    addTearDown(tracker.dispose);
    tracker.selectFocusMinutes(15);
    tracker.recordFinishedFocusBlock();
    expect(tracker.completedSessions, 1);
    expect(tracker.focusedMinutes, 15);
    expect(tracker.sessionPoints, 10);
    expect(tracker.focusScore, 10);
    expect(tracker.sessions.first, 'Finished a 15 min block');
  });

  testWidgets('renders the day tracker with metrics and a week chart', (
    tester,
  ) async {
    await tester.pumpWidget(
      AppBrand(
        config: AppBrandConfig.zenithHabits,
        child: MaterialApp(home: NativeDashboardScreen(today: thursday)),
      ),
    );

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Thursday, October 8'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('Daily Score'), findsWidgets);
    expect(find.text('Score'), findsOneWidget);
    expect(find.text('Focus time'), findsOneWidget);
    expect(find.text('0m'), findsOneWidget);
    expect(find.text('Score by day'), findsOneWidget);
    expect(find.text('Hydration'), findsOneWidget);
    expect(find.text('of 8'), findsOneWidget);
    expect(find.text('Week'), findsOneWidget);
    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('Thu'), findsOneWidget);
    expect(find.text('Sun'), findsOneWidget);
    expect(find.byKey(const Key('reminder-banner')), findsOneWidget);
    expect(find.byKey(const Key('week-chart')), findsOneWidget);
  });

  testWidgets('settings change the home metrics and the reminder', (
    tester,
  ) async {
    await tester.pumpWidget(
      AppBrand(
        config: AppBrandConfig.zenithHabits,
        child: MaterialApp(home: NativeDashboardScreen(today: thursday)),
      ),
    );

    await tester.tap(find.byKey(const Key('open-settings')));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Daily score goal'), findsOneWidget);

    await tester.tap(find.byKey(const Key('water-goal-increase')));
    await tester.tap(find.byKey(const Key('reminders-switch')));
    await tester.pump();

    expect(find.text('9'), findsOneWidget);

    await tester.tap(find.byKey(const Key('close-settings')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reminder-banner')), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const Key('metric-water')),
        matching: find.text('of 9'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('metric-steps')),
        matching: find.text('Daily Score'),
      ),
      findsOneWidget,
    );
    expect(find.text('Steps'), findsNothing);
    expect(find.textContaining('5120'), findsNothing);
  });

  testWidgets('brand config renames the dashboard and recolors it', (
    tester,
  ) async {
    const brand = AppBrandConfig(
      appName: 'Pulse',
      primaryColor: Color(0xFFB45309),
      nativeDashboardTitle: 'Overview',
    );

    await tester.pumpWidget(
      AppBrand(
        config: brand,
        child: MaterialApp(home: NativeDashboardScreen(today: thursday)),
      ),
    );

    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Today'), findsNothing);
    expect(buildAppTheme(brand).colorScheme.primary, brand.primaryColor);

    final icon = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const Key('metric-focus')),
        matching: find.byType(Icon),
      ),
    );
    expect(icon.color, brand.primaryColor);
  });
}
