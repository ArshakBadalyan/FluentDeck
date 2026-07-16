import '../models/conversation_prompt_model.dart';
import '../models/speaking_game_model.dart';
import '../models/speaking_session_context.dart';
import '../models/speaking_topic_model.dart';
import 'api_service.dart';
import 'custom_role_play_service.dart';

class SpeakingCatalogResult<T> {
  final List<T> items;
  final bool isPremium;

  const SpeakingCatalogResult({
    required this.items,
    this.isPremium = false,
  });
}

class SpeakingContentService {
  SpeakingContentService._();
  static final SpeakingContentService instance = SpeakingContentService._();

  List<Map<String, dynamic>> _catalogRows(dynamic data) {
    if (data is! Map) return [];
    final rows = data['data'];
    if (rows is! List) return [];
    return rows
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  bool _catalogIsPremium(dynamic data) {
    return data is Map && data['isPremium'] == true;
  }

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
    final result = await fetchRolePlayCatalog(category: category);
    return result.items;
  }

  Future<SpeakingCatalogResult<ConversationPromptModel>> fetchRolePlayCatalog({
    String? category,
  }) async {
    final query =
        category != null && category.isNotEmpty ? '?category=$category' : '';
    final data = await ApiService.get('speaking-role-plays/catalog$query');
    final remote =
        _catalogRows(data)
            .map((row) => ConversationPromptModel.fromJson(row))
            .toList();

    final local = await CustomRolePlayService.instance.fetchAll();
    if (category == 'custom') {
      return SpeakingCatalogResult(
        items: local,
        isPremium: _catalogIsPremium(data),
      );
    }
    if (category != null && category.isNotEmpty && category != 'all') {
      return SpeakingCatalogResult(
        items: remote,
        isPremium: _catalogIsPremium(data),
      );
    }
    return SpeakingCatalogResult(
      items: [...local, ...remote],
      isPremium: _catalogIsPremium(data),
    );
  }

  Future<List<SpeakingTopicModel>> fetchTopics({String? levelGroup}) async {
    final result = await fetchTopicsCatalog(levelGroup: levelGroup);
    return result.items;
  }

  Future<SpeakingCatalogResult<SpeakingTopicModel>> fetchTopicsCatalog({
    String? levelGroup,
  }) async {
    final query =
        levelGroup != null && levelGroup.isNotEmpty
            ? '?levelGroup=$levelGroup'
            : '';
    final data = await ApiService.get('speaking-topics/catalog$query');
    final items =
        _catalogRows(data)
            .map((row) => SpeakingTopicModel.fromJson(row))
            .toList();
    return SpeakingCatalogResult(
      items: items,
      isPremium: _catalogIsPremium(data),
    );
  }

  Future<List<SpeakingGameModel>> fetchGames() async {
    final result = await fetchGamesCatalog();
    return result.items;
  }

  Future<SpeakingCatalogResult<SpeakingGameModel>> fetchGamesCatalog() async {
    final data = await ApiService.get('speaking-games/catalog');
    final items =
        _catalogRows(data)
            .map((row) => SpeakingGameModel.fromJson(row))
            .toList();
    return SpeakingCatalogResult(
      items: items,
      isPremium: _catalogIsPremium(data),
    );
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
