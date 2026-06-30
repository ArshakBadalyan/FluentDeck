import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/speaking_session_context.dart';

class SpeakingScoreEntry {
  final String referenceKey;
  final String title;
  final SpeakingMode mode;
  final int score;
  final DateTime updatedAt;

  const SpeakingScoreEntry({
    required this.referenceKey,
    required this.title,
    required this.mode,
    required this.score,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'referenceKey': referenceKey,
    'title': title,
    'mode': mode.name,
    'score': score,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory SpeakingScoreEntry.fromJson(Map<String, dynamic> json) {
    return SpeakingScoreEntry(
      referenceKey: json['referenceKey'] as String? ?? '',
      title: json['title'] as String? ?? '',
      mode: SpeakingMode.values.firstWhere(
        (m) => m.name == json['mode'],
        orElse: () => SpeakingMode.chat,
      ),
      score: (json['score'] as num?)?.round() ?? 0,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class SpeakingScoresService {
  SpeakingScoresService._();
  static final SpeakingScoresService instance = SpeakingScoresService._();

  static const _prefsKey = 'speaking_scores_v1';

  Future<Map<String, SpeakingScoreEntry>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final result = <String, SpeakingScoreEntry>{};
      decoded.forEach((key, value) {
        if (value is Map) {
          result[key.toString()] = SpeakingScoreEntry.fromJson(
            Map<String, dynamic>.from(value),
          );
        }
      });
      return result;
    } catch (_) {
      return {};
    }
  }

  Future<int?> getScore(String referenceKey) async {
    if (referenceKey.isEmpty) return null;
    final all = await _loadAll();
    return all[referenceKey]?.score;
  }

  Future<Map<String, SpeakingScoreEntry>> getAllScores() => _loadAll();

  Future<void> mergeServerScores(Map<String, int> serverScores) async {
    if (serverScores.isEmpty) return;
    final all = await _loadAll();
    serverScores.forEach((key, serverScore) {
      final local = all[key];
      if (local == null || serverScore > local.score) {
        all[key] = SpeakingScoreEntry(
          referenceKey: key,
          title: local?.title ?? key,
          mode: local?.mode ?? SpeakingMode.chat,
          score: serverScore.clamp(0, 10),
          updatedAt: DateTime.now(),
        );
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(all.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }

  Future<({int total, int scoredCount, double? averageScore})> topicLevelProgress(
    List<String> referenceKeys,
  ) async {
    if (referenceKeys.isEmpty) {
      return (total: 0, scoredCount: 0, averageScore: null);
    }
    final all = await _loadAll();
    var scoredCount = 0;
    var scoreSum = 0;
    for (final key in referenceKeys) {
      final score = all[key]?.score;
      if (score != null) {
        scoredCount += 1;
        scoreSum += score;
      }
    }
    return (
      total: referenceKeys.length,
      scoredCount: scoredCount,
      averageScore: scoredCount > 0 ? scoreSum / scoredCount : null,
    );
  }

  Future<({int total, int scoredCount})> gameCatalogProgress(
    List<String> referenceKeys,
  ) async {
    final stats = await topicLevelProgress(referenceKeys);
    return (total: stats.total, scoredCount: stats.scoredCount);
  }

  Future<void> saveScore({
    required String referenceKey,
    required int score,
    required String title,
    required SpeakingMode mode,
  }) async {
    if (referenceKey.isEmpty) return;
    final all = await _loadAll();
    all[referenceKey] = SpeakingScoreEntry(
      referenceKey: referenceKey,
      title: title,
      mode: mode,
      score: score.clamp(0, 10),
      updatedAt: DateTime.now(),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(all.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }
}
