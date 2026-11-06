import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hybrid_app/modules/web_container/presentation/web_navigation_policy.dart';

void main() {
  test('http and https stay inside the web view', () async {
    final opened = <Uri>[];
    for (final raw in [
      'https://app.example.com/home',
      'http://localhost:8080/preview',
      'about:blank',
    ]) {
      final policy = await resolveNavigationPolicy(
        url: Uri.parse(raw),
        openExternal: (uri) async {
          opened.add(uri);
          return true;
        },
      );
      expect(policy, NavigationActionPolicy.ALLOW, reason: raw);
    }
    expect(opened, isEmpty);
  });

  test(
    'custom schemes are opened by the system and cancelled in the web view',
    () async {
      final opened = <String>[];
      const targets = [
        'tg://resolve?domain=example',
        'whatsapp://send?text=hello',
        'mailto:person@example.com',
        'tel:+79990000000',
        'intent://scan/#Intent;scheme=zxing;end',
      ];

      for (final raw in targets) {
        final policy = await resolveNavigationPolicy(
          url: Uri.parse(raw),
          openExternal: (uri) async {
            opened.add(uri.toString());
            return true;
          },
        );
        expect(policy, NavigationActionPolicy.CANCEL, reason: raw);
      }

      expect(opened, [for (final raw in targets) Uri.parse(raw).toString()]);
    },
  );

  test(
    'a scheme the system cannot open is still kept out of the web view',
    () async {
      final policy = await resolveNavigationPolicy(
        url: Uri.parse('tg://resolve?domain=example'),
        openExternal: (_) async => throw Exception('not installed'),
      );

      expect(policy, NavigationActionPolicy.CANCEL);
    },
  );
}
