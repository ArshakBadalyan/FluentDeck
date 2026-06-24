class ConversationPromptModel {
  final int id;
  final String title;
  final String scenario;
  final String difficultyLevel;
  final String category;
  final String userRole;
  final String tutorRole;
  final String iconKey;
  final List<String> suggestedVocabulary;
  final bool isLocal;

  const ConversationPromptModel({
    required this.id,
    required this.title,
    required this.scenario,
    required this.difficultyLevel,
    this.category = 'daily_life',
    this.userRole = '',
    this.tutorRole = '',
    this.iconKey = '',
    this.suggestedVocabulary = const [],
    this.isLocal = false,
  });

  String get referenceKey =>
      isLocal ? 'roleplay_local_$id' : 'roleplay_$id';

  String get displayTitle => title.isNotEmpty ? title : scenario;

  String get rolesSubtitle {
    final user = userRole.trim();
    final tutor = tutorRole.trim();
    if (user.isEmpty && tutor.isEmpty) return scenario;
    if (user.isNotEmpty && tutor.isNotEmpty) {
      return 'You: $user · Partner: $tutor';
    }
    return user.isNotEmpty ? 'You: $user' : 'Partner: $tutor';
  }

  factory ConversationPromptModel.fromJson(Map<String, dynamic> json) {
    final attrs = json['attributes'] as Map<String, dynamic>? ?? json;
    final vocab = attrs['suggestedVocabulary'];
    final scenario = attrs['scenario'] as String? ?? '';
    return ConversationPromptModel(
      id: json['id'] as int? ?? 0,
      title: attrs['title'] as String? ?? scenario,
      scenario: scenario,
      difficultyLevel: attrs['difficultyLevel'] as String? ?? 'B1',
      category: attrs['category'] as String? ?? 'daily_life',
      userRole: attrs['userRole'] as String? ?? '',
      tutorRole: attrs['tutorRole'] as String? ?? '',
      iconKey: attrs['iconKey'] as String? ?? '',
      suggestedVocabulary:
          vocab is List ? vocab.map((e) => e.toString()).toList() : const [],
    );
  }

  Map<String, dynamic> toLocalJson() {
    return {
      'id': id,
      'title': title,
      'scenario': scenario,
      'difficultyLevel': difficultyLevel,
      'category': category,
      'userRole': userRole,
      'tutorRole': tutorRole,
      'iconKey': iconKey,
      'suggestedVocabulary': suggestedVocabulary,
    };
  }

  factory ConversationPromptModel.fromLocalJson(Map<String, dynamic> json) {
    final vocab = json['suggestedVocabulary'];
    return ConversationPromptModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      scenario: json['scenario'] as String? ?? '',
      difficultyLevel: json['difficultyLevel'] as String? ?? 'B1',
      category: json['category'] as String? ?? 'custom',
      userRole: json['userRole'] as String? ?? '',
      tutorRole: json['tutorRole'] as String? ?? '',
      iconKey: json['iconKey'] as String? ?? 'theater_comedy',
      suggestedVocabulary:
          vocab is List ? vocab.map((e) => e.toString()).toList() : const [],
      isLocal: true,
    );
  }
}
