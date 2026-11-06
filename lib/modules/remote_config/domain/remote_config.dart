import 'package:hybrid_app/core/config/app_config.dart';

/// Safe page used when a payload does not name its own http(s) target.
const String defaultTargetUrl = 'https://google.com';

/// Startup flags returned by the remote config endpoint.
///
/// The sealed default keeps dynamic content off, so [webUri] is null even
/// when [targetUrl] is [defaultTargetUrl]. A web launch requires a live
/// payload with [isDynamicContentEnabled] set.
class RemoteConfig {
  const RemoteConfig({
    this.isDynamicContentEnabled = false,
    this.displayMode = AppDisplayMode.standard,
    this.userCategory = UserCategory.defaultUser,
    this.targetUrl = defaultTargetUrl,
  });

  final bool isDynamicContentEnabled;
  final AppDisplayMode displayMode;
  final UserCategory userCategory;
  final String? targetUrl;

  AppConfig get appConfig => AppConfig(
    isDynamicContentEnabled: isDynamicContentEnabled,
    displayMode: displayMode,
    userCategory: userCategory,
  );

  /// Absolute http(s) URL when dynamic content should open.
  ///
  /// Returns null when dynamic content is disabled, the URL is missing,
  /// or the value is not an absolute http(s) URI.
  Uri? get webUri {
    if (!isDynamicContentEnabled) return null;

    final raw = targetUrl?.trim();
    if (raw == null || raw.isEmpty) return null;

    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return uri;
  }
}
