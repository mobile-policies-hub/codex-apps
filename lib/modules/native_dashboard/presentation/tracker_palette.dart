import 'package:flutter/material.dart';

import 'package:hybrid_app/core/config/app_brand_config.dart';

abstract final class TrackerColors {
  static const canvas = Color(0xFFF4F0E8);
  static const ink = Color(0xFF1B2420);
  static const muted = Color(0xFF6E756F);
  static const card = Color(0xFFFFFCF8);
  static const line = Color(0xFFE4DDD2);
}

class BrandSurfaces extends ThemeExtension<BrandSurfaces> {
  const BrandSurfaces({required this.deep});

  final Color deep;

  @override
  BrandSurfaces copyWith({Color? deep}) {
    return BrandSurfaces(deep: deep ?? this.deep);
  }

  @override
  BrandSurfaces lerp(ThemeExtension<BrandSurfaces>? other, double t) {
    if (other is! BrandSurfaces) return this;
    return BrandSurfaces(deep: Color.lerp(deep, other.deep, t) ?? deep);
  }
}

ThemeData buildTrackerTheme(AppBrandConfig brand) {
  const ink = Color(0xFFF8FAFC);
  const muted = Color(0xFFCBD5E1);
  final scheme =
      ColorScheme.fromSeed(
        seedColor: brand.primaryColor,
        brightness: Brightness.dark,
        surface: brand.backgroundColor,
      ).copyWith(
        primary: brand.primaryColor,
        surface: brand.backgroundColor,
        onSurface: ink,
        onSurfaceVariant: muted,
      );
  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: scheme,
    fontFamily: '.SF Pro Text',
    scaffoldBackgroundColor: brand.backgroundColor,
    extensions: [BrandSurfaces(deep: brandDeep(brand.primaryColor))],
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: '.SF Pro Display',
        color: ink,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
    ),
    sliderTheme: SliderThemeData(
      trackHeight: 4,
      activeTrackColor: brand.primaryColor,
      inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
      thumbColor: Colors.white,
      overlayColor: brand.primaryColor.withValues(alpha: 0.16),
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
      activeTickMarkColor: brand.primaryColor,
      inactiveTickMarkColor: Colors.white24,
      tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 2),
    ),
  );
}
