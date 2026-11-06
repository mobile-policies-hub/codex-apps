import 'dart:convert';

import 'package:hybrid_app/core/config/app_config.dart';
import 'package:hybrid_app/modules/remote_config/domain/remote_config.dart';
import 'package:hybrid_app/modules/remote_config/domain/remote_config_exception.dart';

/// Parses the remote config JSON document.
///
/// `isDynamicContentEnabled` defaults to false when the key is absent.
/// A missing or blank `targetUrl` becomes [defaultTargetUrl].
/// `displayMode` and `userCategory` accept the enum names and the legacy
/// tokens (`white` / `black`, `organic` / `player`). An unrecognized display
/// mode falls back to [AppDisplayMode.standard].
RemoteConfig parseRemoteConfigBody(String body) {
  final Object? decoded;
  try {
    decoded = jsonDecode(body);
  } on FormatException catch (error) {
    throw RemoteConfigException(
      'Config payload is not valid JSON',
      cause: error,
    );
  }

  if (decoded is! Map<String, dynamic>) {
    throw const RemoteConfigException('Config payload must be a JSON object');
  }

  final enabled = _readDynamicContentFlag(decoded);
  final displayMode = _readDisplayMode(decoded, enabled: enabled);
  final userCategory = _readUserCategory(decoded, enabled: enabled);

  final url = decoded['targetUrl'];
  if (url != null && url is! String) {
    throw const RemoteConfigException(
      'Field targetUrl must be a string or null',
    );
  }

  return RemoteConfig(
    isDynamicContentEnabled: enabled,
    displayMode: displayMode,
    userCategory: userCategory,
    targetUrl: _readTargetUrl(url),
  );
}

String _readTargetUrl(String? url) {
  if (url == null || url.trim().isEmpty) return defaultTargetUrl;
  return url;
}

bool _readDynamicContentFlag(Map<String, dynamic> decoded) {
  if (!decoded.containsKey('isDynamicContentEnabled')) return false;
  final enabled = decoded['isDynamicContentEnabled'];
  if (enabled is! bool) {
    throw const RemoteConfigException(
      'Field isDynamicContentEnabled must be a boolean',
    );
  }
  return enabled;
}

AppDisplayMode _readDisplayMode(
  Map<String, dynamic> decoded, {
  required bool enabled,
}) {
  if (!decoded.containsKey('displayMode') && !decoded.containsKey('mode')) {
    return enabled ? AppDisplayMode.extended : AppDisplayMode.standard;
  }
  final raw = decoded.containsKey('displayMode')
      ? decoded['displayMode']
      : decoded['mode'];
  return AppDisplayMode.parse(raw);
}

UserCategory _readUserCategory(
  Map<String, dynamic> decoded, {
  required bool enabled,
}) {
  if (!decoded.containsKey('userCategory') &&
      !decoded.containsKey('user_type')) {
    return enabled ? UserCategory.primaryUser : UserCategory.defaultUser;
  }
  final raw = decoded.containsKey('userCategory')
      ? decoded['userCategory']
      : decoded['user_type'];
  return UserCategory.parse(raw);
}

/// Serializes [config] in the same shape the endpoint returns.
String encodeRemoteConfig(RemoteConfig config) {
  return jsonEncode({
    'isDynamicContentEnabled': config.isDynamicContentEnabled,
    'displayMode': config.displayMode.name,
    'userCategory': config.userCategory.name,
    'targetUrl': config.targetUrl,
  });
}
