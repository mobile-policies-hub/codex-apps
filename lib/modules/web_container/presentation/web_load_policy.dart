import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Main-document failures that should replace the page with the offline screen.
///
/// Subframe errors stay on the page. A cancelled navigation is the browser
/// dropping a request it no longer needs, not a broken connection.
bool shouldPresentLoadError({
  required bool? isForMainFrame,
  required WebResourceErrorType type,
}) {
  if (isForMainFrame == false) return false;
  if (type == WebResourceErrorType.CANCELLED) return false;
  return true;
}
