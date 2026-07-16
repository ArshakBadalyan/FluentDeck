import 'package:shared_preferences/shared_preferences.dart';

/// Tracks one-time contextual help hints (Phase 5G-3).
class DecksHelpHintsStore {
  DecksHelpHintsStore._();
  static final DecksHelpHintsStore instance = DecksHelpHintsStore._();

  static const cardBrowserKey = 'decks_help_hint_card_browser_v1';
  static const statisticsKey = 'decks_help_hint_statistics_v1';

  Future<bool> hasSeen(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  Future<void> markSeen(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, true);
  }
}
