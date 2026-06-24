import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguage {
  static const String _defaultLanguage = 'de';
  static const Set<String> _supportedLanguages = {'de', 'en'};
  static const String _prefsKey = 'app_language_override';

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
    final override = prefs.getString(_prefsKey);
    if (override != null && override.isNotEmpty) {
      return _normalize(override);
    }
    return _normalize(dotenv.env['APP_LANGUAGE']);
  }

  static Future<void> setOverride(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _normalize(language));
  }

  static Set<String> get supportedLanguages => _supportedLanguages;
}
