import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:hybrid_app/core/config/app_brand_config.dart';
import 'package:hybrid_app/core/l10n/app_text.dart';
import 'package:hybrid_app/modules/routing/presentation/root_router.dart';

class HybridApp extends StatelessWidget {
  const HybridApp({super.key});

  @override
  Widget build(BuildContext context) {
    final brand = AppBrand.of(context);
    final language = AppText.maybeOf(context)?.code ?? 'en';
    return MaterialApp(
      title: brand.appName,
      debugShowCheckedModeBanner: false,
      locale: Locale(language),
      supportedLocales: AppText.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildAppTheme(brand),
      home: const RootRouter(),
    );
  }
}
