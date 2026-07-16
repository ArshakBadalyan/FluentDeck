class UserNoteModel {
  final int id;
  final String word;
  final String definition;
  final String exampleSentence;
  final List<String> tags;
  final String source;
  final String languageCode;
  final DateTime? createdAt;
  final int? vocabularyEntryId;
  final String? cefrLevel;
  final String? topic;
  final String? partOfSpeech;
  final String? entryType;

  const UserNoteModel({
    required this.id,
    required this.word,
    this.definition = '',
    this.exampleSentence = '',
    this.tags = const [],
    this.source = 'manual',
    this.languageCode = 'en',
    this.createdAt,
    this.vocabularyEntryId,
    this.cefrLevel,
    this.topic,
    this.partOfSpeech,
    this.entryType,
  });

  String get sourceLabel {
    switch (source) {
      case 'catalog':
        return 'Word list';
      case 'speaking':
        return 'From speaking';
      case 'deck':
        return topic?.trim().isNotEmpty == true ? topic!.trim() : 'From deck';
      default:
        return 'Manual';
    }
  }

  factory UserNoteModel.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];
    return UserNoteModel(
      id: json['id'] as int? ?? 0,
      word: json['word'] as String? ?? '',
      definition: json['definition'] as String? ?? '',
      exampleSentence: json['exampleSentence'] as String? ?? '',
      tags:
          rawTags is List
              ? rawTags.map((e) => e.toString()).toList()
              : const [],
      source: json['source'] as String? ?? 'manual',
      languageCode: json['languageCode'] as String? ?? 'en',
      createdAt:
          json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString())
              : null,
      vocabularyEntryId: json['vocabularyEntryId'] as int?,
      cefrLevel: json['cefrLevel'] as String?,
      topic: json['topic'] as String?,
      partOfSpeech: json['partOfSpeech'] as String?,
      entryType: json['entryType'] as String?,
    );
  }
}

class StudySettingsModel {
  final bool autoCreateFlashcards;
  final int noteCount;
  final int? noteLimit;
  final bool isPremium;

  const StudySettingsModel({
    this.autoCreateFlashcards = true,
    this.noteCount = 0,
    this.noteLimit,
    this.isPremium = false,
  });

  factory StudySettingsModel.fromJson(Map<String, dynamic> json) {
    final limit = json['noteLimit'];
    return StudySettingsModel(
      autoCreateFlashcards: json['autoCreateFlashcards'] != false,
      noteCount: json['noteCount'] as int? ?? 0,
      noteLimit: limit == null ? null : (limit as num).toInt(),
      isPremium: json['isPremium'] == true,
    );
  }
}

class SaveNoteResult {
  final bool ok;
  final UserNoteModel? note;
  final bool flashcardCreated;
  final bool autoCreateEnabled;
  final String? message;

  const SaveNoteResult({
    required this.ok,
    this.note,
    this.flashcardCreated = false,
    this.autoCreateEnabled = true,
    this.message,
  });
}

class WordMeaningResult {
  final bool ok;
  final String definition;
  final String example;
  final bool premiumRequired;
  final String? message;

  const WordMeaningResult({
    required this.ok,
    this.definition = '',
    this.example = '',
    this.premiumRequired = false,
    this.message,
  });
}

class CefrLevelResult {
  final bool ok;
  final String? cefrLevel;
  final bool premiumRequired;
  final String? message;

  const CefrLevelResult({
    required this.ok,
    this.cefrLevel,
    this.premiumRequired = false,
    this.message,
  });
}

class LinkedMyNotesDeck {
  const LinkedMyNotesDeck({
    required this.id,
    required this.name,
    this.deckSlug = '',
  });

  final int id;
  final String name;
  final String deckSlug;

  /// The built-in speaking source chip already covers this deck — hide duplicate chip.
  bool get duplicatesSpeakingSource {
    if (deckSlug == 'from_speaking') return true;
    return name.trim().toLowerCase() == 'from speaking';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (deckSlug.isNotEmpty) 'deckSlug': deckSlug,
  };

  factory LinkedMyNotesDeck.fromJson(Map<String, dynamic> json) {
    return LinkedMyNotesDeck(
      id: (json['id'] as num?)?.round() ?? 0,
      name: json['name']?.toString() ?? '',
      deckSlug: json['deckSlug']?.toString() ?? '',
    );
  }
}

class ImportDecksResult {
  final bool ok;
  final int created;
  final int skipped;
  final List<String> deckNames;
  final List<LinkedMyNotesDeck> linkedDecks;
  final bool limitReached;
  final String? message;

  const ImportDecksResult({
    required this.ok,
    this.created = 0,
    this.skipped = 0,
    this.deckNames = const [],
    this.linkedDecks = const [],
    this.limitReached = false,
    this.message,
  });
}
