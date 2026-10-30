import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One app (interface) language. Separate from the practice language the
/// tutor speaks. Strings live in `assets/locales/<code>.json`; a language is
/// only offered once its file exists. See docs/app-languages.md.
class AppLanguageOption {
  const AppLanguageOption(
    this.code,
    this.nativeName,
    this.englishName, {
    this.rtl = false,
  });

  final String code;

  /// Shown in the picker, so people can find their language in any UI language.
  final String nativeName;
  final String englishName;
  final bool rtl;
}

class AppLanguage {
  static const String _defaultLanguage = 'en';
  static const String _prefsKey = 'app_language_override';
  static const String _enDefaultMigrationKey = 'app_language_default_en_v1';

  /// Interface languages, in picker order. Tier 1 = core markets, tier 2 =
  /// large English-learner markets (docs/app-languages.md). Armenian is
  /// planned for later.
  static const List<AppLanguageOption> options = [
    AppLanguageOption('en', 'English', 'English'),
    // Tier 1
    AppLanguageOption('es', 'Español', 'Spanish'),
    AppLanguageOption('pt', 'Português (Brasil)', 'Portuguese (Brazil)'),
    AppLanguageOption('tr', 'Türkçe', 'Turkish'),
    AppLanguageOption('ru', 'Русский', 'Russian'),
    // Tier 2
    AppLanguageOption('vi', 'Tiếng Việt', 'Vietnamese'),
    AppLanguageOption('id', 'Bahasa Indonesia', 'Indonesian'),
    AppLanguageOption('ja', '日本語', 'Japanese'),
    AppLanguageOption('ko', '한국어', 'Korean'),
    AppLanguageOption('ar', 'العربية', 'Arabic', rtl: true),
    // Existing
    AppLanguageOption('de', 'Deutsch', 'German'),
  ];

  static final Set<String> _supportedLanguages = {
    for (final o in options) o.code,
  };

  static AppLanguageOption? optionFor(String code) {
    for (final o in options) {
      if (o.code == code) return o;
    }
    return null;
  }

  static String? _match(String? raw, Set<String> available) {
    if (raw == null || raw.trim().isEmpty) return null;
    final code = raw.trim().toLowerCase().split(RegExp('[-_]')).first;
    return available.contains(code) ? code : null;
  }

  /// Saved choice → phone language (if translated) → `APP_LANGUAGE` → English.
  /// [available] = languages whose locale file ships with the app.
  static Future<String> resolveCurrent({
    Set<String>? available,
    String? deviceLanguage,
  }) async {
    final usable = (available ?? _supportedLanguages).intersection(
      _supportedLanguages,
    );
    final prefs = await SharedPreferences.getInstance();
    // Legacy product default was German; drop sticky `de` override once so English wins.
    if (prefs.getBool(_enDefaultMigrationKey) != true) {
      await prefs.setBool(_enDefaultMigrationKey, true);
      if (prefs.getString(_prefsKey) == 'de') {
        await prefs.remove(_prefsKey);
      }
    }
    String? fromEnv;
    try {
      fromEnv = dotenv.env['APP_LANGUAGE'];
    } catch (_) {
      // dotenv not loaded (tests).
    }
    return _match(prefs.getString(_prefsKey), usable) ??
        _match(
          deviceLanguage ?? PlatformDispatcher.instance.locale.languageCode,
          usable,
        ) ??
        _match(fromEnv, usable) ??
        _defaultLanguage;
  }

  static Future<void> setOverride(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      _match(language, _supportedLanguages) ?? _defaultLanguage,
    );
  }

  static Set<String> get supportedLanguages => _supportedLanguages;
}
