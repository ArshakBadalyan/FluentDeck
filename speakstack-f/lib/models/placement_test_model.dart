class PlacementQuestionModel {
  final int vocabularyEntryId;
  final String word;
  final String cefrLevel;
  final String? definition;

  const PlacementQuestionModel({
    required this.vocabularyEntryId,
    required this.word,
    required this.cefrLevel,
    this.definition,
  });

  factory PlacementQuestionModel.fromJson(Map<String, dynamic> json) {
    return PlacementQuestionModel(
      vocabularyEntryId: json['vocabularyEntryId'] as int? ?? 0,
      word: json['word'] as String? ?? '',
      cefrLevel: json['cefrLevel'] as String? ?? 'B1',
      definition: json['definition'] as String?,
    );
  }
}

class PlacementTestResultModel {
  final int? id;
  final String suggestedLevel;
  final String levelBucket;
  final double score;
  final DateTime? takenAt;
  final StudySuggestions? studySuggestions;

  const PlacementTestResultModel({
    this.id,
    required this.suggestedLevel,
    required this.levelBucket,
    required this.score,
    this.takenAt,
    this.studySuggestions,
  });

  String get bucketLabel {
    switch (levelBucket) {
      case 'beginner':
        return 'Beginner';
      case 'intermediate':
        return 'Intermediate';
      case 'advanced':
        return 'Advanced';
      default:
        return levelBucket;
    }
  }

  factory PlacementTestResultModel.fromJson(Map<String, dynamic> json) {
    final suggestions = json['studySuggestions'];
    return PlacementTestResultModel(
      id: json['id'] as int?,
      suggestedLevel: json['suggestedLevel'] as String? ?? 'B1',
      levelBucket: json['levelBucket'] as String? ?? 'intermediate',
      score: (json['score'] as num?)?.toDouble() ?? 0,
      takenAt:
          json['takenAt'] != null
              ? DateTime.tryParse(json['takenAt'].toString())
              : null,
      studySuggestions:
          suggestions is Map
              ? StudySuggestions.fromJson(
                Map<String, dynamic>.from(suggestions),
              )
              : null,
    );
  }
}

class StudySuggestions {
  final int dailyNewWords;
  final int dailyReviews;
  final List<String> deckSetup;
  final int speakMinutes;
  final String message;

  const StudySuggestions({
    this.dailyNewWords = 10,
    this.dailyReviews = 15,
    this.deckSetup = const [],
    this.speakMinutes = 5,
    this.message = '',
  });

  factory StudySuggestions.fromJson(Map<String, dynamic> json) {
    final decks = json['deckSetup'];
    return StudySuggestions(
      dailyNewWords: json['dailyNewWords'] as int? ?? 10,
      dailyReviews: json['dailyReviews'] as int? ?? 15,
      deckSetup:
          decks is List ? decks.map((e) => e.toString()).toList() : const [],
      speakMinutes: json['speakMinutes'] as int? ?? 5,
      message: json['message'] as String? ?? '',
    );
  }
}
