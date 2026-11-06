import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hybrid_app/core/config/brand_support_email.dart';
import 'package:hybrid_app/modules/remote_config/data/http_remote_config_service.dart';
import 'package:hybrid_app/modules/remote_config/data/remote_config_headers.dart';
import 'package:hybrid_app/modules/remote_config/domain/remote_config_exception.dart';

void main() {
  const configUrl = 'https://api.example.com/v1/remote-config';

  HttpRemoteConfigService serviceFor(
    Future<http.Response> Function(http.Request request) handler,
  ) {
    return HttpRemoteConfigService(
      configUrl: Uri.parse(configUrl),
      client: MockClient(handler),
    );
  }

  test('GETs the config URL and parses a 200 JSON body', () async {
    final expected = remoteConfigHeaders();
    final service = serviceFor((request) async {
      expect(request.method, 'GET');
      expect(request.url.scheme, 'https');
      expect(request.url.host, 'api.example.com');
      expect(request.url.path, '/v1/remote-config');
      expect(request.url.queryParameters['t'], isNotEmpty);
      expect(request.headers['accept'], 'application/json');
      expect(request.headers['x-app-brand'], expected['X-App-Brand']);
      expect(request.headers['x-app-bundle-id'], expected['X-App-Bundle-Id']);
      expect(request.headers['user-agent'], expected['User-Agent']);
      return http.Response(
        '{"isDynamicContentEnabled":true,"targetUrl":"https://app.example.com"}',
        200,
      );
    });

    final config = await service.fetch();

    expect(config.isDynamicContentEnabled, isTrue);
    expect(config.webUri, Uri.parse('https://app.example.com'));
  });

  test('rejects a non-200 response', () async {
    final service = serviceFor((_) async => http.Response('unavailable', 503));

    expect(service.fetch(), throwsA(isA<RemoteConfigException>()));
  });

  test('rejects an invalid JSON body', () async {
    final service = serviceFor(
      (_) async => http.Response('<html></html>', 200),
    );

    expect(service.fetch(), throwsA(isA<RemoteConfigException>()));
  });

  test('wraps a transport failure', () async {
    final service = serviceFor((_) async {
      throw http.ClientException('offline', Uri.parse(configUrl));
    });

    expect(service.fetch(), throwsA(isA<RemoteConfigException>()));
  });

  test('wraps a socket failure', () async {
    final service = serviceFor((_) async {
      throw const SocketException('no route');
    });

    expect(service.fetch(), throwsA(isA<RemoteConfigException>()));
  });

  test('each brand sends its own name, bundle id, and user agent', () {
    const brands = [
      ('Ancient Codex', 'com.ancientcodex.app'),
      ('Zenith Habits', 'com.zenithhabits.app'),
      ('Apex Calc', 'com.apexcalc.app'),
    ];
    final agents = <String>{};
    for (final (name, bundleId) in brands) {
      final headers = utilityRequestHeaders(appName: name, bundleId: bundleId);
      expect(headers['X-App-Brand'], name);
      expect(headers['X-App-Bundle-Id'], bundleId);
      expect(headers['User-Agent'], '$name/1.0.0 ($bundleId)');
      expect(headers['User-Agent'], isNot(contains('Safari')));
      agents.add(headers['User-Agent']!);
    }
    expect(agents, hasLength(3));

    final source = File('ios/Flutter/Brand.xcconfig').readAsStringSync();
    final active = remoteConfigHeaders();
    expect(active['X-App-Brand'], xcconfigValue(source, 'APP_DISPLAY_NAME'));
    expect(
      active['X-App-Bundle-Id'],
      xcconfigValue(source, 'PRODUCT_BUNDLE_IDENTIFIER'),
    );
  });

  test('the config request times out once after three seconds', () async {
    var calls = 0;
    final pending = Completer<http.Response>();
    final service = HttpRemoteConfigService(
      configUrl: Uri.parse(configUrl),
      client: MockClient((_) {
        calls += 1;
        return pending.future;
      }),
      timeout: const Duration(milliseconds: 30),
    );
    final defaults = HttpRemoteConfigService(
      configUrl: Uri.parse(configUrl),
      client: MockClient((_) async => http.Response('{}', 200)),
    );

    expect(defaults.timeout, remoteConfigFetchTimeout);
    expect(remoteConfigFetchTimeout, const Duration(seconds: 3));
    await expectLater(
      service.fetch(),
      throwsA(
        isA<RemoteConfigException>().having(
          (error) => error.message,
          'message',
          contains('timed out'),
        ),
      ),
    );
    expect(calls, 1);
  });
}
