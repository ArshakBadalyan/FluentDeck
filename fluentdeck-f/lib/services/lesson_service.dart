import '../models/conversation_prompt_model.dart';
import '../models/lesson_model.dart';
import '../utils/strapi_response.dart';
import 'api_service.dart';

class LessonService {
  LessonService._();
  static final LessonService instance = LessonService._();

  Future<List<LessonModel>> fetchLessons({
    String? level,
    String? skillType,
  }) async {
    final filters = <String>[];
    if (level != null && level.isNotEmpty) {
      filters.add('filters[level][\$eq]=$level');
    }
    if (skillType != null && skillType.isNotEmpty) {
      filters.add('filters[skillType][\$eq]=$skillType');
    }
    filters.add('sort=order:asc');
    filters.add('populate=exercises');

    final query = filters.isEmpty ? '' : '?${filters.join('&')}';
    final data = await ApiService.get('lessons$query');
    final rows = StrapiResponse.list(data);

    return rows
        .whereType<Map>()
        .map((row) => LessonModel.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<LessonModel?> fetchLessonById(int id) async {
    final data = await ApiService.get('lessons/$id?populate=exercises');
    final row = StrapiResponse.row(data);
    if (row == null) return null;
    return LessonModel.fromJson(row);
  }

  Future<List<ConversationPromptModel>> fetchConversationPrompts({
    String? difficultyLevel,
  }) async {
    final query =
        difficultyLevel != null && difficultyLevel.isNotEmpty
            ? '?filters[difficultyLevel][\$eq]=$difficultyLevel&sort=id:asc'
            : '?sort=id:asc';
    final data = await ApiService.get('speaking-role-plays$query');
    final rows = StrapiResponse.list(data);

    return rows
        .whereType<Map>()
        .map(
          (row) => ConversationPromptModel.fromJson(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList();
  }
}
