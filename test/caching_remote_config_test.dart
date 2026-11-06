import 'package:flutter_test/flutter_test.dart';
import 'package:hybrid_app/modules/remote_config/data/caching_remote_config_service.dart';
import 'package:hybrid_app/modules/remote_config/data/memory_remote_config_store.dart';
import 'package:hybrid_app/modules/remote_config/data/remote_config_parser.dart';
import 'package:hybrid_app/modules/remote_config/data/shared_preferences_remote_config_store.dart';
import 'package:hybrid_app/modules/remote_config/domain/remote_config.dart';
import 'package:hybrid_app/modules/remote_config/domain/remote_config_exception.dart';
import 'package:hybrid_app/modules/remote_config/domain/remote_config_service.dart';
import 'package:hybrid_app/modules/remote_config/domain/remote_config_store.dart';
import 'package:hybrid_app/modules/routing/domain/launch_resolution.dart';
import 'package:hybrid_app/modules/routing/domain/resolve_launch_destination.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const saved = RemoteConfig(
    isDynamicContentEnabled: true,
    targetUrl: 'https://cached.example.com/home',
  );

  test('persists the last successful payload on disk', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final store = SharedPreferencesRemoteConfigStore(preferences);

    expect(await store.read(), isNull);

    await store.write(saved);
    final restored = await store.read();

    expect(restored?.isDynamicContentEnabled, isTrue);
    expect(restored?.webUri, Uri.parse('https://cached.example.com/home'));
    expect(
      preferences.getString(SharedPreferencesRemoteConfigStore.storageKey),
      isNotNull,
    );
  });

  test('a corrupt saved payload is treated as empty', () async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesRemoteConfigStore.storageKey: 'not-json',
    });
    final preferences = await SharedPreferences.getInstance();
    final store = SharedPreferencesRemoteConfigStore(preferences);

    expect(await store.read(), isNull);
  });

  test('network failure does not reopen a saved web target', () async {
    final store = MemoryRemoteConfigStore()..value = saved;
    final service = CachingRemoteConfigService(
      origin: _ScriptedService(
        () async => throw const RemoteConfigException('offline'),
      ),
      store: store,
    );

    expect(service.fetch(), throwsA(isA<RemoteConfigException>()));
    expect(store.value, same(saved));
    expect(saved.webUri, isNotNull);
  });

  test('network failure without a saved config stays a failure', () async {
    final service = CachingRemoteConfigService(
      origin: _ScriptedService(
        () async => throw const RemoteConfigException('offline'),
      ),
      store: MemoryRemoteConfigStore(),
    );

    expect(service.fetch(), throwsA(isA<RemoteConfigException>()));
  });

  test('a failed read of storage still surfaces the network error', () async {
    final service = CachingRemoteConfigService(
      origin: _ScriptedService(
        () async => throw const RemoteConfigException('offline'),
      ),
      store: _BrokenStore(),
    );

    expect(service.fetch(), throwsA(isA<RemoteConfigException>()));
  });

  test('startup stays native when the network fails', () async {
    final store = MemoryRemoteConfigStore()..value = saved;
    final resolution = await ResolveLaunchDestination(
      CachingRemoteConfigService(
        origin: _ScriptedService(
          () async => throw const RemoteConfigException('timeout'),
        ),
        store: store,
      ),
    ).call();

    expect(resolution, isA<NativeLaunch>());
    expect((resolution as NativeLaunch).cause, isA<RemoteConfigException>());
    expect(store.value?.isDynamicContentEnabled, isTrue);
  });

  test('startup opens the native dashboard when nothing is saved', () async {
    final resolution = await ResolveLaunchDestination(
      CachingRemoteConfigService(
        origin: _ScriptedService(
          () async => throw const RemoteConfigException('timeout'),
        ),
        store: MemoryRemoteConfigStore(),
      ),
    ).call();

    expect(resolution, isA<NativeLaunch>());
    expect((resolution as NativeLaunch).cause, isA<RemoteConfigException>());
  });

  test('a successful response replaces the saved payload', () async {
    final store = MemoryRemoteConfigStore()..value = saved;
    const fresh = RemoteConfig(isDynamicContentEnabled: false);
    final service = CachingRemoteConfigService(
      origin: _ScriptedService(() async => fresh),
      store: store,
    );

    expect(await service.fetch(), same(fresh));
    expect((await store.read())?.isDynamicContentEnabled, isFalse);
    expect(
      parseRemoteConfigBody(encodeRemoteConfig(fresh)).isDynamicContentEnabled,
      isFalse,
    );
  });
}

class _ScriptedService implements RemoteConfigService {
  _ScriptedService(this._fetch);

  final Future<RemoteConfig> Function() _fetch;

  @override
  Future<RemoteConfig> fetch() => _fetch();
}

class _BrokenStore implements RemoteConfigStore {
  @override
  Future<RemoteConfig?> read() async => throw Exception('disk');

  @override
  Future<void> write(RemoteConfig config) async {}
}
