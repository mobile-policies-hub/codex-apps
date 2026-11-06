import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hybrid_app/core/config/app_brand_config.dart';
import 'package:hybrid_app/core/l10n/app_text.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/ancient_screens.dart';
import 'package:hybrid_app/modules/notifications/domain/push_payload.dart';
import 'package:hybrid_app/modules/notifications/presentation/push_notification_service.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/apex_screens.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/dashboard_home.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/settings_screen.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/tracker_controller.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/widgets/premium_surface.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/zenith_screens.dart';

class BrandShell extends StatefulWidget {
  const BrandShell({super.key});

  @override
  State<BrandShell> createState() => _BrandShellState();
}

class _BrandShellState extends State<BrandShell> {
  int _index = 0;
  int _appliedGeneration = 0;
  int _scheduledGeneration = 0;

  void _scheduleSection(PushNotificationService push, AppBrandId brandId) {
    if (push.generation == 0 || push.generation == _appliedGeneration) return;
    if (push.generation == _scheduledGeneration) return;
    final next = _tabFor(brandId, push.nativeDestination());
    if (next == null) {
      _appliedGeneration = push.generation;
      return;
    }
    _scheduledGeneration = push.generation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _appliedGeneration = push.generation;
      setState(() => _index = next);
      final navigator = Navigator.of(context);
      if (navigator.canPop()) navigator.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final brand = AppBrand.of(context);
    final push = PushNotificationService.maybeOf(context);
    if (push != null) _scheduleSection(push, brand.id);
    final tabs = _tabsFor(context, brand.id);
    final index = _index >= tabs.length ? 0 : _index;
    final title = index == 0
        ? context.tr(brand.nativeDashboardTitle)
        : tabs[index].label;
    final scheme = Theme.of(context).colorScheme;

    return BrandBackdrop(
      child: Scaffold(
        backgroundColor: brand.backgroundColor,
        appBar: AppBar(
          title: Text(title),
          actions: [
            if (kIsWeb && BrandPreview.maybeOf(context) != null)
              PopupMenuButton<AppBrandConfig>(
                tooltip: 'Brand',
                icon: const Icon(Icons.apps),
                onSelected: (value) {
                  context.read<TrackerController>().stopAmbient();
                  setState(() => _index = 0);
                  BrandPreview.maybeOf(context)?.onSelect(value);
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: AppBrandConfig.ancientCodex,
                    child: Text('Ancient Codex'),
                  ),
                  PopupMenuItem(
                    value: AppBrandConfig.zenithHabits,
                    child: Text('Zenith Habits'),
                  ),
                  PopupMenuItem(
                    value: AppBrandConfig.apexCalc,
                    child: Text('Apex Calc'),
                  ),
                ],
              ),
            IconButton(
              key: const Key('open-settings'),
              tooltip: context.tr('Settings'),
              onPressed: () {
                Navigator.of(context).push(
                  CupertinoPageRoute<void>(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.tune),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: index,
                children: [for (final tab in tabs) tab.page],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: brand.cardColor,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                      child: BottomNavigationBar(
                        currentIndex: index,
                        onTap: (value) {
                          final leavingTimer =
                              brand.id == AppBrandId.zenithHabits &&
                              _index == 1 &&
                              value != 1;
                          if (leavingTimer) {
                            context.read<TrackerController>().stopAmbient();
                          }
                          setState(() => _index = value);
                        },
                        type: BottomNavigationBarType.fixed,
                        backgroundColor: Colors.transparent,
                        selectedItemColor: brand.primaryColor,
                        unselectedItemColor: scheme.onSurfaceVariant,
                        selectedFontSize: 12,
                        unselectedFontSize: 11,
                        elevation: 0,
                        items: [
                          for (final tab in tabs)
                            BottomNavigationBarItem(
                              icon: Icon(tab.icon),
                              activeIcon: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: brand.primaryColor.withValues(
                                    alpha: 0.18,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(tab.activeIcon),
                                ),
                              ),
                              label: tab.label,
                              tooltip: tab.label,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec(this.label, this.icon, this.activeIcon, this.page);

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget page;
}

int? _tabFor(AppBrandId id, NativePushSection section) {
  return switch (id) {
    AppBrandId.zenithHabits when section == NativePushSection.habitList => 0,
    AppBrandId.ancientCodex when section == NativePushSection.dailyQuiz => 1,
    _ => null,
  };
}

List<_TabSpec> _tabsFor(BuildContext context, AppBrandId id) {
  String label(String english) => context.tr(english);
  return switch (id) {
    AppBrandId.ancientCodex => [
      _TabSpec(
        label('Lessons'),
        Icons.menu_book_outlined,
        Icons.menu_book,
        const LessonsScreen(),
      ),
      _TabSpec(
        label('Trials'),
        Icons.quiz_outlined,
        Icons.quiz,
        const TrialsScreen(),
      ),
      _TabSpec(
        label('Workshop'),
        Icons.grid_view_outlined,
        Icons.grid_view_rounded,
        const WorkshopScreen(),
      ),
      _TabSpec(
        label('Progress'),
        Icons.donut_large_outlined,
        Icons.donut_large,
        const CodexProgressScreen(),
      ),
    ],
    AppBrandId.zenithHabits => [
      _TabSpec(
        label('Day'),
        Icons.wb_sunny_outlined,
        Icons.wb_sunny,
        const DashboardHome(),
      ),
      _TabSpec(
        label('Timer'),
        Icons.timer_outlined,
        Icons.timer,
        const FocusTimerScreen(),
      ),
      _TabSpec(
        label('Analytics'),
        Icons.bar_chart_outlined,
        Icons.bar_chart,
        const AnalyticsScreen(),
      ),
    ],
    AppBrandId.apexCalc => [
      _TabSpec(
        label('Calc'),
        Icons.calculate_outlined,
        Icons.calculate,
        const ApexCalcScreen(),
      ),
      _TabSpec(
        label('Converter'),
        Icons.swap_horiz,
        Icons.currency_exchange,
        const ApexConvertScreen(),
      ),
      _TabSpec(
        label('History'),
        Icons.history,
        Icons.history_toggle_off,
        const ApexHistoryScreen(),
      ),
    ],
  };
}
