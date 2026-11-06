import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:hybrid_app/core/config/web_document_config.dart';

/// Web view configuration for a persistent, scriptable document.
///
/// `incognito: false` keeps the default website data store, so cookies and
/// local storage survive reloads and restarts. `sharedCookiesEnabled` also
/// writes cookies into the shared cookie store. [userAgent] is attached to
/// every request; it defaults to mobile Safari.
InAppWebViewSettings persistentDocumentSettings({
  String userAgent = defaultIosSafariUserAgent,
}) {
  return InAppWebViewSettings(
    javaScriptEnabled: true,
    domStorageEnabled: true,
    databaseEnabled: true,
    cacheEnabled: true,
    incognito: false,
    sharedCookiesEnabled: true,
    thirdPartyCookiesEnabled: true,
    allowsInlineMediaPlayback: true,
    mediaPlaybackRequiresUserGesture: false,
    allowsBackForwardNavigationGestures: true,
    limitsNavigationsToAppBoundDomains: false,
    disableDefaultErrorPage: true,
    useShouldOverrideUrlLoading: true,
    userAgent: userAgent,
  );
}
