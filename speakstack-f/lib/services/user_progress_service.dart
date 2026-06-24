import '../models/grammar_correction.dart';
import '../models/user_progress_model.dart';
import 'api_service.dart';
import 'token_storage.dart';

class UserProgressService {
  UserProgressService._();
  static final UserProgressService instance = UserProgressService._();

  Future<UserProgressModel?> fetchForCurrentUser() async {
    final userId = await TokenStorage.getUserId();
    if (userId == null) return null;

    final data = await ApiService.get(
      'user-progresses?filters[user][id][\$eq]=$userId',
    );
    final rows = data is Map ? data['data'] as List? : null;
    if (rows == null || rows.isEmpty) return null;
    return UserProgressModel.fromJson(Map<String, dynamic>.from(rows.first as Map));
  }

  Future<UserProgressModel> createIfMissing() async {
    final existing = await fetchForCurrentUser();
    if (existing != null) return existing;

    final userId = await TokenStorage.getUserId();
    if (userId == null) {
      throw StateError('User not logged in');
    }

    final data = await ApiService.post('user-progresses', {
      'data': {
        'currentLevel': 'B1',
        'weakAreas': <Map<String, dynamic>>[],
        'streakDays': 0,
        'totalSpeakingMinutes': 0,
        'perfectSentencesCount': 0,
        'uniqueWordsUsed': 0,
        'completedExercises': <Map<String, dynamic>>[],
        'user': userId,
      },
    });

    final row = data is Map ? data['data'] : null;
    if (row is Map) {
      return UserProgressModel.fromJson(Map<String, dynamic>.from(row));
    }
    return const UserProgressModel(userId: 0);
  }

  Future<void> updateProgress(UserProgressModel progress) async {
    if (progress.id == null) return;
    await ApiService.put('user-progresses/${progress.id}', {
      'data': progress.toJson(),
    });
  }

  Future<void> recordConversationTurn({
    required List<GrammarCorrection> corrections,
    required DateTime startedAt,
  }) async {
    final progress = await createIfMissing();
    final weakAreas = _mergeCorrections(progress.weakAreas, corrections);

    await updateProgress(
      UserProgressModel(
        id: progress.id,
        userId: progress.userId,
        currentLevel: progress.currentLevel,
        weakAreas: weakAreas,
        streakDays: progress.streakDays,
        totalSpeakingMinutes: progress.totalSpeakingMinutes,
        perfectSentencesCount: progress.perfectSentencesCount,
        uniqueWordsUsed: progress.uniqueWordsUsed,
        lastPracticeAt: progress.lastPracticeAt,
        completedExercises: progress.completedExercises,
      ),
    );
  }

  Future<void> recordExerciseCompletion({
    required int exerciseId,
    required int lessonId,
    required bool correct,
    required String exerciseLabel,
  }) async {
    if (exerciseId <= 0) return;

    final progress = await createIfMissing();
    final completed = List<CompletedExercise>.from(progress.completedExercises);
    completed.removeWhere((item) => item.exerciseId == exerciseId);
    completed.add(
      CompletedExercise(
        exerciseId: exerciseId,
        lessonId: lessonId,
        correct: correct,
        completedAt: DateTime.now(),
      ),
    );

    var weakAreas = progress.weakAreas;
    if (!correct) {
      final label = _truncateLabel(exerciseLabel);
      weakAreas = _mergeCorrections(
        weakAreas,
        [
          GrammarCorrection(
            errorType: 'exercise',
            originalText: label,
            correctedText: label,
            explanation: 'Review this exercise topic',
          ),
        ],
      );
    }

    await updateProgress(
      UserProgressModel(
        id: progress.id,
        userId: progress.userId,
        currentLevel: progress.currentLevel,
        weakAreas: weakAreas,
        streakDays: progress.streakDays,
        totalSpeakingMinutes: progress.totalSpeakingMinutes,
        perfectSentencesCount: progress.perfectSentencesCount,
        uniqueWordsUsed: progress.uniqueWordsUsed,
        lastPracticeAt: progress.lastPracticeAt,
        completedExercises: completed,
      ),
    );
  }

  List<WeakArea> _mergeCorrections(
    List<WeakArea> existing,
    List<GrammarCorrection> corrections,
  ) {
    if (corrections.isEmpty) return existing;

    final counts = <String, WeakArea>{};
    for (final area in existing) {
      counts['${area.errorType}::${area.label}'] = area;
    }

    for (final correction in corrections) {
      final label = _weakAreaLabel(correction);
      final key = '${correction.errorType}::$label';
      final prior = counts[key];
      counts[key] = WeakArea(
        errorType: correction.errorType,
        label: label,
        count: (prior?.count ?? 0) + 1,
      );
    }

    return counts.values.toList()..sort((a, b) => b.count.compareTo(a.count));
  }

  String _weakAreaLabel(GrammarCorrection correction) {
    final explanation = correction.explanation.trim();
    if (explanation.isNotEmpty) {
      return _truncateLabel(explanation);
    }
    return correction.errorType;
  }

  String _truncateLabel(String value) {
    final trimmed = value.trim();
    if (trimmed.length <= 40) return trimmed;
    return '${trimmed.substring(0, 40)}…';
  }
}
