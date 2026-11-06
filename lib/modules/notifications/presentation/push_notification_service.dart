import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'package:hybrid_app/core/config/app_config.dart';
import 'package:hybrid_app/core/config/push_app_id.dart';
import 'package:hybrid_app/modules/notifications/domain/push_backend.dart';
import 'package:hybrid_app/modules/notifications/domain/push_payload.dart';

enum PushPermission { unknown, granted, denied }

class LocalNotification {
  const LocalNotification({
    required this.title,
    required this.body,
    this.payloadUrl,
  });

  final String title;
  final String body;
  final String? payloadUrl;
}

/// App-wide push entry point. [AppScope] owns the single instance.
class PushNotificationService extends ChangeNotifier {
  PushNotificationService({PushBackend? backend, String? appId})
    : appId = appId ?? kPushAppId,
      _backend = backend ?? createPushBackend(appId: appId ?? kPushAppId);

  final String appId;
  final PushBackend _backend;

  PushPermission permission = PushPermission.unknown;
  AppConfig segment = const AppConfig();
  Map<String, String> userTags = const {};
  LocalNotification? preview;
  String? lastPayload;
  int generation = 0;
  bool _initialized = false;

  Future<void> initialize() {
    if (_initialized) return Future<void>.value();
    _initialized = true;
    return _backend.initialize();
  }

  bool get isDynamicContentEnabled => segment.isDynamicContentEnabled;

  AppDisplayMode get displayMode => segment.displayMode;

  UserCategory get userCategory => segment.userCategory;

  /// Records the launch mode so the test alert can pick a payload.
  void bindDynamicContent(bool enabled) {
    segment = const AppConfig().alignedWith(dynamicContent: enabled);
  }

  /// Tags the device for the launch mode chosen by remote config.
  ///
  /// Dynamic content uses [AppDisplayMode.extended] and
  /// [UserCategory.primaryUser]. The native shell uses
  /// [AppDisplayMode.standard] and [UserCategory.defaultUser]. A non-empty
  /// [geo] is stored as `geo`. [RemotePushBackend] sends each tag with
  /// `OneSignal.User.addTag`.
  Future<void> updateUserSegment({
    required bool isDynamicContentEnabled,
    String? geo,
  }) async {
    segment = const AppConfig().alignedWith(
      dynamicContent: isDynamicContentEnabled,
    );
    final tags = Map<String, String>.from(segment.segmentTags);
    final region = geo?.trim();
    if (region != null && region.isNotEmpty) {
      tags['geo'] = region;
    }
    userTags = Map.unmodifiable(tags);
    await _backend.addTags(tags);
  }

  Future<bool> requestPermission() async {
    final granted = await _backend.requestPermission();
    permission = granted ? PushPermission.granted : PushPermission.denied;
    notifyListeners();
    return granted;
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payloadUrl,
  }) async {
    preview = LocalNotification(
      title: title,
      body: body,
      payloadUrl: payloadUrl,
    );
    notifyListeners();
    await _backend.showLocal(title: title, body: body, payloadUrl: payloadUrl);
  }

  Future<void> showTestNotification() {
    final payload = isDynamicContentEnabled
        ? 'https://app.example.com/from-notification'
        : 'habits';
    return showLocalNotification(
      title: 'Habit reminder',
      body: isDynamicContentEnabled
          ? 'Open the linked page'
          : 'Open your habit list',
      payloadUrl: payload,
    );
  }

  /// Click path for a system push and for the in-app test alert.
  void onNotificationOpened(String? payloadUrl) {
    lastPayload = payloadUrl;
    generation += 1;
    preview = null;
    notifyListeners();
  }

  Uri? webDestination() {
    return pushWebUri(
      isDynamicContentEnabled: isDynamicContentEnabled,
      payload: lastPayload,
    );
  }

  NativePushSection nativeDestination() => nativeSectionFor(lastPayload);

  static PushNotificationService? maybeOf(BuildContext context) {
    try {
      return Provider.of<PushNotificationService>(context);
    } on ProviderNotFoundException {
      return null;
    }
  }
}
