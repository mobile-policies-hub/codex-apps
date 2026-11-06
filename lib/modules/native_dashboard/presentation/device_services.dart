import 'package:flutter/widgets.dart';

import 'package:hybrid_app/modules/native_dashboard/data/local_vault.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/tracker_controller.dart';

/// On-device services available to the native dashboard.
///
/// Widget tests omit this scope, so they keep the in-memory controllers.
class DeviceServices extends InheritedWidget {
  const DeviceServices({
    super.key,
    required this.vault,
    required this.alarms,
    required super.child,
  });

  final LocalVault vault;
  final HabitAlarmScheduler alarms;

  static DeviceServices? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DeviceServices>();
  }

  @override
  bool updateShouldNotify(DeviceServices oldWidget) {
    return vault != oldWidget.vault || alarms != oldWidget.alarms;
  }
}
