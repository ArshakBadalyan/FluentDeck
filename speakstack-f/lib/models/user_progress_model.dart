class WeakArea {
  final String errorType;
  final String label;
  final int count;

  const WeakArea({
    required this.errorType,
    required this.label,
    required this.count,
  });

  factory WeakArea.fromJson(Map<String, dynamic> json) => WeakArea(
    errorType: json['errorType'] as String? ?? 'grammar',
    label: json['label'] as String? ?? '',
    count: json['count'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'errorType': errorType,
    'label': label,
    'count': count,
  };
}

class CompletedExercise {
  final int exerciseId;
  final int lessonId;
  final bool correct;
  final DateTime? completedAt;

  const CompletedExercise({
    required this.exerciseId,
    required this.lessonId,
    required this.correct,
    this.completedAt,
  });

  factory CompletedExercise.fromJson(Map<String, dynamic> json) =>
      CompletedExercise(
        exerciseId: json['exerciseId'] as int? ?? 0,
        lessonId: json['lessonId'] as int? ?? 0,
        correct: json['correct'] as bool? ?? false,
        completedAt:
            json['completedAt'] != null
                ? DateTime.tryParse(json['completedAt'].toString())
                : null,
      );

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'lessonId': lessonId,
    'correct': correct,
    if (completedAt != null) 'completedAt': completedAt!.toUtc().toIso8601String(),
  };
}

class UserProgressModel {
  final int? id;
  final int userId;
  final String currentLevel;
  final List<WeakArea> weakAreas;
  final int streakDays;
  final int totalSpeakingMinutes;
  final int perfectSentencesCount;
  final int uniqueWordsUsed;
  final DateTime? lastPracticeAt;
  final List<CompletedExercise> completedExercises;

  const UserProgressModel({
    this.id,
    required this.userId,
    this.currentLevel = 'B1',
    this.weakAreas = const [],
    this.streakDays = 0,
    this.totalSpeakingMinutes = 0,
    this.perfectSentencesCount = 0,
    this.uniqueWordsUsed = 0,
    this.lastPracticeAt,
    this.completedExercises = const [],
  });

  factory UserProgressModel.fromJson(Map<String, dynamic> json) {
    final attrs = json['attributes'] as Map<String, dynamic>? ?? json;
    final rawWeakAreas = attrs['weakAreas'];
    final rawCompleted = attrs['completedExercises'];
    final userData = attrs['user']?['data'];

    return UserProgressModel(
      id: json['id'] as int?,
      userId:
          userData is Map
              ? userData['id'] as int? ?? 0
              : attrs['userId'] as int? ?? 0,
      currentLevel: attrs['currentLevel'] as String? ?? 'B1',
      weakAreas:
          rawWeakAreas is List
              ? rawWeakAreas
                  .map(
                    (e) => WeakArea.fromJson(Map<String, dynamic>.from(e as Map)),
                  )
                  .toList()
              : const [],
      streakDays: attrs['streakDays'] as int? ?? 0,
      totalSpeakingMinutes: attrs['totalSpeakingMinutes'] as int? ?? 0,
      perfectSentencesCount: attrs['perfectSentencesCount'] as int? ?? 0,
      uniqueWordsUsed: attrs['uniqueWordsUsed'] as int? ?? 0,
      lastPracticeAt:
          attrs['lastPracticeAt'] != null
              ? DateTime.tryParse(attrs['lastPracticeAt'].toString())
              : null,
      completedExercises:
          rawCompleted is List
              ? rawCompleted
                  .map(
                    (e) => CompletedExercise.fromJson(
                      Map<String, dynamic>.from(e as Map),
                    ),
                  )
                  .toList()
              : const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'currentLevel': currentLevel,
    'weakAreas': weakAreas.map((w) => w.toJson()).toList(),
    'streakDays': streakDays,
    'totalSpeakingMinutes': totalSpeakingMinutes,
    'perfectSentencesCount': perfectSentencesCount,
    'uniqueWordsUsed': uniqueWordsUsed,
    if (lastPracticeAt != null)
      'lastPracticeAt': lastPracticeAt!.toUtc().toIso8601String(),
    'completedExercises': completedExercises.map((e) => e.toJson()).toList(),
  };
}
