/// Native screen a push opens when the web shell is off.
enum NativePushSection { habitList, dailyQuiz }

/// Absolute http(s) URL from a push payload, or null when it is not one.
Uri? httpPayload(String? payload) {
  final raw = payload?.trim();
  if (raw == null || raw.isEmpty) return null;
  final uri = Uri.tryParse(raw);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  return uri;
}

/// Web container URL when dynamic content is on and the payload is a link.
Uri? pushWebUri({required bool isDynamicContentEnabled, String? payload}) {
  if (!isDynamicContentEnabled) return null;
  return httpPayload(payload);
}

/// Habit list unless the payload names the daily quiz.
NativePushSection nativeSectionFor(String? payload) {
  final value = payload?.toLowerCase() ?? '';
  if (value.contains('quiz') || value.contains('trial')) {
    return NativePushSection.dailyQuiz;
  }
  return NativePushSection.habitList;
}
