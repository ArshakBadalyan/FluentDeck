import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide theme (Step 6 — not Decks-only).
class ThemeSettingsStore extends ChangeNotifier {
  ThemeSettingsStore._();
  static final ThemeSettingsStore instance = ThemeSettingsStore._();

  static const _key = 'app_theme_mode_v1';
  static const _legacyDecksDarkKey = 'review_settings_v1_darkMode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    if (stored != null) {
      _themeMode = _parse(stored);
    } else {
      final legacyDark = prefs.getBool(_legacyDecksDarkKey) ?? false;
      _themeMode = legacyDark ? ThemeMode.dark : ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
    notifyListeners();
  }

  String label(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System default';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  ThemeMode _parse(String raw) {
    return ThemeMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => ThemeMode.system,
    );
  }
}
