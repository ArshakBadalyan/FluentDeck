import 'package:flutter/foundation.dart';

import 'speaking_preferences_service.dart';

/// Watches today's correct-sentence count (sent as `speakingStats` with each
/// tutor reply) against the user's daily goal.
class DailyGoalTracker {
  DailyGoalTracker._();
  static final DailyGoalTracker instance = DailyGoalTracker._();

  /// Bumps when the goal is crossed; the conversation screen celebrates
  /// (at most once per day).
  final ValueNotifier<int> dailyGoalReached = ValueNotifier(0);
  String? _celebratedDay;

  /// Keeps the cached daily count in sync (Activity's goal gauge updates live)
  /// and fires [dailyGoalReached] when the goal is crossed.
  void applySpeakingStats(Object? raw) {
    if (raw is! Map) return;
    final today = (raw['correctSentencesToday'] as num?)?.round();
    if (today == null) return;
    final prefsService = SpeakingPreferencesService.instance;
    final prefs = prefsService.current;
    final before = prefs.correctSentencesToday;
    if (today != before) {
      prefsService.updateLocal(prefs.copyWith(correctSentencesToday: today));
    }
    final goal = prefs.correctSentenceGoal;
    final day = DateTime.now().toIso8601String().substring(0, 10);
    if (goal > 0 && before < goal && today >= goal && _celebratedDay != day) {
      _celebratedDay = day;
      dailyGoalReached.value++;
    }
  }
}
