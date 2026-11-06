import 'package:url_launcher/url_launcher.dart';

/// Opens [uri] in the app that owns its scheme.
Future<bool> launchExternalApplication(Uri uri) {
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
