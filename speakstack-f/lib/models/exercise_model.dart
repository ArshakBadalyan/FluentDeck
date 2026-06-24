class ExerciseModel {
  final int id;
  final int lessonId;
  final String type;
  final String prompt;
  final String? correctAnswer;
  final List<String> options;
  final bool aiFeedbackEnabled;

  const ExerciseModel({
    required this.id,
    required this.lessonId,
    required this.type,
    required this.prompt,
    this.correctAnswer,
    this.options = const [],
    this.aiFeedbackEnabled = false,
  });

  factory ExerciseModel.fromJson(
    Map<String, dynamic> json, {
    int lessonId = 0,
  }) {
    final attrs = json['attributes'] as Map<String, dynamic>? ?? json;
    final rawOptions = attrs['options'];
    final lessonRelation = attrs['lesson']?['data'];
    final resolvedLessonId =
        lessonId > 0
            ? lessonId
            : (lessonRelation is Map ? lessonRelation['id'] as int? : null) ?? 0;

    return ExerciseModel(
      id: json['id'] as int? ?? 0,
      lessonId: resolvedLessonId,
      type: attrs['type'] as String? ?? 'speakingPrompt',
      prompt: attrs['prompt'] as String? ?? '',
      correctAnswer: attrs['correctAnswer'] as String?,
      options:
          rawOptions is List
              ? rawOptions.map((e) => e.toString()).toList()
              : const [],
      aiFeedbackEnabled: attrs['aiFeedbackEnabled'] as bool? ?? false,
    );
  }
}
