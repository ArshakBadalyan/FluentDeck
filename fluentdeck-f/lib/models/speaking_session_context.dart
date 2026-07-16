enum SpeakingMode { chat, rolePlay, topic, game, lesson }

class SpeakingSessionContext {
  final SpeakingMode mode;
  final String title;
  final String? referenceKey;
  final String? userRole;
  final String? tutorRole;
  final String? situation;
  final String? scenario;
  final String? starterPrompt;
  final List<String> suggestedVocabulary;
  final String? gameRules;
  final String? systemPrompt;
  final String? openingMessage;
  final int? lessonId;
  final String? lessonDescription;
  final String? lessonObjectives;
  final String? exercisePrompt;

  const SpeakingSessionContext({
    required this.mode,
    required this.title,
    this.referenceKey,
    this.userRole,
    this.tutorRole,
    this.situation,
    this.scenario,
    this.starterPrompt,
    this.suggestedVocabulary = const [],
    this.gameRules,
    this.systemPrompt,
    this.openingMessage,
    this.lessonId,
    this.lessonDescription,
    this.lessonObjectives,
    this.exercisePrompt,
  });

  bool get isFreeChat => mode == SpeakingMode.chat;

  static const defaultChatGreeting =
      "Hi! I'm your AI tutor. How can I help you today?";

  factory SpeakingSessionContext.freeChat() {
    return const SpeakingSessionContext(
      mode: SpeakingMode.chat,
      title: 'Free conversation',
      referenceKey: 'chat_free',
    );
  }

  Map<String, dynamic> toJson() {
    final modeKey = switch (mode) {
      SpeakingMode.chat => 'chat',
      SpeakingMode.rolePlay => 'role_play',
      SpeakingMode.topic => 'topic',
      SpeakingMode.game => 'game',
      SpeakingMode.lesson => 'lesson',
    };
    return {
      'mode': modeKey,
      'title': title,
      if (referenceKey != null) 'referenceKey': referenceKey,
      if (userRole != null && userRole!.isNotEmpty) 'userRole': userRole,
      if (tutorRole != null && tutorRole!.isNotEmpty) 'tutorRole': tutorRole,
      if (situation != null && situation!.isNotEmpty) 'situation': situation,
      if (scenario != null && scenario!.isNotEmpty) 'scenario': scenario,
      if (starterPrompt != null && starterPrompt!.isNotEmpty)
        'starterPrompt': starterPrompt,
      if (suggestedVocabulary.isNotEmpty)
        'suggestedVocabulary': suggestedVocabulary,
      if (gameRules != null && gameRules!.isNotEmpty) 'gameRules': gameRules,
      if (systemPrompt != null && systemPrompt!.isNotEmpty)
        'systemPrompt': systemPrompt,
      if (openingMessage != null && openingMessage!.isNotEmpty)
        'openingMessage': openingMessage,
      if (lessonId != null) 'lessonId': lessonId,
      if (lessonDescription != null && lessonDescription!.isNotEmpty)
        'lessonDescription': lessonDescription,
      if (lessonObjectives != null && lessonObjectives!.isNotEmpty)
        'lessonObjectives': lessonObjectives,
      if (exercisePrompt != null && exercisePrompt!.isNotEmpty)
        'exercisePrompt': exercisePrompt,
    };
  }
}

class SessionEvaluationResult {
  final int score;
  final String feedback;
  final String summary;

  const SessionEvaluationResult({
    required this.score,
    required this.feedback,
    required this.summary,
  });

  factory SessionEvaluationResult.fromJson(Map<String, dynamic> json) {
    return SessionEvaluationResult(
      score: (json['score'] as num?)?.round() ?? 0,
      feedback: json['feedback']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
    );
  }
}
