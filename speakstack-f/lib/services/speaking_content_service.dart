import '../models/conversation_prompt_model.dart';
import '../models/speaking_game_model.dart';
import '../models/speaking_session_context.dart';
import '../models/speaking_topic_model.dart';
import 'api_service.dart';
import 'custom_role_play_service.dart';

class SpeakingContentService {
  SpeakingContentService._();
  static final SpeakingContentService instance = SpeakingContentService._();

  SpeakingSessionContext rolePlaySessionFrom(ConversationPromptModel prompt) {
    return SpeakingSessionContext(
      mode: SpeakingMode.rolePlay,
      title: prompt.displayTitle,
      referenceKey: prompt.referenceKey,
      userRole: prompt.userRole.isNotEmpty ? prompt.userRole : 'Learner',
      tutorRole:
          prompt.tutorRole.isNotEmpty
              ? prompt.tutorRole
              : 'Conversation partner',
      situation: prompt.scenario,
      scenario: prompt.scenario,
      suggestedVocabulary: prompt.suggestedVocabulary,
    );
  }

  SpeakingSessionContext topicSessionFrom(SpeakingTopicModel topic) {
    return SpeakingSessionContext(
      mode: SpeakingMode.topic,
      title: topic.title,
      referenceKey: topic.referenceKey,
      starterPrompt: topic.starterPrompt,
      situation: topic.starterPrompt,
      suggestedVocabulary: topic.suggestedVocabulary,
    );
  }

  Future<List<ConversationPromptModel>> fetchRolePlayScenarios({
    String? category,
  }) async {
    final filters = <String>['sort=order:asc'];
    if (category != null && category.isNotEmpty && category != 'all') {
      filters.insert(0, 'filters[category][\$eq]=$category');
    }
    final query = '?${filters.join('&')}';
    final data = await ApiService.get('conversation-prompts$query');
    final rows = data is Map ? data['data'] as List? : null;
    final remote =
        rows == null
            ? <ConversationPromptModel>[]
            : rows
                .whereType<Map>()
                .map(
                  (row) => ConversationPromptModel.fromJson(
                    Map<String, dynamic>.from(row),
                  ),
                )
                .toList();

    final local = await CustomRolePlayService.instance.fetchAll();
    if (category == 'custom') return local;
    if (category != null && category.isNotEmpty && category != 'all') {
      return remote;
    }
    return [...local, ...remote];
  }

  Future<List<SpeakingTopicModel>> fetchTopics({String? levelGroup}) async {
    final filters = <String>['sort=order:asc'];
    if (levelGroup != null && levelGroup.isNotEmpty) {
      filters.insert(0, 'filters[levelGroup][\$eq]=$levelGroup');
    }
    final query = '?${filters.join('&')}';
    final data = await ApiService.get('speaking-topics$query');
    final rows = data is Map ? data['data'] as List? : null;
    if (rows == null) return [];

    return rows
        .whereType<Map>()
        .map(
          (row) => SpeakingTopicModel.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<List<SpeakingGameModel>> fetchGames() async {
    final data = await ApiService.get('speaking-games?sort=order:asc');
    final rows = data is Map ? data['data'] as List? : null;
    if (rows == null) return [];

    return rows
        .whereType<Map>()
        .map(
          (row) => SpeakingGameModel.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  SpeakingSessionContext gameSessionFrom(SpeakingGameModel game) {
    return SpeakingSessionContext(
      mode: SpeakingMode.game,
      title: game.title,
      referenceKey: game.referenceKey,
      gameRules: game.systemPrompt,
      systemPrompt: game.systemPrompt,
      openingMessage: game.openingMessage,
    );
  }
}
