import 'package:flutter_test/flutter_test.dart';
import 'package:hybrid_app/modules/remote_config/domain/remote_config.dart';
import 'package:hybrid_app/modules/remote_config/domain/remote_config_exception.dart';
import 'package:hybrid_app/modules/remote_config/domain/remote_config_service.dart';
import 'package:hybrid_app/modules/routing/domain/launch_resolution.dart';
import 'package:hybrid_app/modules/routing/domain/resolve_launch_destination.dart';

void main() {
  ResolveLaunchDestination resolveWith(RemoteConfigService service) {
    return ResolveLaunchDestination(service);
  }

  test('opens the web container for an enabled http(s) URL', () async {
    final resolution = await resolveWith(
      _FakeRemoteConfigService(
        () async => const RemoteConfig(
          isDynamicContentEnabled: true,
          targetUrl: ' https://app.example.com/home ',
        ),
      ),
    ).call();

    expect(resolution, isA<WebLaunch>());
    expect(
      (resolution as WebLaunch).targetUrl,
      Uri.parse('https://app.example.com/home'),
    );
  });

  test('opens the native dashboard when web is disabled', () async {
    final resolution = await resolveWith(
      _FakeRemoteConfigService(
        () async => const RemoteConfig(
          isDynamicContentEnabled: false,
          targetUrl: 'https://app.example.com',
        ),
      ),
    ).call();

    expect(resolution, isA<NativeLaunch>());
    expect((resolution as NativeLaunch).cause, isNull);
  });

  test(
    'opens the native dashboard when the URL is missing or not http(s)',
    () async {
      for (final targetUrl in <String?>[
        null,
        '',
        '   ',
        'ftp://files.example.com',
      ]) {
        final resolution = await resolveWith(
          _FakeRemoteConfigService(
            () async => RemoteConfig(
              isDynamicContentEnabled: true,
              targetUrl: targetUrl,
            ),
          ),
        ).call();

        expect(resolution, isA<NativeLaunch>());
        expect((resolution as NativeLaunch).cause, isNull);
      }
    },
  );

  test('opens the native dashboard when the config read fails', () async {
    final resolution = await resolveWith(
      _FakeRemoteConfigService(
        () async => throw const RemoteConfigException('offline'),
      ),
    ).call();

    expect(resolution, isA<NativeLaunch>());
    expect((resolution as NativeLaunch).cause, isA<RemoteConfigException>());
  });
}

class _FakeRemoteConfigService implements RemoteConfigService {
  _FakeRemoteConfigService(this._fetch);

  final Future<RemoteConfig> Function() _fetch;

  @override
  Future<RemoteConfig> fetch() => _fetch();
}
