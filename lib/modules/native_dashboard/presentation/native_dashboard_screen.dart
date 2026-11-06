import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hybrid_app/core/config/app_brand_config.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/ancient_codex_controller.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/apex_calc_controller.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/brand_shell.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/device_services.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/sound/sound_deck.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/tracker_controller.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/tracker_palette.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/widgets/premium_surface.dart';

/// Local experience used when the web shell is off or unreachable.
class NativeDashboardScreen extends StatelessWidget {
  const NativeDashboardScreen({super.key, this.today});

  final DateTime? today;

  @override
  Widget build(BuildContext context) {
    final brand = AppBrand.of(context);
    return ChangeNotifierProvider(
      create: (_) => SoundDeck(),
      child: Builder(
        builder: (context) {
          final deck = context.read<SoundDeck>();
          final services = DeviceServices.maybeOf(context);
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: (_) => TrackerController(
                  today: today,
                  deck: deck,
                  vault: services?.vault,
                  alarms: brand.id == AppBrandId.zenithHabits
                      ? services?.alarms
                      : null,
                ),
              ),
              ChangeNotifierProvider(
                create: (_) =>
                    AncientCodexController(deck: deck, vault: services?.vault),
              ),
              ChangeNotifierProvider(
                create: (_) =>
                    ApexCalcController(deck: deck, vault: services?.vault),
              ),
            ],
            child: _DashboardFrame(brand: brand),
          );
        },
      ),
    );
  }
}

class _DashboardFrame extends StatelessWidget {
  const _DashboardFrame({required this.brand});

  final AppBrandConfig brand;

  @override
  Widget build(BuildContext context) {
    return MobileFrame(
      child: Theme(
        data: buildTrackerTheme(brand),
        child: const Navigator(initialRoute: '/', onGenerateRoute: _homeRoute),
      ),
    );
  }
}

Route<dynamic> _homeRoute(RouteSettings settings) {
  return CupertinoPageRoute<void>(
    settings: settings,
    builder: (_) => const BrandShell(),
  );
}
