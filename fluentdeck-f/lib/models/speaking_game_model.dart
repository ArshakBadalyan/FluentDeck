import 'speaking_session_context.dart';

class SpeakingGameModel {
  final int id;
  final String title;
  final String slug;
  final String description;
  final String systemPrompt;
  final String openingMessage;
  final String iconKey;
  final bool isPremiumLocked;

  const SpeakingGameModel({
    required this.id,
    required this.title,
    required this.slug,
    this.description = '',
    required this.systemPrompt,
    this.openingMessage = '',
    this.iconKey = '',
    this.isPremiumLocked = false,
  });

  String get referenceKey => 'game_$slug';

  bool get isFeatured => slug == 'heroes-and-horrors';

  String get descriptionPreview {
    final text = description.trim();
    if (text.length <= 80) return text;
    return '${text.substring(0, 77)}…';
  }

  factory SpeakingGameModel.fromJson(Map<String, dynamic> json) {
    final attrs = json['attributes'] as Map<String, dynamic>? ?? json;
    return SpeakingGameModel(
      id: json['id'] as int? ?? 0,
      title: attrs['title'] as String? ?? '',
      slug: attrs['slug'] as String? ?? '',
      description: attrs['description'] as String? ?? '',
      systemPrompt: attrs['systemPrompt'] as String? ?? '',
      openingMessage: attrs['openingMessage'] as String? ?? '',
      iconKey: attrs['iconKey'] as String? ?? '',
      isPremiumLocked:
          json['isPremiumLocked'] == true || attrs['isPremiumLocked'] == true,
    );
  }

  SpeakingSessionContext toSessionContext() {
    return SpeakingSessionContext(
      mode: SpeakingMode.game,
      title: title,
      referenceKey: referenceKey,
      gameRules: systemPrompt,
      systemPrompt: systemPrompt,
      openingMessage: openingMessage,
    );
  }
}
