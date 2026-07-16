import '../models/language_levels_snapshot.dart';
import '../models/speaking_preferences.dart';
import 'api_service.dart';

class LanguageLevelsService {
  LanguageLevelsService._();
  static final LanguageLevelsService instance = LanguageLevelsService._();

  LanguageLevelsSnapshot _cached = const LanguageLevelsSnapshot();

  LanguageLevelsSnapshot get current => _cached;

  Future<LanguageLevelsSnapshot> fetch({bool forceRefresh = false}) async {
    if (!forceRefresh && _cached.languages.isNotEmpty) {
      return _cached;
    }

    final data = await ApiService.get('user-progress/language-levels');
    if (data is Map && data['error'] == null) {
      _cached = LanguageLevelsSnapshot.fromJson(
        Map<String, dynamic>.from(data),
      );
      return _cached;
    }

    return _cached;
  }

  String languageLabel(String code) =>
      SpeakingPreferences.practiceLanguageOptions[code] ?? code.toUpperCase();
}
