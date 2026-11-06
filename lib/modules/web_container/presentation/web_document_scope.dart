import 'package:flutter/widgets.dart';

import 'package:hybrid_app/modules/web_container/presentation/web_view_hooks.dart';

typedef WebDocumentBuilder = Widget Function(WebViewHooks hooks);

/// Optional replacement for the platform web view.
///
/// Production leaves this unset and mounts `InAppWebView`. Tests install a
/// plain widget so the chrome can be exercised without a platform view.
class WebDocumentScope extends InheritedWidget {
  const WebDocumentScope({
    super.key,
    required this.builder,
    required super.child,
  });

  final WebDocumentBuilder builder;

  static WebDocumentBuilder? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<WebDocumentScope>()
        ?.builder;
  }

  @override
  bool updateShouldNotify(WebDocumentScope oldWidget) {
    return builder != oldWidget.builder;
  }
}
