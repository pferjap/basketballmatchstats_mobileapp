import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preference key for the push-notification opt-in.
const String kNotificationsEnabledKey = 'settings.notificationsEnabled';

/// Preference key for the selected UI language.
const String kLanguageCodeKey = 'settings.languageCode';

/// Languages offered by the settings screen.
///
/// Only Spanish ships today; the selector exists so the ARB-based i18n work has
/// a place to plug into (Agent_Mobile.md §5, `core/l10n`).
const Map<String, String> kSupportedLanguages = <String, String>{
  'es': 'Español',
  'en': 'English',
};

/// App version string, e.g. "1.0.0 (1)".
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
});

/// User preferences persisted in `shared_preferences` (never tokens, which
/// belong in secure storage — Agent_Mobile.md §9.1).
class SettingsPreferences {
  const SettingsPreferences({
    this.notificationsEnabled = true,
    this.languageCode = 'es',
  });

  final bool notificationsEnabled;
  final String languageCode;

  SettingsPreferences copyWith({
    bool? notificationsEnabled,
    String? languageCode,
  }) {
    return SettingsPreferences(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      languageCode: languageCode ?? this.languageCode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsPreferences &&
          other.notificationsEnabled == notificationsEnabled &&
          other.languageCode == languageCode;

  @override
  int get hashCode => Object.hash(notificationsEnabled, languageCode);
}

/// Reads and writes the user's local preferences.
class SettingsController extends Notifier<SettingsPreferences> {
  @override
  SettingsPreferences build() {
    // Deferred past build() so the async read never mutates state while the
    // notifier is still being constructed.
    Future<void>.microtask(_load);
    return const SettingsPreferences();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = SettingsPreferences(
      notificationsEnabled: prefs.getBool(kNotificationsEnabledKey) ?? true,
      languageCode: prefs.getString(kLanguageCodeKey) ?? 'es',
    );
  }

  /// Toggles the notification opt-in and persists it.
  Future<void> setNotificationsEnabled(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kNotificationsEnabledKey, enabled);
  }

  /// Selects a UI language and persists it.
  Future<void> setLanguageCode(String languageCode) async {
    state = state.copyWith(languageCode: languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kLanguageCodeKey, languageCode);
  }
}

/// User preferences controller.
final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsPreferences>(
      SettingsController.new,
    );
