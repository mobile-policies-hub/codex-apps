/// Where the app should land after startup configuration is resolved.
sealed class LaunchResolution {
  const LaunchResolution();
}

/// Open the remote web experience at [targetUrl].
final class WebLaunch extends LaunchResolution {
  const WebLaunch(this.targetUrl);

  final Uri targetUrl;
}

/// Open the local dashboard.
///
/// [cause] is set when the native screen is a fallback after a failed config
/// read. It stays null when the payload itself selects the native screen.
final class NativeLaunch extends LaunchResolution {
  const NativeLaunch({this.cause});

  final Object? cause;
}
