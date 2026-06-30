import 'package:fluentdeck/models/speaking_session_record_model.dart';
import 'package:fluentdeck/services/api_service.dart';
import 'package:fluentdeck/services/tutor_memory_service.dart';

class StudyHallSpeakingWord {
  final String word;
  final String definition;
  final String deckName;
  final String deckSlug;
  final DateTime? savedAt;

  const StudyHallSpeakingWord({
    required this.word,
    required this.definition,
    required this.deckName,
    required this.deckSlug,
    this.savedAt,
  });

  factory StudyHallSpeakingWord.fromJson(Map<String, dynamic> json) {
    DateTime? savedAt;
    final raw = json['savedAt']?.toString();
    if (raw != null && raw.isNotEmpty) {
      savedAt = DateTime.tryParse(raw);
    }
    return StudyHallSpeakingWord(
      word: json['word']?.toString() ?? '',
      definition: json['definition']?.toString() ?? '',
      deckName: json['deckName']?.toString() ?? 'From speaking',
      deckSlug: json['deckSlug']?.toString() ?? 'from_speaking',
      savedAt: savedAt,
    );
  }
}

class StudyHallWeakArea {
  final String label;
  final int count;

  const StudyHallWeakArea({required this.label, required this.count});

  factory StudyHallWeakArea.fromJson(Map<String, dynamic> json) {
    return StudyHallWeakArea(
      label: json['label']?.toString() ??
          json['errorType']?.toString() ??
          'general',
      count: (json['count'] as num?)?.round() ?? 0,
    );
  }
}

class StudyHallStats {
  final int totalSessions;
  final int totalWordsFromSpeaking;
  final int memoryFactCount;

  const StudyHallStats({
    this.totalSessions = 0,
    this.totalWordsFromSpeaking = 0,
    this.memoryFactCount = 0,
  });

  factory StudyHallStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const StudyHallStats();
    return StudyHallStats(
      totalSessions: (json['totalSessions'] as num?)?.round() ?? 0,
      totalWordsFromSpeaking:
          (json['totalWordsFromSpeaking'] as num?)?.round() ?? 0,
      memoryFactCount: (json['memoryFactCount'] as num?)?.round() ?? 0,
    );
  }
}

class StudyHallSummary {
  final List<TutorMemoryFact> memoryFacts;
  final List<SpeakingSessionRecord> recentSessions;
  final List<StudyHallSpeakingWord> speakingWords;
  final List<StudyHallWeakArea> weakAreas;
  final StudyHallStats stats;

  const StudyHallSummary({
    this.memoryFacts = const [],
    this.recentSessions = const [],
    this.speakingWords = const [],
    this.weakAreas = const [],
    this.stats = const StudyHallStats(),
  });

  factory StudyHallSummary.fromJson(Map<String, dynamic> json) {
    return StudyHallSummary(
      memoryFacts: (json['memoryFacts'] as List? ?? [])
          .whereType<Map>()
          .map(
            (item) => TutorMemoryFact.fromJson(Map<String, dynamic>.from(item)),
          )
          .where((item) => item.fact.trim().isNotEmpty)
          .toList(),
      recentSessions: (json['recentSessions'] as List? ?? [])
          .whereType<Map>()
          .map(
            (item) =>
                SpeakingSessionRecord.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      speakingWords: (json['speakingWords'] as List? ?? [])
          .whereType<Map>()
          .map(
            (item) =>
                StudyHallSpeakingWord.fromJson(Map<String, dynamic>.from(item)),
          )
          .where((item) => item.word.trim().isNotEmpty)
          .toList(),
      weakAreas: (json['weakAreas'] as List? ?? [])
          .whereType<Map>()
          .map(
            (item) => StudyHallWeakArea.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      stats: StudyHallStats.fromJson(
        json['stats'] is Map
            ? Map<String, dynamic>.from(json['stats'] as Map)
            : null,
      ),
    );
  }
}

class StudyHallService {
  StudyHallService._();
  static final StudyHallService instance = StudyHallService._();

  Future<StudyHallSummary> fetchSummary() async {
    final data = await ApiService.get('study-hall/summary');
    if (data is! Map) {
      return const StudyHallSummary();
    }
    return StudyHallSummary.fromJson(Map<String, dynamic>.from(data));
  }
}
