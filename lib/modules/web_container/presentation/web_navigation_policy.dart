import 'package:flutter_inappwebview/flutter_inappwebview.dart';

const _documentSchemes = {
  'http',
  'https',
  'about',
  'blob',
  'data',
  'javascript',
};

/// Custom app schemes leave the web view. Document schemes stay inside it.
///
/// `about`, `blob`, `data`, and `javascript` are page machinery, not apps.
/// `tg`, `whatsapp`, `mailto`, `tel`, and `intent` are opened by the system.
bool shouldOpenOutsideWebView(Uri uri) {
  final scheme = uri.scheme.toLowerCase();
  if (scheme.isEmpty) return false;
  return !_documentSchemes.contains(scheme);
}

/// Allows an http(s) document to load, and hands every other scheme to
/// [openExternal] before cancelling the web view navigation.
Future<NavigationActionPolicy> resolveNavigationPolicy({
  required Uri? url,
  required Future<bool> Function(Uri uri) openExternal,
}) async {
  if (url == null || !shouldOpenOutsideWebView(url)) {
    return NavigationActionPolicy.ALLOW;
  }
  try {
    await openExternal(url);
  } on Exception {
    // The custom scheme still must not load inside the document.
  }
  return NavigationActionPolicy.CANCEL;
}
