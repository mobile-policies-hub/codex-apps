import 'package:hybrid_app/modules/remote_config/domain/remote_config.dart';
import 'package:hybrid_app/modules/remote_config/domain/remote_config_store.dart';

/// In-memory store used by tests and as a stand-in before disk is available.
class MemoryRemoteConfigStore implements RemoteConfigStore {
  RemoteConfig? value;

  @override
  Future<RemoteConfig?> read() async => value;

  @override
  Future<void> write(RemoteConfig config) async {
    value = config;
  }
}
