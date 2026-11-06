import 'package:flutter/material.dart';

import 'package:hybrid_app/core/config/app_brand_config.dart';
import 'package:hybrid_app/core/l10n/app_text.dart';
import 'package:hybrid_app/modules/native_dashboard/domain/tracker_format.dart';

class WeekBarChart extends StatelessWidget {
  const WeekBarChart({
    super.key,
    required this.values,
    required this.selectedIndex,
    required this.accent,
    this.barHeight = 72,
    this.subtitle = 'Score by day',
    this.semanticsLabel = 'Focus scores for the week',
  });

  final List<int> values;
  final int selectedIndex;
  final Color accent;
  final double barHeight;
  final String subtitle;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final brand = AppBrand.of(context);
    final scheme = Theme.of(context).colorScheme;
    final peak = values.fold<int>(0, (max, value) => value > max ? value : max);
    final scale = peak == 0 ? 1 : peak;

    return Semantics(
      container: true,
      label: semanticsLabel,
      child: DecoratedBox(
        key: const Key('week-chart'),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(brand.cardColor, Colors.white, 0.05)!,
              brand.cardColor,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Week',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: barHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var index = 0; index < values.length; index++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: _Bar(
                            fraction: _fraction(values[index], scale),
                            label: context.tr(weekDayLabels[index]),
                            selected: index == selectedIndex,
                            accent: accent,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _fraction(int value, int scale) {
    if (value <= 0) return 0.06;
    final fraction = value / scale;
    return fraction < 0.08 ? 0.08 : fraction;
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.fraction,
    required this.label,
    required this.selected,
    required this.accent,
  });

  final double fraction;
  final String label;
  final bool selected;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? accent : const Color(0xFF334155);
    final labelColor = selected ? accent : scheme.onSurfaceVariant;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: fraction,
              widthFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
