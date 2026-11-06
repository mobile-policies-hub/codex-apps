import 'dart:io';

import 'package:hybrid_app/core/config/brand_support_email.dart';

/// Brand.xcconfig text when the project file is on disk.
String? readBrandXcconfig() {
  try {
    final file = File(brandXcconfigAsset);
    if (!file.existsSync()) return null;
    return file.readAsStringSync();
  } on IOException {
    return null;
  }
}

/// Support address from the Brand.xcconfig next to the project, when present.
String? readBrandSupportEmail() {
  final source = readBrandXcconfig();
  if (source == null) return null;
  return supportEmailFromXcconfig(source);
}
