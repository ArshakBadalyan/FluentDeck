import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluentdeck/models/user_progress_model.dart';
import 'package:fluentdeck/screens/onboarding/english_onboarding_screen.dart';
import 'package:fluentdeck/services/auth_service.dart';
import 'package:fluentdeck/services/token_storage.dart';
import 'package:fluentdeck/services/user_progress_service.dart';

class EnglishLevelService {
  EnglishLevelService._();
  static final EnglishLevelService instance = EnglishLevelService._();

  static const levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

  static const wordsTabLevelFilterKey = 'words_tab_level_filter';
  static const wordsTabInitialB2AppliedKey = 'words_tab_initial_b2_applied';
  static const englishLevelUserSetKey = 'english_level_user_set';

  /// Default CEFR level for new users (onboarding, lessons, profile).
  static const defaultLevel = 'A1';

  /// Words tab level filter: A1 on first visit only, then persisted user choice.
  Future<String> resolveWordsTabLevelFilter({String allLevelsLabel = 'All'}) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(wordsTabInitialB2AppliedKey) != true) {
      await prefs.setBool(wordsTabInitialB2AppliedKey, true);
      await prefs.setString(wordsTabLevelFilterKey, defaultLevel);
      return defaultLevel;
    }
    return prefs.getString(wordsTabLevelFilterKey) ?? allLevelsLabel;
  }

  Future<void> saveWordsTabLevelFilter(String level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(wordsTabLevelFilterKey, level);
  }

  Future<String> getLevel() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(kEnglishLevelPrefsKey);
    final userSet = prefs.getBool(englishLevelUserSetKey) == true;
    // Prior product default was B2; migrate unset installs to A1.
    if (!userSet && (stored == null || stored == 'B2' || stored == 'B1')) {
      await saveLocal(defaultLevel);
      return defaultLevel;
    }
    return stored!;
  }

  Future<void> saveLocal(String level) async {
    if (!levels.contains(level)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kEnglishLevelPrefsKey, level);
  }

  /// Called from onboarding — marks level as user-chosen so sync won't overwrite with server default.
  Future<void> setLevelFromOnboarding(String level) async {
    if (!levels.contains(level)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kEnglishLevelPrefsKey, level);
    await prefs.setBool(englishLevelUserSetKey, true);
    await prefs.setString(wordsTabLevelFilterKey, level);
    await prefs.setBool(wordsTabInitialB2AppliedKey, true);
  }

  /// Server wins when set; otherwise pushes local onboarding choice to Strapi.
  Future<void> syncOnAppStart() async {
    final userId = await TokenStorage.getUserId();
    if (userId == null) return;

    final res = await AuthService.getUser();
    if (res['status'] != 'success' || res['user'] is! Map) return;

    final user = Map<String, dynamic>.from(res['user'] as Map);
    final serverLevel = user['english_level']?.toString();
    final prefs = await SharedPreferences.getInstance();
    final localLevel = prefs.getString(kEnglishLevelPrefsKey);
    final userSetLevel = prefs.getBool(englishLevelUserSetKey) == true;

    if (userSetLevel && localLevel != null && levels.contains(localLevel)) {
      if (serverLevel != localLevel) {
        await AuthService.updateUser({'english_level': localLevel});
      }
      await _syncProgressLevel(localLevel);
      return;
    }

    if (serverLevel != null && levels.contains(serverLevel)) {
      await saveLocal(serverLevel);
      await _syncProgressLevel(serverLevel);
      return;
    }

    if (localLevel != null && levels.contains(localLevel)) {
      await AuthService.updateUser({'english_level': localLevel});
      await _syncProgressLevel(localLevel);
      return;
    }

    await saveLocal(defaultLevel);
    await AuthService.updateUser({'english_level': defaultLevel});
    await _syncProgressLevel(defaultLevel);
  }

  Future<void> applyLevelLocally(String level) async {
    await saveLocal(level);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(englishLevelUserSetKey, true);
    await _syncProgressLevel(level);
  }

  /// Saves locally and on Strapi when authenticated.
  Future<bool> setLevel(String level) async {
    if (!levels.contains(level)) return false;
    await saveLocal(level);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(englishLevelUserSetKey, true);

    final userId = await TokenStorage.getUserId();
    if (userId == null) return true;

    final res = await AuthService.updateUser({'english_level': level});
    if (res['status'] != 'success') return false;

    await _syncProgressLevel(level);
    return true;
  }

  Future<void> _syncProgressLevel(String level) async {
    try {
      final progress = await UserProgressService.instance.createIfMissing();
      if (progress.currentLevel == level) return;
      await UserProgressService.instance.updateProgress(
        UserProgressModel(
          id: progress.id,
          userId: progress.userId,
          currentLevel: level,
          weakAreas: progress.weakAreas,
          streakDays: progress.streakDays,
          totalSpeakingMinutes: progress.totalSpeakingMinutes,
          lastPracticeAt: progress.lastPracticeAt,
          completedExercises: progress.completedExercises,
        ),
      );
    } catch (_) {
      // Progress row is optional for level sync.
    }
  }
}
