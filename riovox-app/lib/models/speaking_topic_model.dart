import 'speaking_session_context.dart';

class SpeakingTopicModel {
  final int id;
  final String title;
  final String levelGroup;
  final String starterPrompt;
  final String iconKey;
  final List<String> suggestedVocabulary;
  final bool isPremiumLocked;

  const SpeakingTopicModel({
    required this.id,
    required this.title,
    required this.levelGroup,
    required this.starterPrompt,
    this.iconKey = '',
    this.suggestedVocabulary = const [],
    this.isPremiumLocked = false,
  });

  String get referenceKey => 'topic_$id';

  String get promptPreview {
    final text = starterPrompt.trim();
    if (text.length <= 72) return text;
    return '${text.substring(0, 69)}…';
  }

  String get vocabPreview {
    if (suggestedVocabulary.isEmpty) return '';
    final shown = suggestedVocabulary.take(4).join(', ');
    if (suggestedVocabulary.length <= 4) return shown;
    return '$shown…';
  }

  factory SpeakingTopicModel.fromJson(Map<String, dynamic> json) {
    final attrs = json['attributes'] as Map<String, dynamic>? ?? json;
    final vocab = attrs['suggestedVocabulary'];
    return SpeakingTopicModel(
      id: json['id'] as int? ?? 0,
      title: attrs['title'] as String? ?? '',
      levelGroup: attrs['levelGroup'] as String? ?? 'intermediate',
      starterPrompt: attrs['starterPrompt'] as String? ?? '',
      iconKey: attrs['iconKey'] as String? ?? '',
      suggestedVocabulary:
          vocab is List ? vocab.map((e) => e.toString()).toList() : const [],
      isPremiumLocked:
          json['isPremiumLocked'] == true || attrs['isPremiumLocked'] == true,
    );
  }

  SpeakingSessionContext toSessionContext() {
    return SpeakingSessionContext(
      mode: SpeakingMode.topic,
      title: title,
      referenceKey: referenceKey,
      starterPrompt: starterPrompt,
      situation: starterPrompt,
      suggestedVocabulary: suggestedVocabulary,
    );
  }
}
