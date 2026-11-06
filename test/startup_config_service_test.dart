import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hybrid_app/core/config/app_config.dart';
import 'package:hybrid_app/modules/remote_config/data/memory_remote_config_store.dart';
import 'package:hybrid_app/modules/remote_config/data/startup_config_service.dart';

void main() {
  const configUrl = 'https://api.example.com/v1/remote-config';

  test('a debug session stays native and does not call the network', () async {
    var calls = 0;
    final store = MemoryRemoteConfigStore();
    final service = startupConfigService(
      configUrl: Uri.parse(configUrl),
      client: MockClient((_) async {
        calls += 1;
        return http.Response('{"isDynamicContentEnabled":true}', 200);
      }),
      store: store,
    );

    final config = await service.fetch();

    expect(service, isA<LocalDebugConfigService>());
    expect(calls, 0);
    expect(await store.read(), isNull);
    expect(config.isDynamicContentEnabled, isFalse);
    expect(config.displayMode, AppDisplayMode.standard);
    expect(config.userCategory, UserCategory.defaultUser);
    expect(config.webUri, isNull);
  });

  test('a release session stays native and does not call the network', () async {
    var calls = 0;
    final store = MemoryRemoteConfigStore();
    final service = startupConfigService(
      configUrl: Uri.parse(configUrl),
      client: MockClient((request) async {
        calls += 1;
        return http.Response(
          '{"isDynamicContentEnabled":true,"targetUrl":"https://app.example.com/home"}',
          200,
        );
      }),
      store: store,
      debugMode: false,
    );

    final config = await service.fetch();

    expect(service, isA<LocalDebugConfigService>());
    expect(calls, 0);
    expect(config.isDynamicContentEnabled, isFalse);
    expect(config.webUri, isNull);
    expect(await store.read(), isNull);
  });
}
