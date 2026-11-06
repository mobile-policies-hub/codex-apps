import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hybrid_app/modules/native_dashboard/presentation/native_dashboard_screen.dart';
import 'package:hybrid_app/modules/notifications/domain/push_payload.dart';
import 'package:hybrid_app/modules/notifications/presentation/push_notification_service.dart';
import 'package:hybrid_app/modules/notifications/presentation/push_preview_layer.dart';
import 'package:hybrid_app/modules/routing/domain/launch_resolution.dart';
import 'package:hybrid_app/modules/routing/presentation/launch_controller.dart';
import 'package:hybrid_app/modules/web_container/presentation/web_container_screen.dart';

/// Startup gate.
///
/// Reads remote config once, then mounts [WebContainerScreen] when
/// `isDynamicContentEnabled` is true and `targetUrl` is an absolute http(s)
/// URL. Otherwise mounts [NativeDashboardScreen].
class RootRouter extends StatefulWidget {
  const RootRouter({super.key});

  @override
  State<RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<RootRouter> {
  bool? _segmentedForWeb;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<LaunchController>().resolve());
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LaunchController>().state;
    final push = context.watch<PushNotificationService>();
    if (state is LaunchReady) {
      final web = state.resolution is WebLaunch;
      push.bindDynamicContent(web);
      if (_segmentedForWeb != web) {
        _segmentedForWeb = web;
        unawaited(push.updateUserSegment(isDynamicContentEnabled: web));
      }
    }

    final destination = switch (state) {
      LaunchLoading() => const _LaunchSplash(),
      LaunchReady(:final resolution) => switch (resolution) {
        WebLaunch(:final targetUrl) => _webScreen(
          pushWebUri(
                isDynamicContentEnabled: true,
                payload: push.lastPayload,
              ) ??
              targetUrl,
        ),
        NativeLaunch() => const NativeDashboardScreen(),
      },
    };

    return PushPreviewLayer(child: destination);
  }
}

WebContainerScreen _webScreen(Uri targetUrl) {
  return WebContainerScreen(
    key: ValueKey(targetUrl.toString()),
    targetUrl: targetUrl,
  );
}

class _LaunchSplash extends StatelessWidget {
  const _LaunchSplash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Semantics(
            label: 'Loading configuration',
            child: const CupertinoActivityIndicator(),
          ),
        ),
      ),
    );
  }
}
