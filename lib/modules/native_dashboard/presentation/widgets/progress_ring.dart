import 'package:flutter/material.dart';

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    required this.color,
    this.label = '',
    this.size = 72,
    this.labelColor = Colors.white,
    this.glow = false,
  });

  final double progress;
  final Color color;
  final String label;
  final double size;
  final Color labelColor;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return GlowRing(
      size: size,
      progress: progress,
      color: color,
      glow: glow,
      label: label,
      fontSize: size < 80 ? 13 : 18,
      labelColor: labelColor,
    );
  }
}

class GlowRing extends StatelessWidget {
  const GlowRing({
    super.key,
    required this.size,
    required this.progress,
    required this.color,
    required this.glow,
    required this.label,
    required this.fontSize,
    this.labelKey,
    this.labelColor = Colors.white,
  });

  final double size;
  final double progress;
  final Color color;
  final bool glow;
  final String label;
  final double fontSize;
  final Key? labelKey;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    final value = progress.isNaN ? 0.0 : progress.clamp(0.0, 1.0).toDouble();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: glow
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.55),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: size < 80 ? 7 : 8,
              strokeCap: StrokeCap.round,
              color: color,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Text(
            label,
            key: labelKey,
            style: TextStyle(
              color: labelColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
