import 'exercise_model.dart';

class LessonModel {
  final int id;
  final String title;
  final String level;
  final String skillType;
  final int order;
  final int? strapiContentId;
  final String? description;
  final List<ExerciseModel> exercises;

  const LessonModel({
    required this.id,
    required this.title,
    required this.level,
    required this.skillType,
    this.order = 0,
    this.strapiContentId,
    this.description,
    this.exercises = const [],
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    final attrs = json['attributes'] as Map<String, dynamic>? ?? json;
    final lessonId = json['id'] as int? ?? 0;

    final rawExercises = attrs['exercises']?['data'] ?? attrs['exercises'];
    final exercises =
        rawExercises is List
            ? rawExercises
                .map(
                  (e) => ExerciseModel.fromJson(
                    Map<String, dynamic>.from(e as Map),
                    lessonId: lessonId,
                  ),
                )
                .toList()
            : const <ExerciseModel>[];

    return LessonModel(
      id: lessonId,
      title: attrs['title'] as String? ?? '',
      level: attrs['level'] as String? ?? 'B1',
      skillType: attrs['skillType'] as String? ?? 'speaking',
      order: attrs['order'] as int? ?? 0,
      strapiContentId: lessonId > 0 ? lessonId : null,
      description: attrs['description'] as String?,
      exercises: exercises,
    );
  }
}
