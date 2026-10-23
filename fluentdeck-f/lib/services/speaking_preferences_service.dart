import 'package:flutter/foundation.dart';

import '../models/speaking_preferences.dart';
import 'api_service.dart';
import 'auth_service.dart';
import '../utils/api_exception.dart';

/// Notifies listeners whenever the cached preferences change, so screens
/// showing the same value (e.g. the Daily goal slider in Profile → Settings
/// and the draggable gauge on Activity → Speaking) stay in sync live instead
/// of only agreeing after a manual reload.
class SpeakingPreferencesService extends ChangeNotifier {
  SpeakingPreferencesService._();
  static final SpeakingPreferencesService instance = SpeakingPreferencesService._();

  SpeakingPreferences _cached = const SpeakingPreferences();

  SpeakingPreferences get current => _cached;

  Future<SpeakingPreferences> load({bool forceRefresh = false}) async {
    if (!forceRefresh && _cached != const SpeakingPreferences()) {
      return _cached;
    }

    try {
      final data = await ApiService.get('users/me/speaking-preferences');
      if (data is Map && data['error'] == null) {
        _cached = SpeakingPreferences.fromUser(Map<String, dynamic>.from(data));
        notifyListeners();
        return _cached;
      }
    } catch (_) {}

    final res = await AuthService.getUser();
    if (res['status'] == 'success' && res['user'] is Map) {
      _cached = SpeakingPreferences.fromUser(
        Map<String, dynamic>.from(res['user'] as Map),
      );
      notifyListeners();
    }
    return _cached;
  }

  Future<({bool ok, String? errorMessage})> saveWithDetails(
    SpeakingPreferences preferences,
  ) async {
    final payload = preferences.toUpdatePayload();
    AuthService.invalidateUserCache();
    // ApiService throws on 4xx/5xx and network errors; callers expect a
    // result (they revert their UI on !ok), so report failures that way.
    final dynamic data;
    try {
      data = await ApiService.put('users/me/speaking-preferences', payload);
    } on ApiException catch (e) {
      return (ok: false, errorMessage: e.message);
    } catch (_) {
      return (ok: false, errorMessage: 'Could not save. Check your connection.');
    }

    if (data is Map && data['error'] == null) {
      _cached = preferences.copyWith(
        translationLanguage:
            preferences.translationLanguage == 'none'
                ? 'none'
                : preferences.translationLanguage,
      );
      notifyListeners();
      return (ok: true, errorMessage: null);
    }

    final message = _extractErrorMessage(data) ?? 'Unexpected response';
    return (ok: false, errorMessage: message);
  }

  String? _extractErrorMessage(dynamic data) {
    if (data is! Map) return 'Unexpected response';
    final error = data['error'];
    if (error is Map) {
      return error['message']?.toString();
    }
    return null;
  }

  Future<bool> save(SpeakingPreferences preferences) async {
    final result = await saveWithDetails(preferences);
    return result.ok;
  }

  /// Updates the cached value and notifies listeners without a network
  /// call — used for optimistic, instant UI sync (e.g. while dragging a
  /// slider or gauge) ahead of the debounced [saveWithDetails] call.
  void updateLocal(SpeakingPreferences preferences) {
    _cached = preferences;
    notifyListeners();
  }

  void applyFromUser(Map<String, dynamic>? user) {
    _cached = SpeakingPreferences.fromUser(user);
    notifyListeners();
  }
}

extension SpeakingPreferencesCopy on SpeakingPreferences {
  SpeakingPreferences copyWith({
    String? practiceLanguage,
    bool? syncLearningLanguage,
    String? responseLanguage,
    String? translationLanguage,
    bool? showTranslations,
    bool? autoPlayVoice,
    bool? autoConversation,
    bool? soundOn,
    bool? typeMessagesEnabled,
    bool? autoStartRecording,
    int? autoStartRecordingDelaySeconds,
    bool? autoSaveCorrections,
    bool? dailyReminderEnabled,
    String? dailyReminderTime,
    int? correctSentenceGoal,
    int? correctSentencesToday,
    String? englishLevel,
    String? tutorVoice,
  }) {
    return SpeakingPreferences(
      practiceLanguage: practiceLanguage ?? this.practiceLanguage,
      syncLearningLanguage: syncLearningLanguage ?? this.syncLearningLanguage,
      responseLanguage: responseLanguage ?? this.responseLanguage,
      translationLanguage: translationLanguage ?? this.translationLanguage,
      showTranslations: showTranslations ?? this.showTranslations,
      autoPlayVoice: autoPlayVoice ?? this.autoPlayVoice,
      autoConversation: autoConversation ?? this.autoConversation,
      soundOn: soundOn ?? this.soundOn,
      typeMessagesEnabled: typeMessagesEnabled ?? this.typeMessagesEnabled,
      autoStartRecording: autoStartRecording ?? this.autoStartRecording,
      autoStartRecordingDelaySeconds:
          autoStartRecordingDelaySeconds ?? this.autoStartRecordingDelaySeconds,
      autoSaveCorrections: autoSaveCorrections ?? this.autoSaveCorrections,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      dailyReminderTime: dailyReminderTime ?? this.dailyReminderTime,
      correctSentenceGoal: correctSentenceGoal ?? this.correctSentenceGoal,
      correctSentencesToday: correctSentencesToday ?? this.correctSentencesToday,
      englishLevel: englishLevel ?? this.englishLevel,
      tutorVoice: tutorVoice ?? this.tutorVoice,
    );
  }
}
