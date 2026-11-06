import 'package:hybrid_app/modules/remote_config/domain/remote_config.dart';
import 'package:hybrid_app/modules/remote_config/domain/remote_config_service.dart';
import 'package:hybrid_app/modules/remote_config/domain/remote_config_store.dart';

/// Reads remote config from the network and keeps the last good payload.
///
/// A timeout or any other fetch failure is rethrown. Startup routing then
/// stays on the native dashboard and does not reopen a saved web target.
/// The next successful response replaces the saved payload.
class CachingRemoteConfigService implements RemoteConfigService {
  CachingRemoteConfigService({required this.origin, required this.store});

  final RemoteConfigService origin;
  final RemoteConfigStore store;

  @override
  Future<RemoteConfig> fetch() async {
    final config = await origin.fetch();
    try {
      await store.write(config);
    } on Exception {
      // The live response is still usable if disk persistence fails.
    }
    return config;
  }
}
