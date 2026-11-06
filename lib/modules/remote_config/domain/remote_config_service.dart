import 'package:hybrid_app/modules/remote_config/domain/remote_config.dart';
import 'package:hybrid_app/modules/remote_config/domain/remote_config_exception.dart';

/// Startup configuration served by the Cloudflare Worker.
///
/// A timeout, an unreachable host, or a bad response never opens dynamic
/// content. Startup routing then stays on the native screen.
const String testRemoteConfigRawUrl =
    'https://lucky-union-2bd1.denischernousov90.workers.dev/';

/// Loads startup configuration from the backend.
///
/// The app reads [testRemoteConfigRawUrl] unless `REMOTE_CONFIG_URL` is set.
/// Throws [RemoteConfigException] when the endpoint cannot be reached or the
/// payload does not match the contract:
/// `{"isDynamicContentEnabled": true, "targetUrl": "https://google.com"}`.
abstract interface class RemoteConfigService {
  Future<RemoteConfig> fetch();
}
