import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:hybrid_app/core/config/active_brand.dart';
import 'package:hybrid_app/core/config/brand_support_email.dart';
import 'package:hybrid_app/core/config/brand_xcconfig_reader.dart';

/// Which native experience the dashboard should build.
enum AppBrandId { ancientCodex, zenithHabits, apexCalc }

/// Name, palette, bundle id, and native title for one product brand.
///
/// `dart run tool/select_brand.dart` writes [current] and the iOS
/// `CFBundleDisplayName` together.
class AppBrandConfig {
  const AppBrandConfig({
    required this.appName,
    required this.primaryColor,
    required this.nativeDashboardTitle,
    this.id = AppBrandId.zenithHabits,
    this.bundleId = 'com.zenithhabits.app',
    this.iconSetName = 'AppIconZenith',
    this.supportEmail = activeBrandSupportEmail,
    this.backgroundColor = const Color(0xFF0F172A),
    this.cardColor = const Color(0xFF1E293B),
  });

  static const ancientCodex = AppBrandConfig(
    id: AppBrandId.ancientCodex,
    appName: 'Ancient Codex',
    bundleId: 'com.ancientcodex.app',
    iconSetName: 'AppIconAncient',
    supportEmail: 'dev.outbox.88@outlook.com',
    primaryColor: Color(0xFFE0A93B),
    backgroundColor: Color(0xFF1A0505),
    cardColor: Color(0xFF2D0D0D),
    nativeDashboardTitle: 'Ancient Codex',
  );

  static const zenithHabits = AppBrandConfig(
    id: AppBrandId.zenithHabits,
    appName: 'Zenith Habits',
    bundleId: 'com.zenithhabits.app',
    iconSetName: 'AppIconZenith',
    supportEmail: 'dev.outbox.88@outlook.com',
    primaryColor: Color(0xFF10B981),
    backgroundColor: Color(0xFF0F172A),
    cardColor: Color(0xFF1E293B),
    nativeDashboardTitle: 'Today',
  );

  static const apexCalc = AppBrandConfig(
    id: AppBrandId.apexCalc,
    appName: 'Apex Calc',
    bundleId: 'com.apexcalc.app',
    iconSetName: 'AppIconApex',
    supportEmail: 'dev.outbox.88@outlook.com',
    primaryColor: Color(0xFFFF9F1C),
    backgroundColor: Color(0xFF0A1128),
    cardColor: Color(0xFF1C2541),
    nativeDashboardTitle: 'Apex Calc',
  );

  /// Selected brand. [supportEmail] is `SUPPORT_EMAIL` from Brand.xcconfig
  /// when that file can be read, otherwise the generated fallback.
  static AppBrandConfig get current {
    final selected = forIdName(activeBrandIdName);
    final email = readBrandSupportEmail() ?? activeBrandSupportEmail;
    return selected.withSupportEmail(email);
  }

  /// Applies the copy of Brand.xcconfig packaged with the app.
  ///
  /// Info.plist reads the same `SUPPORT_EMAIL` key at build time. Settings
  /// displays [supportEmail] from this config, so an edit to Brand.xcconfig
  /// reaches both on the next build without a UI change.
  static Future<AppBrandConfig> loadPackaged() async {
    try {
      final source = await rootBundle.loadString(brandXcconfigAsset);
      final email = supportEmailFromXcconfig(source);
      if (email != null) return current.withSupportEmail(email);
    } on Object {
      // Missing asset falls back to the project file or generated constant.
    }
    return current;
  }

  AppBrandConfig withSupportEmail(String email) {
    if (email == supportEmail) return this;
    return AppBrandConfig(
      id: id,
      appName: appName,
      bundleId: bundleId,
      iconSetName: iconSetName,
      supportEmail: email,
      primaryColor: primaryColor,
      backgroundColor: backgroundColor,
      cardColor: cardColor,
      nativeDashboardTitle: nativeDashboardTitle,
    );
  }

  static AppBrandConfig forIdName(String name) {
    return switch (name) {
      'ancientCodex' => ancientCodex,
      'apexCalc' => apexCalc,
      _ => zenithHabits,
    };
  }

  final AppBrandId id;
  final String appName;
  final String bundleId;
  final String iconSetName;
  final String supportEmail;
  final Color primaryColor;
  final Color backgroundColor;
  final Color cardColor;
  final String nativeDashboardTitle;
}

/// Darker companion of [primary], used for the dashboard hero.
Color brandDeep(Color primary) {
  final hsl = HSLColor.fromColor(primary);
  return hsl
      .withLightness((hsl.lightness * 0.45).clamp(0.12, 0.42))
      .withSaturation(hsl.saturation.clamp(0.0, 1.0))
      .toColor();
}

ThemeData buildAppTheme(AppBrandConfig brand) {
  final scheme = ColorScheme.fromSeed(seedColor: brand.primaryColor)
      .copyWith(primary: brand.primaryColor);
  return ThemeData(colorScheme: scheme);
}

/// Lets a web preview swap [AppBrand] without rebuilding the project.
class BrandPreview extends InheritedWidget {
  const BrandPreview({super.key, required this.onSelect, required super.child});

  final ValueChanged<AppBrandConfig> onSelect;

  static BrandPreview? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<BrandPreview>();
  }

  @override
  bool updateShouldNotify(BrandPreview oldWidget) => false;
}

class AppBrand extends InheritedWidget {
  const AppBrand({super.key, required this.config, required super.child});

  final AppBrandConfig config;

  static AppBrandConfig of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppBrand>();
    return scope?.config ?? AppBrandConfig.current;
  }

  @override
  bool updateShouldNotify(AppBrand oldWidget) {
    final next = config;
    final previous = oldWidget.config;
    return next.id != previous.id ||
        next.appName != previous.appName ||
        next.bundleId != previous.bundleId ||
        next.iconSetName != previous.iconSetName ||
        next.supportEmail != previous.supportEmail ||
        next.primaryColor != previous.primaryColor ||
        next.backgroundColor != previous.backgroundColor ||
        next.cardColor != previous.cardColor ||
        next.nativeDashboardTitle != previous.nativeDashboardTitle;
  }
}
