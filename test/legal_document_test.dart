import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hybrid_app/core/config/app_brand_config.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/legal_document.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/native_dashboard_screen.dart';
import 'package:hybrid_app/modules/web_container/presentation/web_document_scope.dart';
import 'package:hybrid_app/modules/web_container/presentation/web_view_hooks.dart';

void main() {
  test('privacy and terms name the brand and its support address', () {
    const brands = [
      AppBrandConfig.ancientCodex,
      AppBrandConfig.zenithHabits,
      AppBrandConfig.apexCalc,
    ];
    for (final brand in brands) {
      for (final document in LegalDocument.values) {
        final html = legalDocumentHtml(brand, document);
        expect(html, contains('<!DOCTYPE html>'));
        expect(html, contains(legalDocumentTitle(document)));
        expect(html, contains(brand.appName));
        expect(html, contains(brand.supportEmail));
        if (document == LegalDocument.privacy) {
          expect(html, contains('does not sell personal information'));
          final russian = legalDocumentHtml(brand, document, language: 'ru');
          switch (brand.id) {
            case AppBrandId.ancientCodex:
              expect(html.toLowerCase(), isNot(contains('calculator')));
              expect(html.toLowerCase(), isNot(contains('habit')));
              expect(russian, isNot(contains('калькулятор')));
              expect(russian, isNot(contains('привыч')));
            case AppBrandId.zenithHabits:
              expect(html, contains('habit checkmarks'));
              expect(html.toLowerCase(), isNot(contains('calculator')));
              expect(russian, isNot(contains('калькулятор')));
              expect(russian, isNot(contains('урок')));
            case AppBrandId.apexCalc:
              expect(html, contains('sample rates for reference only'));
              expect(html.toLowerCase(), isNot(contains('lesson')));
              expect(html.toLowerCase(), isNot(contains('habit')));
          }
        } else {
          switch (brand.id) {
            case AppBrandId.ancientCodex:
              expect(html, contains('not a certified course'));
              expect(html.toLowerCase(), isNot(contains('calculator')));
              expect(html.toLowerCase(), isNot(contains('habit')));
            case AppBrandId.zenithHabits:
              expect(html, contains('not medical advice'));
              expect(html.toLowerCase(), isNot(contains('calculator')));
              expect(html.toLowerCase(), isNot(contains('lesson')));
            case AppBrandId.apexCalc:
              expect(html, contains('not financial, tax, or investment advice'));
              expect(html.toLowerCase(), isNot(contains('lesson')));
              expect(html.toLowerCase(), isNot(contains('habit')));
          }
        }
      }
    }

    const marked = AppBrandConfig(
      appName: 'A & B <notes>',
      supportEmail: 'a&b@example.com',
      primaryColor: Color(0xFF112233),
      nativeDashboardTitle: 'Notes',
    );
    final escaped = legalDocumentHtml(marked, LegalDocument.privacy);
    expect(escaped, contains('A &amp; B &lt;notes&gt;'));
    expect(escaped, contains('a&amp;b@example.com'));
    expect(escaped, isNot(contains('<notes>')));
  });

  testWidgets('settings opens privacy and terms in the in-app web view', (
    tester,
  ) async {
    late WebViewHooks hooks;
    await tester.pumpWidget(
      WebDocumentScope(
        builder: (value) {
          hooks = value;
          return const SizedBox(key: Key('legal-webview'));
        },
        child: const AppBrand(
          config: AppBrandConfig.ancientCodex,
          child: MaterialApp(home: NativeDashboardScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _openLegalPage(
      tester,
      button: const Key('privacy-policy'),
      title: 'Privacy Policy',
    );
    expect(find.byKey(const Key('legal-webview')), findsOneWidget);
    expect(find.byKey(const Key('inapp-webview')), findsNothing);
    expect(hooks.html, contains('Ancient Codex'));
    expect(hooks.html, contains('dev.outbox.88@outlook.com'));
    expect(hooks.html, contains('Privacy Policy'));
    expect(hooks.html, isNot(contains('alculator')));
    expect(hooks.html, isNot(contains('abit')));
    expect(
      tester.widget<Text>(find.byKey(const Key('web-url'))).data,
      'Privacy Policy',
    );

    await tester.tap(find.byKey(const Key('web-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('legal-webview')), findsNothing);

    await _openLegalPage(
      tester,
      button: const Key('terms-of-service'),
      title: 'Terms of Service',
    );
    expect(hooks.html, contains('Terms of Service'));
    expect(hooks.html, contains('not a certified course'));
    expect(hooks.html, isNot(contains('alculator')));
    expect(hooks.html, contains('Ancient Codex'));
    expect(
      tester.widget<Text>(find.byKey(const Key('web-url'))).data,
      'Terms of Service',
    );
  });
}

Future<void> _openLegalPage(
  WidgetTester tester, {
  required Key button,
  required String title,
}) async {
  if (find.byKey(const Key('privacy-policy')).evaluate().isEmpty) {
    await tester.tap(find.byKey(const Key('open-settings')));
    await tester.pumpAndSettle();
  }
  final settingsScroll = find.descendant(
    of: find.byType(Scaffold).last,
    matching: find.byType(Scrollable),
  );
  await tester.scrollUntilVisible(
    find.byKey(button),
    200,
    scrollable: settingsScroll,
  );
  await tester.tap(find.byKey(button));
  await tester.pumpAndSettle();
  expect(find.text(title), findsWidgets);
}
