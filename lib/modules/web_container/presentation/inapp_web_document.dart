import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:hybrid_app/core/config/web_document_config.dart';
import 'package:hybrid_app/modules/web_container/presentation/external_url_launcher.dart';
import 'package:hybrid_app/modules/web_container/presentation/persistent_web_settings.dart';
import 'package:hybrid_app/modules/web_container/presentation/web_load_policy.dart';
import 'package:hybrid_app/modules/web_container/presentation/web_navigation_policy.dart';
import 'package:hybrid_app/modules/web_container/presentation/web_view_hooks.dart';

Widget buildInAppWebDocument(WebViewHooks hooks) {
  return InAppWebDocument(hooks: hooks);
}

class InAppWebDocument extends StatefulWidget {
  const InAppWebDocument({
    super.key,
    required this.hooks,
    this.openExternal = launchExternalApplication,
  });

  final WebViewHooks hooks;
  final Future<bool> Function(Uri uri) openExternal;

  @override
  State<InAppWebDocument> createState() => _InAppWebDocumentState();
}

class _InAppWebDocumentState extends State<InAppWebDocument> {
  PullToRefreshController? _refresh;
  InAppWebViewController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (kIsWeb || _refresh != null) return;
    _refresh = PullToRefreshController(
      settings: PullToRefreshSettings(
        color: Theme.of(context).colorScheme.primary,
        backgroundColor: const Color(0xFFFFFCF8),
      ),
      onRefresh: _reloadFromPull,
    );
  }

  Future<void> _reloadFromPull() async {
    final controller = _controller;
    if (controller == null) {
      await _refresh?.endRefreshing();
      return;
    }
    await _load(controller, preferCurrentUrl: true);
  }

  Future<void> _load(
    InAppWebViewController controller, {
    required bool preferCurrentUrl,
  }) async {
    final html = widget.hooks.html;
    if (html != null) {
      await controller.loadData(data: html);
      return;
    }
    final headers = _requestHeaders();
    try {
      final current = preferCurrentUrl ? await controller.getUrl() : null;
      final target = current ?? WebUri(widget.hooks.initialUrl.toString());
      await controller.loadUrl(
        urlRequest: URLRequest(url: target, headers: headers),
      );
    } catch (_) {
      await controller.loadUrl(
        urlRequest: URLRequest(
          url: WebUri(widget.hooks.initialUrl.toString()),
          headers: headers,
        ),
      );
    }
  }

  Map<String, String> _requestHeaders() {
    return WebDocumentConfigScope.of(context).requestHeaders();
  }

  Future<void> _publishNavigation(InAppWebViewController controller) async {
    final canGoBack = await controller.canGoBack();
    final canGoForward = await controller.canGoForward();
    if (!mounted) return;
    widget.hooks.onNavigationState?.call(
      canGoBack: canGoBack,
      canGoForward: canGoForward,
    );
  }

  @override
  Widget build(BuildContext context) {
    final document = WebDocumentConfigScope.of(context);
    final html = widget.hooks.html;
    return InAppWebView(
      key: const ValueKey('inapp-webview'),
      initialUrlRequest: html == null
          ? URLRequest(
              url: WebUri(widget.hooks.initialUrl.toString()),
              headers: document.requestHeaders(),
            )
          : null,
      initialData: html == null ? null : InAppWebViewInitialData(data: html),
      initialSettings: persistentDocumentSettings(
        userAgent: document.userAgent,
      ),
      pullToRefreshController: _refresh,
      shouldOverrideUrlLoading: (controller, navigationAction) {
        return resolveNavigationPolicy(
          url: navigationAction.request.url,
          openExternal: widget.openExternal,
        );
      },
      onWebViewCreated: (controller) {
        _controller = controller;
        widget.hooks.attachControls(
          reload: () => _load(controller, preferCurrentUrl: true),
          goBack: () => controller.goBack(),
          goForward: () => controller.goForward(),
        );
      },
      onLoadStart: (controller, url) {
        widget.hooks.onPageStarted?.call(url);
      },
      onLoadStop: (controller, url) async {
        await _refresh?.endRefreshing();
        widget.hooks.onPageFinished?.call(url);
        await _publishNavigation(controller);
      },
      onUpdateVisitedHistory: (controller, url, isReload) async {
        await _publishNavigation(controller);
      },
      onProgressChanged: (controller, progress) {
        if (progress == 100) {
          _refresh?.endRefreshing();
        }
        widget.hooks.onProgress?.call(progress);
      },
      onReceivedError: (controller, request, error) {
        _refresh?.endRefreshing();
        if (!shouldPresentLoadError(
          isForMainFrame: request.isForMainFrame,
          type: error.type,
        )) {
          return;
        }
        final description = error.description.trim();
        widget.hooks.onMainFrameError?.call(
          description.isEmpty ? 'Could not open the page' : description,
        );
      },
    );
  }
}
