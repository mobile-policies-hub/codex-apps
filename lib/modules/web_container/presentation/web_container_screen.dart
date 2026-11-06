import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:hybrid_app/core/l10n/app_text.dart';

import 'package:hybrid_app/modules/web_container/presentation/inapp_web_document.dart';
import 'package:hybrid_app/modules/web_container/presentation/web_document_scope.dart';
import 'package:hybrid_app/modules/web_container/presentation/web_offline_view.dart';
import 'package:hybrid_app/modules/web_container/presentation/web_view_hooks.dart';

/// Full-screen web experience for an absolute http(s) [targetUrl].
///
/// JavaScript, cookies, and local storage stay enabled. History moves with
/// the toolbar and the iOS back/forward swipe. Pull down on the page to
/// reload it.
class WebContainerScreen extends StatefulWidget {
  const WebContainerScreen({
    super.key,
    required this.targetUrl,
    this.documentHtml,
    this.title,
  });

  final Uri targetUrl;

  /// Local HTML shown in the in-app web view. When set, [targetUrl] is not loaded.
  final String? documentHtml;

  /// Label in the toolbar. Falls back to the current page address.
  final String? title;

  @override
  State<WebContainerScreen> createState() => _WebContainerScreenState();
}

class _WebContainerScreenState extends State<WebContainerScreen> {
  late final WebViewHooks _hooks;
  late String _displayUrl;
  int _progress = 0;
  bool _showSpinner = true;
  bool _canGoBack = false;
  bool _canGoForward = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _showSpinner = widget.documentHtml == null;
    _displayUrl = widget.title ?? widget.targetUrl.toString();
    _hooks =
        WebViewHooks(initialUrl: widget.targetUrl, html: widget.documentHtml)
          ..onProgress = _handleProgress
          ..onMainFrameError = _handleError
          ..onPageStarted = _handlePageStarted
          ..onPageFinished = _handlePageFinished
          ..onNavigationState = _handleNavigation;
  }

  void _handleProgress(int value) {
    if (!mounted) return;
    setState(() {
      _progress = value.clamp(0, 100);
      if (_progress > 0) _showSpinner = false;
    });
  }

  void _handleError(String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _showSpinner = false;
    });
  }

  void _handlePageStarted(Uri? url) {
    if (!mounted) return;
    setState(() {
      _error = null;
      _progress = 0;
      _displayUrl = widget.title ?? url?.toString() ?? _displayUrl;
    });
  }

  void _handlePageFinished(Uri? url) {
    if (!mounted) return;
    setState(() {
      _progress = 100;
      _showSpinner = false;
      _error = null;
      _displayUrl = widget.title ?? url?.toString() ?? _displayUrl;
    });
  }

  void _handleNavigation({
    required bool canGoBack,
    required bool canGoForward,
  }) {
    if (!mounted) return;
    setState(() {
      _canGoBack = canGoBack;
      _canGoForward = canGoForward;
    });
  }

  Future<void> _retry() async {
    setState(() {
      _error = null;
      _progress = 0;
      _showSpinner = true;
    });
    await _hooks.reload?.call();
  }

  @override
  Widget build(BuildContext context) {
    final builder = WebDocumentScope.maybeOf(context) ?? buildInAppWebDocument;
    final showSpinner = _error == null && _showSpinner;
    final showBar = _error == null && !_showSpinner && _progress < 100;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _NavigationBar(
              url: _displayUrl,
              canGoBack: _canGoBack || Navigator.canPop(context),
              canGoForward: _canGoForward,
              onBack: () {
                if (_canGoBack) {
                  _hooks.goBack?.call();
                  return;
                }
                Navigator.of(context).maybePop();
              },
              onForward: () => _hooks.goForward?.call(),
            ),
            if (showBar)
              LinearProgressIndicator(
                key: const Key('web-progress'),
                value: _progress / 100,
                minHeight: 3,
              ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  builder(_hooks),
                  if (showSpinner) const _LoadingOverlay(),
                  if (_error case final message?)
                    WebOfflineView(message: message, onRetry: _retry),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationBar extends StatelessWidget {
  const _NavigationBar({
    required this.url,
    required this.canGoBack,
    required this.canGoForward,
    required this.onBack,
    required this.onForward,
  });

  final String url;
  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback onBack;
  final VoidCallback onForward;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            IconButton(
              key: const Key('web-back'),
              tooltip: context.tr('Back'),
              onPressed: canGoBack ? onBack : null,
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            ),
            IconButton(
              key: const Key('web-forward'),
              tooltip: context.tr('Forward'),
              onPressed: canGoForward ? onForward : null,
              icon: const Icon(Icons.arrow_forward_ios, size: 18),
            ),
            Expanded(
              child: Text(
                url,
                key: const Key('web-url'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      key: const Key('web-loading'),
      color: const Color(0xCCFFFFFF),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CupertinoActivityIndicator(),
                const SizedBox(height: 14),
                Text(context.tr('Opening the page')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
