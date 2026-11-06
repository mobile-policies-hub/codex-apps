import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hybrid_app/app/app_scope.dart';
import 'package:hybrid_app/app/hybrid_app.dart';
import 'package:hybrid_app/core/config/api_config.dart';
import 'package:hybrid_app/core/config/app_brand_config.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/native_dashboard_screen.dart';
import 'package:hybrid_app/modules/notifications/presentation/push_notification_service.dart';
import 'package:provider/provider.dart';
import 'package:hybrid_app/modules/remote_config/data/memory_remote_config_store.dart';
import 'package:hybrid_app/modules/remote_config/domain/remote_config_store.dart';
import 'package:hybrid_app/modules/web_container/presentation/web_container_screen.dart';
import 'package:hybrid_app/modules/web_container/presentation/web_document_scope.dart';

void main() {
  const configUrl = 'https://api.example.com/v1/remote-config';

  Future<void> pumpApp(
    WidgetTester tester, {
    required Future<http.Response> Function(http.Request request) handler,
    RemoteConfigStore? configStore,
    Key? scopeKey,
  }) {
    return tester.pumpWidget(
      WebDocumentScope(
        builder: (_) => const SizedBox(key: Key('web-document-stub')),
        child: AppScope(
          key: scopeKey,
          config: ApiConfig(remoteConfigUri: Uri.parse(configUrl)),
          configStore: configStore ?? MemoryRemoteConfigStore(),
          httpClient: MockClient(handler),
          child: const HybridApp(),
        ),
      ),
    );
  }

  testWidgets('shows a loading indicator until the local session resolves', (
    tester,
  ) async {
    var calls = 0;
    await pumpApp(
      tester,
      handler: (_) {
        calls += 1;
        return Completer<http.Response>().future;
      },
    );

    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    expect(find.byType(WebContainerScreen), findsNothing);
    expect(find.byType(NativeDashboardScreen), findsNothing);

    await tester.pump();

    expect(calls, 0);
    expect(find.byType(NativeDashboardScreen), findsOneWidget);
    expect(find.byType(WebContainerScreen), findsNothing);
    expect(find.text('https://app.example.com/home'), findsNothing);
  });

  testWidgets('opens the native dashboard when web is disabled', (
    tester,
  ) async {
    await pumpApp(
      tester,
      handler: (_) async => http.Response(
        jsonEncode({
          'isDynamicContentEnabled': false,
          'targetUrl': 'https://app.example.com',
        }),
        200,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(NativeDashboardScreen), findsOneWidget);
    expect(
      find.text(AppBrandConfig.current.nativeDashboardTitle),
      findsOneWidget,
    );
    expect(find.byType(WebContainerScreen), findsNothing);
    final push = Provider.of<PushNotificationService>(
      tester.element(find.byType(NativeDashboardScreen)),
      listen: false,
    );
    expect(push.userTags, {'user_type': 'defaultUser', 'mode': 'standard'});
  });

  testWidgets('opens the native dashboard when the request fails', (
    tester,
  ) async {
    await pumpApp(
      tester,
      handler: (_) async => http.Response('unavailable', 503),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byType(NativeDashboardScreen), findsOneWidget);
    expect(find.byType(WebContainerScreen), findsNothing);
  });

  testWidgets('a debug launch stays native and does not request config', (
    tester,
  ) async {
    var calls = 0;
    final store = MemoryRemoteConfigStore();
    await pumpApp(
      tester,
      configStore: store,
      handler: (_) async {
        calls += 1;
        return http.Response(
          jsonEncode({
            'isDynamicContentEnabled': true,
            'targetUrl': 'https://app.example.com/home',
          }),
          200,
        );
      },
    );
    await tester.pump();
    await tester.pump();

    expect(calls, 0);
    expect(await store.read(), isNull);
    expect(find.byType(NativeDashboardScreen), findsOneWidget);
    expect(find.byType(WebContainerScreen), findsNothing);

    await pumpApp(
      tester,
      scopeKey: const ValueKey('offline-relaunch'),
      configStore: store,
      handler: (_) async {
        calls += 1;
        throw http.ClientException('offline');
      },
    );
    await tester.pump();
    await tester.pump();

    expect(calls, 0);
    expect(find.byType(NativeDashboardScreen), findsOneWidget);
    expect(find.byType(WebContainerScreen), findsNothing);
    expect(find.text('https://app.example.com/home'), findsNothing);
  });
}
