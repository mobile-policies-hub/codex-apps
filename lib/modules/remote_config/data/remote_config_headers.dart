import 'package:hybrid_app/core/config/app_brand_config.dart';
import 'package:hybrid_app/core/config/brand_support_email.dart';
import 'package:hybrid_app/core/config/brand_xcconfig_reader.dart';

/// One attempt. A timeout, transport error, or bad status does not retry.
const Duration remoteConfigFetchTimeout = Duration(seconds: 3);

/// Headers for one brand's startup configuration request.
Map<String, String> utilityRequestHeaders({
  required String appName,
  required String bundleId,
}) {
  return {
    'Accept': 'application/json',
    'X-App-Brand': appName,
    'X-App-Bundle-Id': bundleId,
    'User-Agent': '$appName/1.0.0 ($bundleId)',
  };
}

/// Identity sent with the startup configuration request.
///
/// Name and bundle id prefer `Brand.xcconfig` (`APP_DISPLAY_NAME`,
/// `PRODUCT_BUNDLE_IDENTIFIER`) and fall back to the selected [AppBrandConfig].
Map<String, String> remoteConfigHeaders({AppBrandConfig? brand}) {
  final selected = brand ?? AppBrandConfig.current;
  final source = readBrandXcconfig();
  return utilityRequestHeaders(
    appName: _value(source, 'APP_DISPLAY_NAME') ?? selected.appName,
    bundleId: _value(source, 'PRODUCT_BUNDLE_IDENTIFIER') ?? selected.bundleId,
  );
}

String? _value(String? source, String key) {
  if (source == null) return null;
  return xcconfigValue(source, key);
}
