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

  /// Null when there is no committed AI speaking assessment yet — see
  /// [estimatedLevelStatus] for why (not enough evidence, or a legacy
  /// activity-based estimate that was never a real assessment). Callers
  /// must not assume this is always a valid CEFR string.
  final String? estimatedLevel;

  /// 'assessed' | 'insufficient_evidence' | 'legacy_unassessed'.
  final String estimatedLevelStatus;
  final DateTime? lastActiveAt;
  final DateTime? firstSelectedAt;
  final int speakingTurns;
  final int deckWordsReviewed;
  /// Notes (and their cards) saved in this language.
  final int noteCount;
  final List<LanguageLevelHistoryEntry> levelHistory;

  const LanguageLevelRecord({
    required this.languageCode,
    this.tutorLevel = 'A1',
    this.estimatedLevel,
    this.estimatedLevelStatus = 'insufficient_evidence',
    this.lastActiveAt,
    this.firstSelectedAt,
    this.speakingTurns = 0,
    this.deckWordsReviewed = 0,
    this.noteCount = 0,
    this.levelHistory = const [],
  });

  /// True once a real AI speaking assessment has committed a level.
  bool get hasAssessedLevel => estimatedLevelStatus == 'assessed' && estimatedLevel != null;

  factory LanguageLevelRecord.fromJson(Map<String, dynamic> json) {
    final rawHistory = json['levelHistory'];
    return LanguageLevelRecord(
      languageCode: json['languageCode'] as String? ?? 'en',
      tutorLevel: json['tutorLevel'] as String? ?? 'A1',
      estimatedLevel: json['estimatedLevel'] as String?,
      estimatedLevelStatus:
          json['estimatedLevelStatus'] as String? ?? 'insufficient_evidence',
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.tryParse(json['lastActiveAt'].toString())
          : null,
      firstSelectedAt: json['firstSelectedAt'] != null
          ? DateTime.tryParse(json['firstSelectedAt'].toString())
          : null,
      speakingTurns: json['speakingTurns'] as int? ?? 0,
      deckWordsReviewed: json['deckWordsReviewed'] as int? ?? 0,
      noteCount: json['noteCount'] as int? ?? 0,
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

  /// Null when there is no committed AI speaking assessment yet for
  /// [practiceLanguage] — see [estimatedLevelStatus].
  final String? estimatedLevel;

  /// 'assessed' | 'insufficient_evidence' | 'legacy_unassessed'.
  final String estimatedLevelStatus;
  final int speakingTurns;
  final int deckWordsReviewed;
  final int uniqueWordsSpoken;
  final List<LanguageLevelHistoryEntry> levelHistory;
  final List<LanguageLevelRecord> languages;

  const LanguageLevelsSnapshot({
    this.practiceLanguage = 'en',
    this.tutorLevel = 'A1',
    this.estimatedLevel,
    this.estimatedLevelStatus = 'insufficient_evidence',
    this.speakingTurns = 0,
    this.deckWordsReviewed = 0,
    this.uniqueWordsSpoken = 0,
    this.levelHistory = const [],
    this.languages = const [],
  });

  /// True once a real AI speaking assessment has committed a level.
  bool get hasAssessedLevel => estimatedLevelStatus == 'assessed' && estimatedLevel != null;

  factory LanguageLevelsSnapshot.fromJson(Map<String, dynamic> json) {
    final rawLanguages = json['languages'];
    final rawHistory = json['levelHistory'];
    return LanguageLevelsSnapshot(
      practiceLanguage: json['practiceLanguage'] as String? ?? 'en',
      tutorLevel: json['tutorLevel'] as String? ?? 'A1',
      estimatedLevel: json['estimatedLevel'] as String?,
      estimatedLevelStatus:
          json['estimatedLevelStatus'] as String? ?? 'insufficient_evidence',
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
