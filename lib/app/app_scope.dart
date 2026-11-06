import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:hybrid_app/core/config/api_config.dart';
import 'package:hybrid_app/modules/notifications/presentation/push_notification_service.dart';
import 'package:hybrid_app/modules/remote_config/data/startup_config_service.dart';
import 'package:hybrid_app/modules/remote_config/domain/remote_config_store.dart';
import 'package:hybrid_app/modules/routing/domain/resolve_launch_destination.dart';
import 'package:hybrid_app/modules/routing/presentation/launch_controller.dart';

/// Composition root for startup routing.
///
/// Owns the HTTP client unless [httpClient] is injected by the caller.
class AppScope extends StatefulWidget {
  const AppScope({
    super.key,
    required this.config,
    required this.configStore,
    required this.child,
    this.httpClient,
  });

  final ApiConfig config;
  final RemoteConfigStore configStore;
  final Widget child;
  final http.Client? httpClient;

  @override
  State<AppScope> createState() => _AppScopeState();
}

class _AppScopeState extends State<AppScope> {
  late final http.Client _client;
  late final bool _ownsClient;
  late final LaunchController _controller;
  late final PushNotificationService _push;

  @override
  void initState() {
    super.initState();
    _ownsClient = widget.httpClient == null;
    _client = widget.httpClient ?? http.Client();
    _push = PushNotificationService();
    unawaited(_push.initialize());
    final service = startupConfigService(
      configUrl: widget.config.remoteConfigUri,
      client: _client,
      store: widget.configStore,
    );
    _controller = LaunchController(ResolveLaunchDestination(service));
  }

  @override
  void dispose() {
    _controller.dispose();
    _push.dispose();
    if (_ownsClient) _client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LaunchController>.value(value: _controller),
        ChangeNotifierProvider<PushNotificationService>.value(value: _push),
      ],
      child: widget.child,
    );
  }
}
