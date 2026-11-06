import 'package:flutter/material.dart';

import 'package:hybrid_app/core/config/app_brand_config.dart';

class BrandCard extends StatelessWidget {
  const BrandCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.gold = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final brand = AppBrand.of(context);
    final base = brand.cardColor;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: gold
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF5A3412),
                  Color(0xFF2A1408),
                  Color(0xFF1A0A04),
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(base, Colors.white, 0.06)!,
                  base,
                  Color.lerp(base, Colors.black, 0.28)!,
                ],
              ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
