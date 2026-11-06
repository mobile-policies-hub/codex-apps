import 'dart:developer';

import 'package:flutter/foundation.dart';

import 'package:hybrid_app/modules/routing/domain/launch_resolution.dart';
import 'package:hybrid_app/modules/routing/domain/resolve_launch_destination.dart';

/// Startup state observed by the root router.
sealed class LaunchState {
  const LaunchState();
}

final class LaunchLoading extends LaunchState {
  const LaunchLoading();
}

final class LaunchReady extends LaunchState {
  const LaunchReady(this.resolution);

  final LaunchResolution resolution;
}

/// Resolves the startup destination once and publishes it to the tree.
class LaunchController extends ChangeNotifier {
  LaunchController(this._resolve);

  final ResolveLaunchDestination _resolve;

  LaunchState _state = const LaunchLoading();
  bool _started = false;
  bool _disposed = false;

  LaunchState get state => _state;

  Future<void> resolve() async {
    if (_started || _disposed) return;
    _started = true;

    final resolution = await _resolve();
    if (_disposed) return;

    if (resolution case NativeLaunch(:final cause) when cause != null) {
      log(
        'Remote config unavailable; showing the native dashboard',
        name: 'LaunchController',
        error: cause,
      );
    }

    _state = LaunchReady(resolution);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
