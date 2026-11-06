import 'package:hybrid_app/modules/remote_config/domain/remote_config.dart';

/// Persistence for the last remote config payload that parsed successfully.
abstract interface class RemoteConfigStore {
  Future<RemoteConfig?> read();

  Future<void> write(RemoteConfig config);
}
