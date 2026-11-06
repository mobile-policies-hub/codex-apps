import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:hybrid_app/core/l10n/app_text.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/widgets/brand_card.dart';

/// Box breathing: four counts in, hold, out, hold.
class BreathCard extends StatefulWidget {
  const BreathCard({super.key});

  @override
  State<BreathCard> createState() => _BreathCardState();
}

class _BreathCardState extends State<BreathCard> {
  static const _phases = ['Inhale', 'Hold', 'Exhale', 'Hold'];
  Timer? _timer;
  int _phase = 0;
  int _left = 4;
  bool _running = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      _left -= 1;
      if (_left > 0) return;
      _phase = (_phase + 1) % _phases.length;
      _left = 4;
    });
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final growing = _phase == 0;
    final shrinking = _phase == 2;
    final size = growing
        ? 92.0 + (4 - _left) * 14
        : shrinking
        ? 148.0 - (4 - _left) * 14
        : _phase == 1
        ? 148.0
        : 92.0;
    return BrandCard(
      child: Column(
        children: [
          Text(
            context.tr('Box breathing'),
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('Four counts each side. One quiet minute.'),
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeInOut,
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  scheme.primary.withValues(alpha: 0.85),
                  scheme.primary.withValues(alpha: 0.15),
                ],
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              _running ? '$_left' : '4',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.tr(_phases[_phase]),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('breath-toggle'),
            onPressed: _toggle,
            child: Text(context.tr(_running ? 'Stop' : 'Begin')),
          ),
        ],
      ),
    );
  }
}
