import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguage {
  static const String _defaultLanguage = 'en';
  static const Set<String> _supportedLanguages = {'de', 'en'};
  static const String _prefsKey = 'app_language_override';
  static const String _enDefaultMigrationKey = 'app_language_default_en_v1';

  static String _normalize(String? raw) {
    if (raw == null || raw.isEmpty) {
      return _defaultLanguage;
    }

    final normalized = raw.trim().toLowerCase();
    if (_supportedLanguages.contains(normalized)) {
      return normalized;
    }

    return _defaultLanguage;
  }

  static Future<String> resolveCurrent() async {
    final prefs = await SharedPreferences.getInstance();
    // Legacy product default was German; drop sticky `de` override once so English wins.
    if (prefs.getBool(_enDefaultMigrationKey) != true) {
      await prefs.setBool(_enDefaultMigrationKey, true);
      if (prefs.getString(_prefsKey) == 'de') {
        await prefs.remove(_prefsKey);
      }
    }
    final override = prefs.getString(_prefsKey);
    final fromEnv = dotenv.env['APP_LANGUAGE'];
    final resolved = (override != null && override.isNotEmpty)
        ? _normalize(override)
        : _normalize(fromEnv);
    return resolved;
  }

  static Future<void> setOverride(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _normalize(language));
  }

  static Set<String> get supportedLanguages => _supportedLanguages;
}
