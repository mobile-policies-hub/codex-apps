import 'package:flutter_test/flutter_test.dart';
import 'package:hybrid_app/modules/remote_config/domain/remote_config.dart';
import 'package:hybrid_app/modules/remote_config/domain/remote_config_service.dart';
import 'package:hybrid_app/modules/routing/domain/launch_resolution.dart';
import 'package:hybrid_app/modules/routing/domain/resolve_launch_destination.dart';
import 'package:hybrid_app/modules/routing/presentation/launch_controller.dart';

void main() {
  test('publishes a ready state after the first resolve', () async {
    final controller = LaunchController(
      ResolveLaunchDestination(
        _FakeRemoteConfigService(
          () async => const RemoteConfig(
            isDynamicContentEnabled: true,
            targetUrl: 'https://app.example.com',
          ),
        ),
      ),
    );

    await controller.resolve();

    final state = controller.state;
    expect(state, isA<LaunchReady>());
    expect((state as LaunchReady).resolution, isA<WebLaunch>());

    controller.dispose();
  });

  test('reads remote config only once', () async {
    var calls = 0;
    final controller = LaunchController(
      ResolveLaunchDestination(
        _FakeRemoteConfigService(() async {
          calls += 1;
          return const RemoteConfig(isDynamicContentEnabled: false);
        }),
      ),
    );

    await controller.resolve();
    await controller.resolve();

    expect(calls, 1);
    expect(controller.state, isA<LaunchReady>());
    controller.dispose();
  });
}

class _FakeRemoteConfigService implements RemoteConfigService {
  _FakeRemoteConfigService(this._fetch);

  final Future<RemoteConfig> Function() _fetch;

  @override
  Future<RemoteConfig> fetch() => _fetch();
}
