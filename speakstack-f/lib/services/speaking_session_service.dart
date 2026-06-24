import '../models/speaking_session_context.dart';
import '../models/speaking_session_record_model.dart';
import 'api_service.dart';
import 'speaking_scores_service.dart';

class SpeakingSessionCompleteResult {
  final SpeakingSessionRecord session;
  final int streakDays;
  final int totalSpeakingMinutes;

  const SpeakingSessionCompleteResult({
    required this.session,
    required this.streakDays,
    required this.totalSpeakingMinutes,
  });
}

class SpeakingSessionService {
  SpeakingSessionService._();
  static final SpeakingSessionService instance = SpeakingSessionService._();

  String _modeKey(SpeakingMode mode) {
    switch (mode) {
      case SpeakingMode.chat:
        return 'chat';
      case SpeakingMode.rolePlay:
        return 'role_play';
      case SpeakingMode.topic:
        return 'topic';
      case SpeakingMode.game:
        return 'game';
      case SpeakingMode.lesson:
        return 'lesson';
    }
  }

  Future<SpeakingSessionCompleteResult?> completeSession({
    required SpeakingSessionContext context,
    required int score,
    required String feedback,
    required String summary,
    required int turnCount,
    required DateTime startedAt,
  }) async {
    final durationMinutes =
        ((DateTime.now().difference(startedAt).inSeconds) / 60).ceil().clamp(
          1,
          120,
        );

    final body = {
      'mode': _modeKey(context.mode),
      'referenceKey': context.referenceKey,
      'title': context.title,
      'score': score,
      'feedback': feedback,
      'summary': summary,
      'durationMinutes': durationMinutes,
      'turnCount': turnCount,
      'completedAt': DateTime.now().toUtc().toIso8601String(),
    };

    final data = await ApiService.post('speaking-sessions/complete', body);
    if (data is Map && data['error'] != null) {
      throw Exception(
        data['error']['message']?.toString() ?? 'Could not save session',
      );
    }
    if (data is! Map || data['session'] is! Map) {
      throw Exception('Unexpected session save response');
    }

    final session = SpeakingSessionRecord.fromJson(
      Map<String, dynamic>.from(data['session'] as Map),
    );

    final bestScoresRaw = data['bestScores'];
    if (bestScoresRaw is Map) {
      final merged = <String, int>{};
      bestScoresRaw.forEach((key, value) {
        if (value is num) merged[key.toString()] = value.round();
      });
      await SpeakingScoresService.instance.mergeServerScores(merged);
    }

    if (context.referenceKey != null && context.referenceKey!.isNotEmpty) {
      await SpeakingScoresService.instance.saveScore(
        referenceKey: context.referenceKey!,
        score: score,
        title: context.title,
        mode: context.mode,
      );
    }

    final progress = data['progress'];
    return SpeakingSessionCompleteResult(
      session: session,
      streakDays: (progress is Map ? progress['streakDays'] as num? : null)?.round() ?? 0,
      totalSpeakingMinutes:
          (progress is Map ? progress['totalSpeakingMinutes'] as num? : null)
              ?.round() ??
          0,
    );
  }

  Future<List<SpeakingSessionRecord>> fetchRecent({int limit = 10}) async {
    final data = await ApiService.get(
      'speaking-sessions/recent?limit=$limit',
    );
    final rows = data is Map ? data['data'] as List? : null;
    if (rows == null) return [];

    return rows
        .whereType<Map>()
        .map(
          (row) => SpeakingSessionRecord.fromJson(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList();
  }

  Future<void> refreshScoresFromServer() async {
    final data = await ApiService.get('speaking-sessions/scores');
    if (data is! Map || data['bestScores'] is! Map) return;
    final merged = <String, int>{};
    (data['bestScores'] as Map).forEach((key, value) {
      if (value is num) merged[key.toString()] = value.round();
    });
    await SpeakingScoresService.instance.mergeServerScores(merged);
  }
}
