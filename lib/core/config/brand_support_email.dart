/// Asset copied into the app bundle from `ios/Flutter/Brand.xcconfig`.
const String brandXcconfigAsset = 'ios/Flutter/Brand.xcconfig';

/// Reads one assignment from a Brand.xcconfig document.
///
/// Comment lines are ignored. Returns null when the key is missing or blank.
String? xcconfigValue(String source, String name) {
  for (final line in source.split(RegExp(r'\r?\n'))) {
    final trimmed = line.trim();
    if (trimmed.isEmpty ||
        trimmed.startsWith('//') ||
        trimmed.startsWith('#')) {
      continue;
    }
    final separator = trimmed.indexOf('=');
    if (separator <= 0) continue;
    final key = trimmed.substring(0, separator).trim();
    if (key != name) continue;
    final value = trimmed.substring(separator + 1).trim();
    if (value.isEmpty) return null;
    return value;
  }
  return null;
}

/// Reads `SUPPORT_EMAIL` from a Brand.xcconfig document.
String? supportEmailFromXcconfig(String source) {
  return xcconfigValue(source, 'SUPPORT_EMAIL');
}
