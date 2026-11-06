import 'package:flutter/widgets.dart';

/// Mobile Safari user agent used when [WebDocumentConfig.userAgent] is left
/// at its default. Replace [WebDocumentConfig.current] to send another one.
const defaultIosSafariUserAgent =
    'Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) '
    'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.6 '
    'Mobile/15E148 Safari/604.1';

/// Request identity for the in-app document.
///
/// [userAgent] is sent on every web view request. [headers] are added to the
/// initial load and to later reloads.
class WebDocumentConfig {
  const WebDocumentConfig({
    this.userAgent = defaultIosSafariUserAgent,
    this.headers = const {},
  });

  static const current = WebDocumentConfig();

  final String userAgent;
  final Map<String, String> headers;

  Map<String, String> requestHeaders() {
    return {'User-Agent': userAgent, ...headers};
  }
}

class WebDocumentConfigScope extends InheritedWidget {
  const WebDocumentConfigScope({
    super.key,
    required this.config,
    required super.child,
  });

  final WebDocumentConfig config;

  static WebDocumentConfig of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<WebDocumentConfigScope>();
    return scope?.config ?? WebDocumentConfig.current;
  }

  @override
  bool updateShouldNotify(WebDocumentConfigScope oldWidget) {
    return config.userAgent != oldWidget.config.userAgent ||
        !_sameHeaders(config.headers, oldWidget.config.headers);
  }
}

bool _sameHeaders(Map<String, String> left, Map<String, String> right) {
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    if (right[entry.key] != entry.value) return false;
  }
  return true;
}
