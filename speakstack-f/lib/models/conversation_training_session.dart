class ConversationTrainingSession {
  const ConversationTrainingSession({
    required this.sourceKey,
    required this.sourceLabel,
    required this.words,
    this.deckId,
  });

  final String sourceKey;
  final String sourceLabel;
  final List<ConversationTrainingWord> words;
  final int? deckId;

  bool get isActive => words.isNotEmpty;

  factory ConversationTrainingSession.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ConversationTrainingSession(
        sourceKey: '',
        sourceLabel: '',
        words: [],
      );
    }

    final rawWords = json['words'];
    final words =
        rawWords is List
            ? rawWords
                .whereType<Map>()
                .map(
                  (w) => ConversationTrainingWord.fromJson(
                    Map<String, dynamic>.from(w),
                  ),
                )
                .where((w) => w.word.isNotEmpty)
                .toList()
            : <ConversationTrainingWord>[];

    if (words.isEmpty && json['active'] != true) {
      return const ConversationTrainingSession(
        sourceKey: '',
        sourceLabel: '',
        words: [],
      );
    }

    return ConversationTrainingSession(
      sourceKey: json['sourceKey']?.toString() ?? '',
      sourceLabel: json['sourceLabel']?.toString() ?? 'Vocabulary',
      words: words,
      deckId: json['deckId'] is num ? (json['deckId'] as num).round() : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'active': isActive,
    'sourceKey': sourceKey,
    'sourceLabel': sourceLabel,
    if (deckId != null) 'deckId': deckId,
    'words': words.map((w) => w.toJson()).toList(),
  };
}

class ConversationTrainingWord {
  const ConversationTrainingWord({
    required this.word,
    this.hint = '',
  });

  final String word;
  final String hint;

  factory ConversationTrainingWord.fromJson(Map<String, dynamic> json) {
    return ConversationTrainingWord(
      word: json['word']?.toString() ?? '',
      hint: json['hint']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'word': word,
    if (hint.isNotEmpty) 'hint': hint,
  };
}
