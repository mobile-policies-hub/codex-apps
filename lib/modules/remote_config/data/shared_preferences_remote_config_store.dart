import 'package:shared_preferences/shared_preferences.dart';

import 'package:hybrid_app/modules/remote_config/data/remote_config_parser.dart';
import 'package:hybrid_app/modules/remote_config/domain/remote_config.dart';
import 'package:hybrid_app/modules/remote_config/domain/remote_config_exception.dart';
import 'package:hybrid_app/modules/remote_config/domain/remote_config_store.dart';

/// Disk-backed copy of the last successful remote config response.
class SharedPreferencesRemoteConfigStore implements RemoteConfigStore {
  SharedPreferencesRemoteConfigStore(this._preferences);

  static const storageKey = 'remote_config.latest';

  final SharedPreferences _preferences;

  @override
  Future<RemoteConfig?> read() async {
    final raw = _preferences.getString(storageKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return parseRemoteConfigBody(raw);
    } on RemoteConfigException {
      return null;
    }
  }

  @override
  Future<void> write(RemoteConfig config) {
    return _preferences.setString(storageKey, encodeRemoteConfig(config));
  }
}
