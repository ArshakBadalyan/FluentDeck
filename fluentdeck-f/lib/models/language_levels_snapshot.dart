class LanguageLevelHistoryEntry {
  final String estimatedLevel;
  final DateTime? recordedAt;
  final String source;

  const LanguageLevelHistoryEntry({
    required this.estimatedLevel,
    this.recordedAt,
    this.source = 'analytics',
  });

  factory LanguageLevelHistoryEntry.fromJson(Map<String, dynamic> json) {
    return LanguageLevelHistoryEntry(
      estimatedLevel: json['estimatedLevel'] as String? ?? 'A1',
      recordedAt: json['recordedAt'] != null
          ? DateTime.tryParse(json['recordedAt'].toString())
          : null,
      source: json['source'] as String? ?? 'analytics',
    );
  }
}

class LanguageLevelRecord {
  final String languageCode;
  final String tutorLevel;
  final String estimatedLevel;
  final DateTime? lastActiveAt;
  final DateTime? firstSelectedAt;
  final int speakingTurns;
  final int deckWordsReviewed;
  final List<LanguageLevelHistoryEntry> levelHistory;

  const LanguageLevelRecord({
    required this.languageCode,
    this.tutorLevel = 'A1',
    this.estimatedLevel = 'A1',
    this.lastActiveAt,
    this.firstSelectedAt,
    this.speakingTurns = 0,
    this.deckWordsReviewed = 0,
    this.levelHistory = const [],
  });

  factory LanguageLevelRecord.fromJson(Map<String, dynamic> json) {
    final rawHistory = json['levelHistory'];
    return LanguageLevelRecord(
      languageCode: json['languageCode'] as String? ?? 'en',
      tutorLevel: json['tutorLevel'] as String? ?? 'A1',
      estimatedLevel: json['estimatedLevel'] as String? ?? 'A1',
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.tryParse(json['lastActiveAt'].toString())
          : null,
      firstSelectedAt: json['firstSelectedAt'] != null
          ? DateTime.tryParse(json['firstSelectedAt'].toString())
          : null,
      speakingTurns: json['speakingTurns'] as int? ?? 0,
      deckWordsReviewed: json['deckWordsReviewed'] as int? ?? 0,
      levelHistory: rawHistory is List
          ? rawHistory
              .map(
                (e) => LanguageLevelHistoryEntry.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList()
          : const [],
    );
  }
}

class LanguageLevelsSnapshot {
  final String practiceLanguage;
  final String tutorLevel;
  final String estimatedLevel;
  final int speakingTurns;
  final int deckWordsReviewed;
  final int uniqueWordsSpoken;
  final List<LanguageLevelHistoryEntry> levelHistory;
  final List<LanguageLevelRecord> languages;

  const LanguageLevelsSnapshot({
    this.practiceLanguage = 'en',
    this.tutorLevel = 'A1',
    this.estimatedLevel = 'A1',
    this.speakingTurns = 0,
    this.deckWordsReviewed = 0,
    this.uniqueWordsSpoken = 0,
    this.levelHistory = const [],
    this.languages = const [],
  });

  factory LanguageLevelsSnapshot.fromJson(Map<String, dynamic> json) {
    final rawLanguages = json['languages'];
    final rawHistory = json['levelHistory'];
    return LanguageLevelsSnapshot(
      practiceLanguage: json['practiceLanguage'] as String? ?? 'en',
      tutorLevel: json['tutorLevel'] as String? ?? 'A1',
      estimatedLevel: json['estimatedLevel'] as String? ?? 'A1',
      speakingTurns: json['speakingTurns'] as int? ?? 0,
      deckWordsReviewed: json['deckWordsReviewed'] as int? ?? 0,
      uniqueWordsSpoken: json['uniqueWordsSpoken'] as int? ?? 0,
      levelHistory: rawHistory is List
          ? rawHistory
              .map(
                (e) => LanguageLevelHistoryEntry.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList()
          : const [],
      languages: rawLanguages is List
          ? rawLanguages
              .map(
                (e) => LanguageLevelRecord.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList()
          : const [],
    );
  }
}
