/// Callbacks and commands shared by the web chrome and the document view.
class WebViewHooks {
  WebViewHooks({required this.initialUrl, this.html});

  final Uri initialUrl;

  /// Local HTML rendered by the in-app web view instead of [initialUrl].
  final String? html;

  void Function(int progress)? onProgress;
  void Function(String message)? onMainFrameError;
  void Function(Uri? url)? onPageStarted;
  void Function(Uri? url)? onPageFinished;

  void Function({required bool canGoBack, required bool canGoForward})?
  onNavigationState;

  Future<void> Function()? reload;
  Future<void> Function()? goBack;
  Future<void> Function()? goForward;

  void attachControls({
    required Future<void> Function() reload,
    required Future<void> Function() goBack,
    required Future<void> Function() goForward,
  }) {
    this.reload = reload;
    this.goBack = goBack;
    this.goForward = goForward;
  }
}
