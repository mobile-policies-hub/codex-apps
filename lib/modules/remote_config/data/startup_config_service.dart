import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:hybrid_app/core/config/app_config.dart';
import 'package:hybrid_app/modules/remote_config/domain/remote_config.dart';
import 'package:hybrid_app/modules/remote_config/domain/remote_config_service.dart';
import 'package:hybrid_app/modules/remote_config/domain/remote_config_store.dart';

/// Startup configuration for every build, including release.
///
/// [isDynamicContentEnabled] stays false. The app does not request a remote
/// document or open a remote page at launch. [debugMode] remains so existing
/// call sites compile.
RemoteConfigService startupConfigService({
  required Uri configUrl,
  required http.Client client,
  required RemoteConfigStore store,
  bool debugMode = kDebugMode,
}) {
  log(
    'Local session: isDynamicContentEnabled=false, '
    'displayMode=standard, remote config request skipped '
    '(debugMode=$debugMode, host=${configUrl.host}, '
    'store=${store.runtimeType}, client=${client.hashCode})',
    name: 'StartupConfig',
  );
  return const LocalDebugConfigService();
}

/// Native utility state used while the app is running from source or tests.
class LocalDebugConfigService implements RemoteConfigService {
  const LocalDebugConfigService();

  @override
  Future<RemoteConfig> fetch() async {
    return const RemoteConfig(
      isDynamicContentEnabled: false,
      displayMode: AppDisplayMode.standard,
      userCategory: UserCategory.defaultUser,
    );
  }
}
