class VocabularyExampleModel {
  final String text;
  final String? audioUrl;

  const VocabularyExampleModel({
    required this.text,
    this.audioUrl,
  });

  factory VocabularyExampleModel.fromJson(dynamic json) {
    if (json is String) {
      return VocabularyExampleModel(text: json);
    }
    if (json is Map) {
      return VocabularyExampleModel(
        text: json['text'] as String? ?? json['sentence'] as String? ?? '',
        audioUrl: json['audioUrl'] as String? ?? json['audio_url'] as String?,
      );
    }
    return const VocabularyExampleModel(text: '');
  }
}

class VocabularyEntryModel {
  final int id;
  final String word;
  final String lemma;
  final String entryType;
  final String partOfSpeech;
  final String? definition;
  final String? exampleSentence;
  final List<VocabularyExampleModel> examples;
  final String ipa;
  final String audioUrl;
  final String? cefrLevel;
  final String topic;
  final int frequencyRank;
  final String frequencyBucket;
  final String? sensePriority;
  final String source;
  final String externalId;
  final bool isSaved;
  final bool previewLimited;

  const VocabularyEntryModel({
    required this.id,
    required this.word,
    this.lemma = '',
    this.entryType = 'word',
    this.partOfSpeech = '',
    this.definition,
    this.exampleSentence,
    this.examples = const [],
    this.ipa = '',
    this.audioUrl = '',
    this.cefrLevel,
    this.topic = '',
    this.frequencyRank = 0,
    this.frequencyBucket = '',
    this.sensePriority,
    this.source = '',
    this.externalId = '',
    this.isSaved = false,
    this.previewLimited = false,
  });

  factory VocabularyEntryModel.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('attributes')) {
      final attrs = Map<String, dynamic>.from(json['attributes'] as Map);
      return VocabularyEntryModel(
        id: json['id'] as int? ?? 0,
        word: attrs['word'] as String? ?? '',
        lemma: attrs['lemma'] as String? ?? attrs['word'] as String? ?? '',
        entryType: attrs['entryType'] as String? ?? 'word',
        partOfSpeech: attrs['partOfSpeech'] as String? ?? '',
        definition: attrs['definition'] as String?,
        exampleSentence: attrs['exampleSentence'] as String?,
        examples: _parseExamples(attrs['examples']),
        ipa: attrs['ipa'] as String? ?? '',
        audioUrl: attrs['audioUrl'] as String? ?? '',
        cefrLevel: attrs['cefrLevel'] as String?,
        topic: attrs['topic'] as String? ?? '',
        frequencyRank: attrs['frequencyRank'] as int? ?? 0,
        frequencyBucket: attrs['frequencyBucket'] as String? ?? '',
        sensePriority: attrs['sensePriority'] as String?,
        source: attrs['source'] as String? ?? '',
        externalId: attrs['externalId'] as String? ?? '',
      );
    }

    return VocabularyEntryModel(
      id: json['id'] as int? ?? 0,
      word: json['word'] as String? ?? '',
      lemma: json['lemma'] as String? ?? json['word'] as String? ?? '',
      entryType: json['entryType'] as String? ?? 'word',
      partOfSpeech: json['partOfSpeech'] as String? ?? '',
      definition: json['definition'] as String?,
      exampleSentence: json['exampleSentence'] as String?,
      examples: _parseExamples(json['examples']),
      ipa: json['ipa'] as String? ?? '',
      audioUrl: json['audioUrl'] as String? ?? '',
      cefrLevel: json['cefrLevel'] as String?,
      topic: json['topic'] as String? ?? '',
      frequencyRank: json['frequencyRank'] as int? ?? 0,
      frequencyBucket: json['frequencyBucket'] as String? ?? '',
      sensePriority: json['sensePriority'] as String?,
      source: json['source'] as String? ?? '',
      externalId: json['externalId'] as String? ?? '',
      isSaved: json['isSaved'] == true,
      previewLimited: json['previewLimited'] == true,
    );
  }

  static List<VocabularyExampleModel> _parseExamples(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map(VocabularyExampleModel.fromJson)
        .where((example) => example.text.isNotEmpty)
        .toList();
  }

  VocabularyEntryModel copyWith({
    bool? isSaved,
    bool? previewLimited,
  }) {
    return VocabularyEntryModel(
      id: id,
      word: word,
      lemma: lemma,
      entryType: entryType,
      partOfSpeech: partOfSpeech,
      definition: definition,
      exampleSentence: exampleSentence,
      examples: examples,
      ipa: ipa,
      audioUrl: audioUrl,
      cefrLevel: cefrLevel,
      topic: topic,
      frequencyRank: frequencyRank,
      frequencyBucket: frequencyBucket,
      sensePriority: sensePriority,
      source: source,
      externalId: externalId,
      isSaved: isSaved ?? this.isSaved,
      previewLimited: previewLimited ?? this.previewLimited,
    );
  }
}

class VocabularyCatalogStats {
  final Map<String, int> levelCounts;
  final Map<String, int> bucketCounts;
  final int savedCount;
  final int? saveLimit;
  final bool isPremium;

  const VocabularyCatalogStats({
    required this.levelCounts,
    this.bucketCounts = const {},
    this.savedCount = 0,
    this.saveLimit,
    this.isPremium = false,
  });

  factory VocabularyCatalogStats.fromJson(Map<String, dynamic> json) {
    final rawCounts = json['levelCounts'];
    final counts = <String, int>{};
    if (rawCounts is Map) {
      rawCounts.forEach((key, value) {
        counts[key.toString()] = value is int ? value : int.tryParse('$value') ?? 0;
      });
    }

    final rawBuckets = json['bucketCounts'];
    final buckets = <String, int>{};
    if (rawBuckets is Map) {
      rawBuckets.forEach((key, value) {
        buckets[key.toString()] = value is int ? value : int.tryParse('$value') ?? 0;
      });
    }

    final limit = json['saveLimit'];
    return VocabularyCatalogStats(
      levelCounts: counts,
      bucketCounts: buckets,
      savedCount: json['savedCount'] as int? ?? 0,
      saveLimit: limit == null ? null : (limit as num).toInt(),
      isPremium: json['isPremium'] == true,
    );
  }
}

class SavedWordModel {
  final int progressId;
  final String status;
  final DateTime? savedAt;
  final VocabularyEntryModel entry;

  const SavedWordModel({
    required this.progressId,
    required this.status,
    this.savedAt,
    required this.entry,
  });

  factory SavedWordModel.fromJson(Map<String, dynamic> json) {
    final entryJson = json['entry'];
    return SavedWordModel(
      progressId: json['progressId'] as int? ?? 0,
      status: json['status'] as String? ?? 'new',
      savedAt:
          json['savedAt'] != null
              ? DateTime.tryParse(json['savedAt'].toString())
              : null,
      entry: VocabularyEntryModel.fromJson(
        Map<String, dynamic>.from(entryJson as Map),
      ),
    );
  }
}
