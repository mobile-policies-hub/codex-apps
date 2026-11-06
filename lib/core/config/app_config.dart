/// How the shell presents content after startup configuration is read.
enum AppDisplayMode {
  /// Native experience. Also the fallback for an unrecognized payload value.
  standard,

  /// Additional remote content alongside the native shell.
  extended;

  /// Maps an external token onto this enum.
  ///
  /// Recognized values are `standard`, `extended`, `white`, and `black`.
  /// Anything else, including a missing value, resolves to [standard].
  static AppDisplayMode parse(Object? raw) {
    final value = raw is String ? raw.trim().toLowerCase() : '';
    return switch (value) {
      'extended' || 'black' => AppDisplayMode.extended,
      'standard' || 'white' => AppDisplayMode.standard,
      _ => AppDisplayMode.standard,
    };
  }
}

/// Audience recorded for the signed-in install.
enum UserCategory {
  /// Store / default audience.
  defaultUser,

  /// Audience that receives the extended experience.
  primaryUser;

  /// Maps an external token onto this enum.
  ///
  /// Recognized values are `defaultUser`, `primaryUser`, `organic`, and
  /// `player`. Anything else resolves to [defaultUser].
  static UserCategory parse(Object? raw) {
    final value = raw is String ? raw.trim().toLowerCase() : '';
    return switch (value) {
      'primaryuser' || 'player' => UserCategory.primaryUser,
      'defaultuser' || 'organic' => UserCategory.defaultUser,
      _ => UserCategory.defaultUser,
    };
  }
}

/// Typed startup flags shared by remote config and the launch controllers.
class AppConfig {
  const AppConfig({
    this.isDynamicContentEnabled = false,
    this.displayMode = AppDisplayMode.standard,
    this.userCategory = UserCategory.defaultUser,
  });

  final bool isDynamicContentEnabled;
  final AppDisplayMode displayMode;
  final UserCategory userCategory;

  /// Tags sent with the install. Values are the enum names, not wire aliases.
  Map<String, String> get segmentTags => {
    'user_type': userCategory.name,
    'mode': displayMode.name,
  };

  /// Pair the boolean gate with the matching display mode and audience.
  AppConfig alignedWith({required bool dynamicContent}) {
    return AppConfig(
      isDynamicContentEnabled: dynamicContent,
      displayMode: dynamicContent
          ? AppDisplayMode.extended
          : AppDisplayMode.standard,
      userCategory: dynamicContent
          ? UserCategory.primaryUser
          : UserCategory.defaultUser,
    );
  }
}
