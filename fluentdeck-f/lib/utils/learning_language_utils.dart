import '../models/speaking_preferences.dart';

/// Resolves which language code to use for deck/note filters and saves.
class LearningLanguageUtils {
  LearningLanguageUtils._();

  /// When sync is on, always use practice language. When off, use [manualFilter] unless 'all'.
  static String? effectiveFilterCode({
    required bool syncLearningLanguage,
    required String practiceLanguage,
    String? manualFilter,
  }) {
    if (syncLearningLanguage) return practiceLanguage;
    final manual = manualFilter?.trim();
    if (manual == null || manual.isEmpty || manual == 'all') return null;
    return manual;
  }

  static String defaultSaveLanguage(SpeakingPreferences prefs) =>
      prefs.practiceLanguage;

  static String languageLabel(String code) =>
      SpeakingPreferences.practiceLanguageOptions[code] ?? code.toUpperCase();

  static List<MapEntry<String, String>> filterOptions() => [
    const MapEntry('all', 'All languages'),
    ...SpeakingPreferences.practiceLanguageOptions.entries,
  ];
}
