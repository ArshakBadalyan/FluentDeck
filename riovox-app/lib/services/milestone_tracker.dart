import 'package:shared_preferences/shared_preferences.dart';

/// Decides when a speaking streak milestone or a level-up deserves a
/// celebration. Remembers what was already celebrated on this device, so
/// each one shows once.
class MilestoneTracker {
  MilestoneTracker._();
  static final MilestoneTracker instance = MilestoneTracker._();

  static const _cefr = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
  static const streakMilestones = [3, 7, 14, 30, 60, 100, 180, 365];
  static const _streakKey = 'milestone_streak_celebrated_v1';
  static const _levelKeyPrefix = 'milestone_level_seen_v1:';

  /// The milestone [streakDays] just reached, or null. A broken streak
  /// (lower than the last celebrated one) lets the milestones count again.
  Future<int?> streakMilestone(int streakDays) async {
    final prefs = await SharedPreferences.getInstance();
    var celebrated = prefs.getInt(_streakKey) ?? 0;
    if (streakDays < celebrated) {
      celebrated = 0;
      await prefs.remove(_streakKey);
    }
    if (!streakMilestones.contains(streakDays) || streakDays <= celebrated) {
      return null;
    }
    await prefs.setInt(_streakKey, streakDays);
    return streakDays;
  }

  /// True when [level] (A1–C2) is higher than the last one seen for
  /// [language]. The first level seen is only remembered, not celebrated.
  Future<bool> isLevelUp(String language, String? level) async {
    final index = _cefr.indexOf(level ?? '');
    if (index < 0) return false;
    final prefs = await SharedPreferences.getInstance();
    final key = '$_levelKeyPrefix$language';
    final seen = _cefr.indexOf(prefs.getString(key) ?? '');
    if (index != seen) await prefs.setString(key, level!);
    return seen >= 0 && index > seen;
  }
}
