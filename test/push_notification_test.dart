import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:hybrid_app/app/hybrid_app.dart';
import 'package:hybrid_app/core/config/app_brand_config.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/native_dashboard_screen.dart';
import 'package:hybrid_app/modules/notifications/domain/push_backend.dart';
import 'package:hybrid_app/modules/notifications/domain/push_payload.dart';
import 'package:hybrid_app/modules/notifications/presentation/push_notification_service.dart';
import 'package:hybrid_app/modules/notifications/presentation/push_preview_layer.dart';
import 'package:hybrid_app/modules/notifications/presentation/push_soft_prompt.dart';
import 'package:hybrid_app/modules/remote_config/domain/remote_config.dart';
import 'package:hybrid_app/modules/remote_config/domain/remote_config_service.dart';
import 'package:hybrid_app/modules/routing/domain/resolve_launch_destination.dart';
import 'package:hybrid_app/modules/routing/presentation/launch_controller.dart';
import 'package:hybrid_app/modules/web_container/presentation/web_container_screen.dart';
import 'package:hybrid_app/modules/web_container/presentation/web_document_scope.dart';

void main() {
  test('initialize does not ask for permission', () async {
    final backend = LocalPushBackend();
    final push = PushNotificationService(backend: backend);

    await push.initialize();
    await push.initialize();

    expect(push.permission, PushPermission.unknown);
    expect(backend.permissionRequested, isFalse);
    expect(createPushBackend(), isA<LocalPushBackend>());
    expect(createPushBackend(appId: 'onesignal-app').appId, 'onesignal-app');
    expect(createPushBackend(appId: 'onesignal-app'), isA<RemotePushBackend>());
  });

  test('updateUserSegment tags web and native audiences', () async {
    final backend = LocalPushBackend();
    final push = PushNotificationService(backend: backend);

    await push.updateUserSegment(isDynamicContentEnabled: true, geo: ' DE ');
    expect(push.userTags, {
      'user_type': 'primaryUser',
      'mode': 'extended',
      'geo': 'DE',
    });
    expect(backend.tags, push.userTags);

    await push.updateUserSegment(isDynamicContentEnabled: false, geo: '   ');
    expect(push.isDynamicContentEnabled, isFalse);
    expect(push.userTags, {'user_type': 'defaultUser', 'mode': 'standard'});
    expect(backend.tags.containsKey('geo'), isFalse);
  });

  test(
    'a remote backend sends each tag through OneSignal.User.addTag',
    () async {
      final sent = <MapEntry<String, String>>[];
      final backend = RemotePushBackend(
        'onesignal-app',
        userTags: _RecordingTags(sent),
      );
      final push = PushNotificationService(backend: backend);

      await push.updateUserSegment(isDynamicContentEnabled: true);

      expect(Map.fromEntries(sent), {
        'user_type': 'primaryUser',
        'mode': 'extended',
      });
    },
  );

  test('a web link opens the container only while web mode is on', () {
    const link = 'https://push.example.com/inbox';

    expect(
      pushWebUri(isDynamicContentEnabled: true, payload: link),
      Uri.parse(link),
    );
    expect(pushWebUri(isDynamicContentEnabled: false, payload: link), isNull);
    expect(
      pushWebUri(isDynamicContentEnabled: true, payload: 'habits'),
      isNull,
    );
    expect(nativeSectionFor('habits'), NativePushSection.habitList);
    expect(nativeSectionFor(link), NativePushSection.habitList);
    expect(
      nativeSectionFor('https://push.example.com/quiz'),
      NativePushSection.dailyQuiz,
    );
    expect(nativeSectionFor('trials'), NativePushSection.dailyQuiz);
  });

  testWidgets('the soft prompt gates the system permission request', (
    tester,
  ) async {
    final backend = LocalPushBackend();
    final push = PushNotificationService(backend: backend);
    addTearDown(push.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                final agreed = await showNotificationSoftPrompt(context);
                if (!agreed) return;
                await push.requestPermission();
              },
              child: const Text('Enable'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Enable'));
    await tester.pumpAndSettle();
    expect(find.text('Allow alerts?'), findsOneWidget);
    expect(backend.permissionRequested, isFalse);

    await tester.tap(find.byKey(const Key('push-soft-deny')));
    await tester.pumpAndSettle();
    expect(backend.permissionRequested, isFalse);
    expect(push.permission, PushPermission.unknown);

    await tester.tap(find.text('Enable'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('push-soft-allow')));
    await tester.pumpAndSettle();
    expect(backend.permissionRequested, isTrue);
    expect(push.permission, PushPermission.granted);
  });

  testWidgets('a tapped test alert opens the habit list', (tester) async {
    final push = PushNotificationService();
    addTearDown(push.dispose);
    final thursday = DateTime(2026, 10, 8);

    await tester.pumpWidget(
      AppBrand(
        config: AppBrandConfig.zenithHabits,
        child: ChangeNotifierProvider<PushNotificationService>.value(
          value: push,
          child: MaterialApp(
            home: PushPreviewLayer(
              child: NativeDashboardScreen(today: thursday),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Timer'));
    await tester.pumpAndSettle();
    expect(find.text('25:00'), findsOneWidget);

    push.onNotificationOpened('habits');
    await tester.pump();
    await tester.pump();

    expect(find.text('25:00'), findsNothing);
    expect(find.text('Habits'), findsOneWidget);
    expect(push.nativeDestination(), NativePushSection.habitList);
  });

  testWidgets('a quiz payload opens the daily challenge', (tester) async {
    final push = PushNotificationService();
    addTearDown(push.dispose);

    await tester.pumpWidget(
      AppBrand(
        config: AppBrandConfig.ancientCodex,
        child: ChangeNotifierProvider<PushNotificationService>.value(
          value: push,
          child: MaterialApp(
            home: NativeDashboardScreen(today: DateTime(2026, 10, 8)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Daily challenge'), findsNothing);
    push.onNotificationOpened('quiz');
    await tester.pump();
    await tester.pump();

    expect(find.text('Daily challenge'), findsOneWidget);
    expect(find.text('Codex lessons'), findsNothing);
  });

  testWidgets('settings ask before enabling and the alert opens habits', (
    tester,
  ) async {
    final backend = LocalPushBackend();
    final push = PushNotificationService(backend: backend);
    addTearDown(push.dispose);

    await tester.pumpWidget(
      AppBrand(
        config: AppBrandConfig.zenithHabits,
        child: ChangeNotifierProvider<PushNotificationService>.value(
          value: push,
          child: MaterialApp(
            home: PushPreviewLayer(
              child: NativeDashboardScreen(today: DateTime(2026, 10, 8)),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open-settings')));
    await tester.pumpAndSettle();
    final settingsScroll = find.descendant(
      of: find.byType(Scaffold).last,
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('notifications-switch')),
      200,
      scrollable: settingsScroll,
    );
    await tester.tap(find.byKey(const Key('notifications-switch')));
    await tester.pump();

    var notifications = tester.widget<SwitchListTile>(
      find.byKey(const Key('notifications-switch')),
    );
    expect(notifications.value, isFalse);
    expect(find.text('Allow alerts?'), findsNothing);

    await tester.tap(find.byKey(const Key('notifications-switch')));
    await tester.pumpAndSettle();
    expect(find.text('Allow alerts?'), findsOneWidget);
    expect(backend.permissionRequested, isFalse);

    await tester.tap(find.byKey(const Key('push-soft-deny')));
    await tester.pumpAndSettle();
    notifications = tester.widget<SwitchListTile>(
      find.byKey(const Key('notifications-switch')),
    );
    expect(notifications.value, isFalse);

    await tester.tap(find.byKey(const Key('notifications-switch')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('push-soft-allow')));
    await tester.pumpAndSettle();
    notifications = tester.widget<SwitchListTile>(
      find.byKey(const Key('notifications-switch')),
    );
    expect(notifications.value, isTrue);
    expect(push.permission, PushPermission.granted);

    await tester.scrollUntilVisible(
      find.byKey(const Key('send-test-notification')),
      200,
      scrollable: settingsScroll,
    );
    await tester.tap(find.byKey(const Key('send-test-notification')));
    await tester.pump();
    expect(find.text('Habit reminder'), findsOneWidget);
    expect(find.text('Open your habit list'), findsOneWidget);

    await tester.tap(find.byKey(const Key('local-notification')));
    await tester.pumpAndSettle();

    expect(find.text('Send a test alert'), findsNothing);
    expect(find.text('Habits'), findsOneWidget);
  });

  testWidgets('a web-mode click loads the payload URL', (tester) async {
    final controller = LaunchController(
      ResolveLaunchDestination(
        _FixedRemoteConfig(
          const RemoteConfig(
            isDynamicContentEnabled: true,
            targetUrl: 'https://app.example.com/home',
          ),
        ),
      ),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      WebDocumentScope(
        builder: (_) => const SizedBox(key: Key('web-document-stub')),
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider<LaunchController>.value(value: controller),
            ChangeNotifierProvider(create: (_) => PushNotificationService()),
          ],
          child: const HybridApp(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('https://app.example.com/home'), findsOneWidget);
    final push = Provider.of<PushNotificationService>(
      tester.element(find.byType(WebContainerScreen)),
      listen: false,
    );
    expect(push.isDynamicContentEnabled, isTrue);
    expect(push.userTags, {'user_type': 'primaryUser', 'mode': 'extended'});

    const payload = 'https://push.example.com/inbox';
    push.onNotificationOpened(payload);
    await tester.pump();

    expect(find.text(payload), findsOneWidget);
    expect(find.text('https://app.example.com/home'), findsNothing);
    expect(find.byType(WebContainerScreen), findsOneWidget);
  });
}

class _FixedRemoteConfig implements RemoteConfigService {
  const _FixedRemoteConfig(this.config);

  final RemoteConfig config;

  @override
  Future<RemoteConfig> fetch() async => config;
}

class _RecordingTags implements PushUserTags {
  _RecordingTags(this.sent);

  final List<MapEntry<String, String>> sent;

  @override
  Future<void> addTag(String key, String value) async {
    sent.add(MapEntry(key, value));
  }
}
