import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

/// String store for progress that should survive a restart.
abstract class LocalVault {
  String? read(String key);

  void write(String key, String value);
}

class MemoryVault implements LocalVault {
  final Map<String, String> values = {};

  @override
  String? read(String key) => values[key];

  @override
  void write(String key, String value) {
    values[key] = value;
  }
}

class PreferencesVault implements LocalVault {
  PreferencesVault(this._preferences);

  final SharedPreferences _preferences;

  @override
  String? read(String key) => _preferences.getString(key);

  @override
  void write(String key, String value) {
    unawaited(_preferences.setString(key, value));
  }
}
