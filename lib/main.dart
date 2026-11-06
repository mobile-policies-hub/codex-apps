import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hybrid_app/app/app_scope.dart';
import 'package:hybrid_app/app/hybrid_app.dart';
import 'package:provider/provider.dart';

import 'package:hybrid_app/core/config/api_config.dart';
import 'package:hybrid_app/core/config/app_brand_config.dart';
import 'package:hybrid_app/core/config/web_document_config.dart';
import 'package:hybrid_app/core/l10n/app_text.dart';
import 'package:hybrid_app/modules/native_dashboard/data/local_vault.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/device_services.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/habit_alarms.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/tracker_controller.dart';
import 'package:hybrid_app/modules/remote_config/data/shared_preferences_remote_config_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final brand = await AppBrandConfig.loadPackaged();
  final preferences = await SharedPreferences.getInstance();
  final app = WebDocumentConfigScope(
    config: WebDocumentConfig.current,
    child: AppScope(
      config: ApiConfig.fromEnvironment(),
      configStore: SharedPreferencesRemoteConfigStore(preferences),
      child: const HybridApp(),
    ),
  );
  runApp(
    ChangeNotifierProvider<AppText>(
      create: (_) => AppText(preferences),
      child: DeviceServices(
        vault: PreferencesVault(preferences),
        alarms: kIsWeb ? const NoopHabitAlarms() : LocalHabitAlarms(),
        child: kIsWeb
            ? WebBrandHost(initialBrand: brand, child: app)
            : AppBrand(config: brand, child: app),
      ),
    ),
  );
}

class WebBrandHost extends StatefulWidget {
  const WebBrandHost({
    super.key,
    required this.initialBrand,
    required this.child,
  });

  final AppBrandConfig initialBrand;
  final Widget child;

  @override
  State<WebBrandHost> createState() => _WebBrandHostState();
}

class _WebBrandHostState extends State<WebBrandHost> {
  late AppBrandConfig _config = widget.initialBrand;

  @override
  Widget build(BuildContext context) {
    return AppBrand(
      config: _config,
      child: BrandPreview(
        onSelect: (value) => setState(() => _config = value),
        child: widget.child,
      ),
    );
  }
}
