import 'package:hybrid_app/core/config/push_app_id.dart';

/// Provider seam for OneSignal or FCM.
///
/// [kPushAppId] picks the backend. The UI talks only to
/// [PushNotificationService].
abstract class PushBackend {
  String get appId;

  /// Prepare the provider. Must not ask for notification permission.
  Future<void> initialize();

  /// System permission prompt. Call only after the in-app soft prompt.
  Future<bool> requestPermission();

  Future<void> showLocal({
    required String title,
    required String body,
    String? payloadUrl,
  });

  /// Stores the current segment. A remote backend also sends each entry.
  Future<void> addTags(Map<String, String> tags);
}

/// Tag writer with the same shape as `OneSignal.User.addTag`.
abstract class PushUserTags {
  Future<void> addTag(String key, String value);
}

/// Substitution point for the OneSignal Flutter SDK.
///
/// When `onesignal_flutter` is linked, the body becomes
/// `OneSignal.User.addTag(key, value)`.
class OneSignalUserTags implements PushUserTags {
  const OneSignalUserTags();

  @override
  Future<void> addTag(String key, String value) async {
    // OneSignal.User.addTag(key, value);
  }
}

/// In-app backend used until a real App ID is set.
class LocalPushBackend implements PushBackend {
  LocalPushBackend({this.appId = ''});

  @override
  final String appId;

  bool permissionRequested = false;
  final Map<String, String> tags = {};

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async {
    permissionRequested = true;
    return true;
  }

  @override
  Future<void> showLocal({
    required String title,
    required String body,
    String? payloadUrl,
  }) async {}

  @override
  Future<void> addTags(Map<String, String> tags) async {
    this.tags
      ..clear()
      ..addAll(tags);
  }
}

/// Holds [kPushAppId] and forwards segments through [PushUserTags].
class RemotePushBackend extends LocalPushBackend {
  RemotePushBackend(String appId, {PushUserTags? userTags})
    : _userTags = userTags ?? const OneSignalUserTags(),
      super(appId: appId);

  final PushUserTags _userTags;

  @override
  Future<void> addTags(Map<String, String> tags) async {
    await super.addTags(tags);
    for (final entry in tags.entries) {
      await _userTags.addTag(entry.key, entry.value);
    }
  }
}

PushBackend createPushBackend({String appId = kPushAppId}) {
  if (appId.isEmpty) return LocalPushBackend();
  return RemotePushBackend(appId);
}
