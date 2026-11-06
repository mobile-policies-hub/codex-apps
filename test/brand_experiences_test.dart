import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hybrid_app/core/config/active_brand.dart';
import 'package:hybrid_app/core/config/app_brand_config.dart';
import 'package:hybrid_app/core/config/brand_support_email.dart';
import 'package:hybrid_app/core/l10n/app_text.dart';
import 'package:hybrid_app/modules/native_dashboard/domain/tracker_format.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/ancient_codex_controller.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/apex_calc_controller.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/native_dashboard_screen.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/sound/sound_deck.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/sound/sound_engine_api.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/tracker_controller.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final thursday = DateTime(2026, 10, 8);

  test('brand presets keep the requested palettes', () {
    expect(activeBrandIdName, 'ancientCodex');
    expect(activeBrandSupportEmail, 'dev.outbox.88@outlook.com');
    expect(AppBrandConfig.current.id, AppBrandId.ancientCodex);
    expect(AppBrandConfig.current.appName, 'Ancient Codex');
    expect(AppBrandConfig.current.bundleId, 'com.ancientcodex.app');
    expect(AppBrandConfig.current.supportEmail, activeBrandSupportEmail);
    expect(AppBrandConfig.ancientCodex.bundleId, 'com.ancientcodex.app');
    expect(AppBrandConfig.apexCalc.bundleId, 'com.apexcalc.app');
    expect(AppBrandConfig.forIdName('ancientCodex').appName, 'Ancient Codex');
    expect(AppBrandConfig.forIdName('apexCalc').iconSetName, 'AppIconApex');

    final xcconfig = File('ios/Flutter/Brand.xcconfig').readAsStringSync();
    expect(xcconfig, contains('APP_DISPLAY_NAME=Ancient Codex'));
    expect(
      xcconfig,
      contains('PRODUCT_BUNDLE_IDENTIFIER=com.ancientcodex.app'),
    );
    expect(
      xcconfig,
      contains('ASSETCATALOG_COMPILER_APPICON_NAME=AppIconAncient'),
    );
    expect(xcconfig, contains('SUPPORT_EMAIL=dev.outbox.88@outlook.com'));
    expect(
      AppBrandConfig.current.supportEmail,
      supportEmailFromXcconfig(xcconfig),
    );
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    expect(plist, contains(r'$(APP_DISPLAY_NAME)'));
    expect(plist, contains(r'$(SUPPORT_EMAIL)'));
    expect(
      File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync(),
      isNot(contains('com.example.hybrid')),
    );
    expect(
      AppBrandConfig.ancientCodex.backgroundColor,
      const Color(0xFF1A0505),
    );
    expect(AppBrandConfig.ancientCodex.primaryColor, const Color(0xFFE0A93B));
    expect(AppBrandConfig.ancientCodex.cardColor, const Color(0xFF2D0D0D));
    expect(
      AppBrandConfig.zenithHabits.backgroundColor,
      const Color(0xFF0F172A),
    );
    expect(AppBrandConfig.zenithHabits.primaryColor, const Color(0xFF10B981));
    expect(AppBrandConfig.zenithHabits.cardColor, const Color(0xFF1E293B));
    expect(AppBrandConfig.apexCalc.backgroundColor, const Color(0xFF0A1128));
    expect(AppBrandConfig.apexCalc.primaryColor, const Color(0xFFFF9F1C));
    expect(AppBrandConfig.apexCalc.cardColor, const Color(0xFF1C2541));
    expect(
      AppBrandConfig.ancientCodex.supportEmail,
      'dev.outbox.88@outlook.com',
    );
    expect(
      AppBrandConfig.zenithHabits.supportEmail,
      'dev.outbox.88@outlook.com',
    );
    expect(AppBrandConfig.apexCalc.supportEmail, 'dev.outbox.88@outlook.com');
  });

  test('SUPPORT_EMAIL text is the settings address', () {
    expect(
      supportEmailFromXcconfig('''
// SUPPORT_EMAIL=ignored@example.com
# SUPPORT_EMAIL=also-ignored@example.com
SUPPORT_EMAIL=desk@example.com
'''),
      'desk@example.com',
    );
    expect(supportEmailFromXcconfig('SUPPORT_EMAIL='), isNull);
    expect(supportEmailFromXcconfig('APP_DISPLAY_NAME=Ancient Codex'), isNull);
  });

  test('packaged brand reads SUPPORT_EMAIL from Brand.xcconfig', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final source = await rootBundle.loadString(brandXcconfigAsset);
    final brand = await AppBrandConfig.loadPackaged();

    expect(brand.supportEmail, supportEmailFromXcconfig(source));
    expect(brand.supportEmail, isNot(contains(' ')));
  });

  test('habits extend the streak and the timer can be paused', () {
    final tracker = TrackerController(today: thursday);

    expect(tracker.streakDays, 0);
    tracker.toggleHabit('morning');
    expect(tracker.completedHabits, 1);
    expect(tracker.streakDays, 1);

    tracker.selectFocusMinutes(15);
    expect(tracker.focusClock, '15:00');
    tracker.toggleFocus();
    expect(tracker.focusRunning, isTrue);
    tracker.toggleFocus();
    expect(tracker.focusRunning, isFalse);
  });

  test('ambient play starts a loop and stop silences it', () {
    final engine = _MemorySoundEngine();
    final deck = SoundDeck(engine: engine);
    addTearDown(deck.dispose);
    final tracker = TrackerController(today: thursday, deck: deck);
    addTearDown(tracker.dispose);

    tracker.selectAmbient(AmbientSound.rain);
    expect(engine.plays, 0);
    tracker.toggleAmbient();
    expect(tracker.ambientPlaying, isTrue);
    expect(deck.nowPlaying, 'ambient-rain');
    expect(engine.plays, 1);

    tracker.selectAmbient(AmbientSound.forest);
    expect(deck.nowPlaying, 'ambient-forest');
    tracker.toggleAmbient();
    expect(tracker.ambientPlaying, isFalse);
    expect(deck.nowPlaying, isNull);
    expect(engine.stops, 1);

    tracker.toggleAmbient();
    expect(engine.plays, 3);
    deck.playLoop('ambient-noise', Uint8List(0));
    expect(deck.nowPlaying, 'ambient-forest');
  });

  test('codex quiz scores by rank and lessons advance', () {
    final codex = AncientCodexController();

    codex.readLesson('scarab');
    expect(codex.lessons.first.progress, 0.25);

    codex.setCategory('Myths');
    expect(codex.lessons, hasLength(15));
    expect(codex.visibleLessons.map((lesson) => lesson.id), [
      'scarab',
      'barque',
      'maat',
      'osiris',
      'isis',
      'desert',
    ]);

    codex.setRank(QuizRank.highPriest);
    codex.startQuiz();
    expect(codex.questions, hasLength(12));
    expect(codex.questions.first.options, hasLength(4));
    while (!codex.quizFinished) {
      codex.chooseAnswer(0);
      codex.advanceQuiz();
    }
    expect(codex.score, 360);
  });

  test('apex recalculates compound growth and stores a note', () {
    final calc = ApexCalcController();

    expect(calc.compounded.round(), 14049);
    calc.setRate(20);
    expect(calc.compounded.round(), 17280);
    expect(calc.converted, closeTo(92, 0.001));

    calc.saveNote('  Mortgage  ');
    expect(calc.history.single.note, 'Mortgage');
    calc.updateNote(0, 'Mortgage, 12%');
    expect(calc.history.single.note, 'Mortgage, 12%');
  });

  testWidgets('zenith habits, timer, and settings respond to taps', (
    tester,
  ) async {
    await tester.pumpWidget(
      AppBrand(
        config: AppBrandConfig.zenithHabits,
        child: MaterialApp(home: NativeDashboardScreen(today: thursday)),
      ),
    );

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Score'), findsOneWidget);
    expect(find.text('Focus'), findsOneWidget);
    expect(find.text('Water'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('habit-morning')),
      300,
    );
    await tester.tap(find.byKey(const Key('habit-morning')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Analytics'));
    await tester.pumpAndSettle();

    expect(find.text('Trend'), findsOneWidget);
    expect(find.text('1 day'), findsOneWidget);

    await tester.tap(find.text('Timer'));
    await tester.pumpAndSettle();
    expect(find.text('25:00'), findsOneWidget);

    await tester.tap(find.byKey(const Key('focus-minutes-15')));
    await tester.pumpAndSettle();
    expect(find.text('15:00'), findsOneWidget);

    await tester.tap(find.byKey(const Key('focus-start')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('14:59'), findsOneWidget);

    await tester.tap(find.byKey(const Key('focus-start')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('open-settings')));
    await tester.pumpAndSettle();
    final settingsScroll = find.descendant(
      of: find.byType(Scaffold).last,
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('Zenith Habits'),
      200,
      scrollable: settingsScroll,
    );
    expect(find.text('About'), findsOneWidget);
    expect(find.text('Zenith Habits'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('notifications-switch')),
      200,
      scrollable: settingsScroll,
    );
    await tester.tap(find.byKey(const Key('notifications-switch')));
    await tester.pump();

    final notifications = tester.widget<SwitchListTile>(
      find.byKey(const Key('notifications-switch')),
    );
    expect(notifications.value, isTrue);
  });

  testWidgets('a fresh progress tab explains an empty history', (tester) async {
    await _pumpBrand(tester, AppBrandConfig.ancientCodex);

    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Your journey begins! Complete lessons and trials to populate your history.',
      ),
      findsOneWidget,
    );
    expect(find.text('Best score: —'), findsOneWidget);
    expect(find.text('Codex opened'), findsNothing);
  });

  testWidgets('ancient codex filters, scores, and opens a glyph', (
    tester,
  ) async {
    await _pumpBrand(tester, AppBrandConfig.ancientCodex);

    expect(find.text('Codex lessons'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.text('Codex lessons')))
          .scaffoldBackgroundColor,
      const Color(0xFF1A0505),
    );

    await tester.tap(find.byKey(const Key('codex-filter-Myths')));
    await tester.pump();
    expect(find.text('House sign'), findsNothing);
    expect(find.text('Scarab and the sun'), findsOneWidget);

    await tester.tap(find.byKey(const Key('read-scarab')));
    await tester.pumpAndSettle();
    expect(find.text('Historical fact'), findsOneWidget);
    expect(find.text('Complete Lesson'), findsOneWidget);
    expect(find.text('25%'), findsNothing);
    await tester.tap(find.byKey(const Key('complete-lesson')));
    await tester.pumpAndSettle();
    expect(find.text('Complete Lesson'), findsNothing);
    expect(find.text('100%'), findsOneWidget);

    await tester.tap(find.text('Trials'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('rank-highPriest')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('daily-challenge')));
    await tester.tap(find.byKey(const Key('daily-challenge')));
    await tester.pump();
    expect(find.text('Done'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('start-quiz')));
    await tester.tap(find.byKey(const Key('start-quiz')));
    await tester.pump();
    for (var step = 0; step < 12; step++) {
      await tester.ensureVisible(find.byKey(const Key('quiz-option-0')));
      await tester.tap(find.byKey(const Key('quiz-option-0')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('quiz-next')));
      await tester.tap(find.byKey(const Key('quiz-next')));
      await tester.pump();
    }
    expect(find.text('Score: 360'), findsOneWidget);

    await tester.tap(find.text('Workshop'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('glyph-0')));
    await tester.tap(find.byKey(const Key('glyph-0')));
    await tester.pump();
    expect(find.text('Protection and wholeness'), findsOneWidget);

    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Lesson read'), findsOneWidget);
    expect(find.text('Lessons: 1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('open-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cubits'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('close-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lessons'));
    await tester.pumpAndSettle();
    expect(find.text('Lengths in cubits'), findsOneWidget);
  });

  testWidgets('apex sliders, currencies, and notes stay in sync', (
    tester,
  ) async {
    await _pumpBrand(tester, AppBrandConfig.apexCalc);

    expect(find.text(formatCount(14049)), findsOneWidget);
    expect(
      Theme.of(tester.element(find.text('Interest and inflation')))
          .scaffoldBackgroundColor,
      const Color(0xFF0A1128),
    );

    tester.widget<Slider>(find.byKey(const Key('apex-rate-slider'))).onChanged!(
      20,
    );
    await tester.pump();
    expect(find.text(formatCount(17280)), findsOneWidget);

    await tester.tap(find.text('Converter'));
    await tester.pumpAndSettle();
    expect(find.text('92.00'), findsOneWidget);
    tester
        .widget<DropdownButton<String>>(find.byKey(const Key('apex-to')))
        .onChanged!('GBP');
    await tester.pump();
    expect(find.text('78.00'), findsOneWidget);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('apex-note')), 'Mortgage');
    await tester.tap(find.byKey(const Key('apex-save')));
    await tester.pump();
    expect(find.text('Mortgage'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('apex-note-0')),
      'Mortgage, 12%',
    );
    await tester.pump();
    expect(find.text('Mortgage, 12%'), findsOneWidget);

    await tester.tap(find.byKey(const Key('open-settings')));
    await tester.pumpAndSettle();
    expect(find.text('About'), findsOneWidget);
    expect(find.text('Apex Calc'), findsOneWidget);
    tester
        .widget<DropdownButton<String>>(find.byKey(const Key('apex-unit')))
        .onChanged!('EUR');
    await tester.pump();
    await tester.tap(find.byKey(const Key('close-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calc'));
    await tester.pumpAndSettle();
    expect(find.text('Ledger currency: EUR'), findsOneWidget);
  });

  testWidgets('brand shells fit a phone width', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final brand in const [
      AppBrandConfig.zenithHabits,
      AppBrandConfig.ancientCodex,
      AppBrandConfig.apexCalc,
    ]) {
      await _pumpBrand(tester, brand);
      await tester.pumpAndSettle();
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    }
  });

  testWidgets('a saved non-english language still draws the shell', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'app.language': 'ru'});
    final text = AppText(await SharedPreferences.getInstance());
    await tester.pumpWidget(
      ChangeNotifierProvider<AppText>.value(
        value: text,
        child: AppBrand(
          config: AppBrandConfig.ancientCodex,
          child: MaterialApp(
            locale: Locale('ru'),
            supportedLocales: AppText.supportedLocales,
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: NativeDashboardScreen(today: thursday),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Уроки'), findsOneWidget);
    expect(find.text('Испытания'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('a removed language code falls back to english', () async {
    SharedPreferences.setMockInitialValues({'app.language': 'uk'});
    final text = AppText(await SharedPreferences.getInstance());
    expect(text.code, 'en');
    expect(text.translate('Lessons'), 'Lessons');
    final stored = (await SharedPreferences.getInstance()).getString(
      AppText.storageKey,
    );
    expect(stored, 'en');
  });

  testWidgets('german draws the lesson shell in german', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'app.language': 'de'});
    final text = AppText(await SharedPreferences.getInstance());

    Future<void> pump(AppBrandConfig brand) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<AppText>.value(
          value: text,
          child: AppBrand(
            config: brand,
            child: MaterialApp(
              locale: const Locale('de'),
              supportedLocales: AppText.supportedLocales,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: NativeDashboardScreen(today: thursday),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    await pump(AppBrandConfig.ancientCodex);
    expect(find.text('Lektionen'), findsOneWidget);
    expect(find.text('Prüfungen'), findsOneWidget);
    expect(find.text('Skarabäus und die Sonne'), findsOneWidget);
    expect(find.text('Lesen'), findsWidgets);

    await pump(AppBrandConfig.zenithHabits);
    expect(find.text('Tag'), findsOneWidget);
    expect(find.text('Gewohnheiten'), findsWidgets);

    await pump(AppBrandConfig.apexCalc);
    expect(find.text('Rechner'), findsOneWidget);
    expect(find.text('Betrag'), findsOneWidget);
  });
}

Future<void> _pumpBrand(WidgetTester tester, AppBrandConfig brand) {
  return tester.pumpWidget(
    AppBrand(
      config: brand,
      child: MaterialApp(
        home: NativeDashboardScreen(today: DateTime(2026, 10, 8)),
      ),
    ),
  );
}

class _MemorySoundEngine implements SoundEngine {
  int plays = 0;
  int stops = 0;

  @override
  void play(Uint8List bytes, {required bool loop, void Function()? onEnded}) {
    plays++;
  }

  @override
  void stop() {
    stops++;
  }

  @override
  void dispose() {}
}
