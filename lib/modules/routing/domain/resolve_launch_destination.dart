import 'package:hybrid_app/modules/remote_config/domain/remote_config_service.dart';
import 'package:hybrid_app/modules/routing/domain/launch_resolution.dart';

/// Maps a remote config read onto the startup screen.
class ResolveLaunchDestination {
  const ResolveLaunchDestination(this._service);

  final RemoteConfigService _service;

  Future<LaunchResolution> call() async {
    try {
      final config = await _service.fetch();
      final targetUrl = config.webUri;
      if (targetUrl == null) return const NativeLaunch();
      return WebLaunch(targetUrl);
    } on Exception catch (error) {
      return NativeLaunch(cause: error);
    }
  }
}
