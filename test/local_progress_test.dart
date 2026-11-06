import 'package:flutter_test/flutter_test.dart';
import 'package:hybrid_app/modules/native_dashboard/data/local_vault.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/ancient_codex_controller.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/apex_calc_controller.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/apex_report.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/tracker_controller.dart';

void main() {
  final thursday = DateTime(2026, 10, 8);

  test('lesson, habit, and calculation progress reload from the vault', () {
    final vault = MemoryVault();

    final codex = AncientCodexController(vault: vault);
    codex.completeLesson('scarab');
    codex.selectGlyph(1);
    final reloadedCodex = AncientCodexController(vault: vault);
    expect(
      reloadedCodex.lessons
          .firstWhere((lesson) => lesson.id == 'scarab')
          .progress,
      1,
    );
    expect(reloadedCodex.selectedGlyph, 1);
    expect(reloadedCodex.bestScore, 0);

    final tracker = TrackerController(today: thursday, vault: vault);
    tracker.toggleHabit('morning');
    tracker.setMood(2);
    tracker.setNotificationsEnabled(false);
    final reloadedTracker = TrackerController(today: thursday, vault: vault);
    final morning = reloadedTracker.habits.firstWhere(
      (habit) => habit.id == 'morning',
    );
    expect(morning.done, isTrue);
    expect(morning.personalStreak, 1);
    expect(reloadedTracker.moodIndex, 2);
    expect(reloadedTracker.notificationsEnabled, isFalse);
    tracker.setHabitReminder('walk', '19:05');
    tracker.setWaterGoal(6);
    tracker.setQuietHours(true);
    final reminded = TrackerController(today: thursday, vault: vault);
    expect(
      reminded.habits.firstWhere((habit) => habit.id == 'walk').reminder,
      '19:05',
    );
    expect(reminded.waterGoal, 6);
    expect(reminded.quietHours, isTrue);

    final calc = ApexCalcController(vault: vault);
    calc.saveNote('Mortgage');
    calc.setFromCurrency('GBP');
    calc.setToCurrency('JPY');
    final reloadedCalc = ApexCalcController(vault: vault);
    expect(reloadedCalc.history.single.note, 'Mortgage');
    expect(reloadedCalc.fromCurrency, 'GBP');
    expect(reloadedCalc.toCurrency, 'JPY');
  });

  test('apex export builds a pdf document', () async {
    final calc = ApexCalcController()..saveNote('Mortgage');
    final bytes = await buildApexReportPdf(calc);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(500));
  });
}
