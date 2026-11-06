import 'package:flutter/material.dart';

import 'package:hybrid_app/core/config/app_brand_config.dart';

const goldGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFF6E2A8), Color(0xFFE0A93B), Color(0xFF8A5A12)],
);

const glassBorder = BorderSide(color: Color(0x14FFFFFF), width: 1);

/// Desktop gutter behind the phone-width column.
class MobileFrame extends StatelessWidget {
  const MobileFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF161B26), Color(0xFF07090E), Color(0xFF10131A)],
        ),
      ),
      child: SizedBox.expand(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                border: Border.symmetric(vertical: glassBorder),
              ),
              child: SizedBox(width: double.infinity, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class BrandBackdrop extends StatelessWidget {
  const BrandBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brand = AppBrand.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _stops(brand),
        ),
      ),
      child: child,
    );
  }

  List<Color> _stops(AppBrandConfig brand) {
    return switch (brand.id) {
      AppBrandId.ancientCodex => const [
        Color(0xFF4A1A10),
        Color(0xFF1A0505),
        Color(0xFF070202),
      ],
      AppBrandId.zenithHabits => const [
        Color(0xFF134E3A),
        Color(0xFF0F172A),
        Color(0xFF070B14),
      ],
      AppBrandId.apexCalc => const [
        Color(0xFF243656),
        Color(0xFF0A1128),
        Color(0xFF050814),
      ],
    };
  }
}

/// Saturated, scrollable column used by every native screen.
class BrandFeed extends StatelessWidget {
  const BrandFeed({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 28),
  });

  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

class SoftTag extends StatelessWidget {
  const SoftTag({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Colors.white;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            color: tint == Colors.white ? Colors.white60 : tint,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
