import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hybrid_app/core/config/web_document_config.dart';
import 'package:hybrid_app/modules/web_container/presentation/persistent_web_settings.dart';
import 'package:hybrid_app/modules/web_container/presentation/web_container_screen.dart';
import 'package:hybrid_app/modules/web_container/presentation/web_document_scope.dart';
import 'package:hybrid_app/modules/web_container/presentation/web_load_policy.dart';
import 'package:hybrid_app/modules/web_container/presentation/web_view_hooks.dart';

void main() {
  const page = 'https://app.example.com/home';

  Future<WebViewHooks> pumpContainer(WidgetTester tester) async {
    late WebViewHooks hooks;
    await tester.pumpWidget(
      MaterialApp(
        home: WebDocumentScope(
          builder: (value) {
            hooks = value;
            return const SizedBox(key: Key('web-document-stub'));
          },
          child: WebContainerScreen(targetUrl: Uri.parse(page)),
        ),
      ),
    );
    return hooks;
  }

  test('document settings keep scripts, storage, and cookies', () {
    final settings = persistentDocumentSettings();

    expect(settings.javaScriptEnabled, isTrue);
    expect(settings.domStorageEnabled, isTrue);
    expect(settings.databaseEnabled, isTrue);
    expect(settings.cacheEnabled, isTrue);
    expect(settings.incognito, isFalse);
    expect(settings.sharedCookiesEnabled, isTrue);
    expect(settings.thirdPartyCookiesEnabled, isTrue);
    expect(settings.allowsBackForwardNavigationGestures, isTrue);
    expect(settings.limitsNavigationsToAppBoundDomains, isFalse);
    expect(settings.disableDefaultErrorPage, isTrue);
    expect(settings.allowsInlineMediaPlayback, isTrue);
    expect(settings.mediaPlaybackRequiresUserGesture, isFalse);
    expect(settings.useShouldOverrideUrlLoading, isTrue);
    expect(settings.userAgent, defaultIosSafariUserAgent);
  });

  test('a custom user agent replaces the Safari default', () {
    const agent = 'HybridApp/1.0';
    final settings = persistentDocumentSettings(userAgent: agent);
    final headers = const WebDocumentConfig(
      userAgent: agent,
      headers: {'Accept-Language': 'en-US'},
    ).requestHeaders();

    expect(settings.userAgent, agent);
    expect(headers['User-Agent'], agent);
    expect(headers['Accept-Language'], 'en-US');
  });

  test('offline screen is reserved for the main document', () {
    expect(
      shouldPresentLoadError(
        isForMainFrame: true,
        type: WebResourceErrorType.NOT_CONNECTED_TO_INTERNET,
      ),
      isTrue,
    );
    expect(
      shouldPresentLoadError(
        isForMainFrame: false,
        type: WebResourceErrorType.NOT_CONNECTED_TO_INTERNET,
      ),
      isFalse,
    );
    expect(
      shouldPresentLoadError(
        isForMainFrame: true,
        type: WebResourceErrorType.CANCELLED,
      ),
      isFalse,
    );
  });

  testWidgets('shows a loading card and the address until the page advances', (
    tester,
  ) async {
    final hooks = await pumpContainer(tester);

    expect(find.byKey(const Key('web-loading')), findsOneWidget);
    expect(find.text('Opening the page'), findsOneWidget);
    expect(find.text(page), findsOneWidget);
    expect(find.byKey(const Key('web-progress')), findsNothing);

    hooks.onProgress!(40);
    await tester.pump();

    expect(find.byKey(const Key('web-loading')), findsNothing);
    expect(find.byKey(const Key('web-progress')), findsOneWidget);

    hooks.onPageFinished!(Uri.parse('https://app.example.com/next'));
    await tester.pump();

    expect(find.text('https://app.example.com/next'), findsOneWidget);
    expect(find.byKey(const Key('web-progress')), findsNothing);
  });

  testWidgets('shows an offline screen and retries the document', (
    tester,
  ) async {
    final hooks = await pumpContainer(tester);
    var reloads = 0;
    hooks.attachControls(
      reload: () async => reloads += 1,
      goBack: () async {},
      goForward: () async {},
    );

    hooks.onMainFrameError!('The Internet connection appears to be offline.');
    await tester.pump();

    expect(find.byKey(const Key('web-offline')), findsOneWidget);
    expect(find.text('No connection'), findsOneWidget);
    expect(
      find.text('The Internet connection appears to be offline.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('web-loading')), findsNothing);

    await tester.tap(find.byKey(const Key('web-retry')));
    await tester.pump();

    expect(reloads, 1);
    expect(find.byKey(const Key('web-offline')), findsNothing);
    expect(find.byKey(const Key('web-loading')), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('enables back and forward only when history allows it', (
    tester,
  ) async {
    final hooks = await pumpContainer(tester);
    var backs = 0;
    var forwards = 0;
    hooks.attachControls(
      reload: () async {},
      goBack: () async => backs += 1,
      goForward: () async => forwards += 1,
    );

    expect(
      tester.widget<IconButton>(find.byKey(const Key('web-back'))).onPressed,
      isNull,
    );
    expect(
      tester.widget<IconButton>(find.byKey(const Key('web-forward'))).onPressed,
      isNull,
    );

    hooks.onNavigationState!(canGoBack: true, canGoForward: false);
    await tester.pump();
    await tester.tap(find.byKey(const Key('web-back')));
    await tester.pump();

    expect(backs, 1);
    expect(forwards, 0);
    expect(
      tester.widget<IconButton>(find.byKey(const Key('web-forward'))).onPressed,
      isNull,
    );
  });
}
