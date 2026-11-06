import 'package:hybrid_app/modules/remote_config/domain/remote_config_service.dart';

/// Backend location for startup configuration.
///
/// Override at build or run time:
/// `--dart-define=REMOTE_CONFIG_URL=https://api.example.com/v1/remote-config`
class ApiConfig {
  ApiConfig({required this.remoteConfigUri}) {
    final scheme = remoteConfigUri.scheme;
    final supported = scheme == 'http' || scheme == 'https';
    if (!remoteConfigUri.hasAuthority ||
        remoteConfigUri.host.isEmpty ||
        !supported) {
      throw ArgumentError.value(
        remoteConfigUri.toString(),
        'remoteConfigUri',
        'Expected an absolute http(s) URL',
      );
    }
  }

  static const remoteConfigUrlDefine = 'REMOTE_CONFIG_URL';

  static const defaultRemoteConfigUrl = testRemoteConfigRawUrl;

  factory ApiConfig.fromEnvironment() {
    const raw = String.fromEnvironment(
      remoteConfigUrlDefine,
      defaultValue: defaultRemoteConfigUrl,
    );
    final uri = Uri.tryParse(raw);
    if (uri == null) {
      throw ArgumentError.value(raw, remoteConfigUrlDefine, 'Not a valid URI');
    }
    return ApiConfig(remoteConfigUri: uri);
  }

  final Uri remoteConfigUri;
}
