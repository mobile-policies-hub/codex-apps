import 'package:flutter/material.dart';

import 'package:hybrid_app/modules/native_dashboard/presentation/widgets/progress_ring.dart';

class GoalRing extends StatelessWidget {
  const GoalRing({
    super.key,
    required this.progress,
    required this.label,
    this.color = const Color(0xFFE7C36A),
    this.glow = false,
    this.size = 64,
  });

  final double progress;
  final String label;
  final Color color;
  final bool glow;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GlowRing(
      size: size,
      progress: progress,
      color: color,
      glow: glow,
      label: label,
      labelKey: const Key('step-percent'),
      fontSize: size < 80 ? 16 : 20,
    );
  }
}
