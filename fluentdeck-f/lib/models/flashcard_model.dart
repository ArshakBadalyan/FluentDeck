import 'package:fluentdeck/models/occlusion_model.dart';
import 'package:fluentdeck/services/deck_scheduling_defaults.dart';

class CardReviewStateModel {
  final int? id;
  final String state;
  final double intervalDays;
  final double easeFactor;
  final DateTime? dueAt;
  final int lapses;
  final int repetitions;
  final int learningStep;
  final DateTime? lastReviewedAt;
  final bool suspended;
  final DateTime? buriedUntil;

  const CardReviewStateModel({
    this.id,
    this.state = 'new',
    this.intervalDays = 0,
    this.easeFactor = 2.5,
    this.dueAt,
    this.lapses = 0,
    this.repetitions = 0,
    this.learningStep = 0,
    this.lastReviewedAt,
    this.suspended = false,
    this.buriedUntil,
  });

  bool get isDue {
    if (suspended) return false;
    if (buriedUntil != null && buriedUntil!.isAfter(DateTime.now())) return false;
    if (state == 'new') return true;
    if (dueAt == null) return true;
    return dueAt!.isBefore(DateTime.now()) ||
        dueAt!.isAtSameMomentAs(DateTime.now());
  }

  factory CardReviewStateModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CardReviewStateModel();
    return CardReviewStateModel(
      id: json['id'] as int?,
      state: json['state'] as String? ?? 'new',
      intervalDays: (json['intervalDays'] as num?)?.toDouble() ?? 0,
      easeFactor: (json['easeFactor'] as num?)?.toDouble() ?? 2.5,
      dueAt:
          json['dueAt'] != null
              ? DateTime.tryParse(json['dueAt'].toString())
              : null,
      lapses: json['lapses'] as int? ?? 0,
      repetitions: json['repetitions'] as int? ?? 0,
      learningStep: json['learningStep'] as int? ?? 0,
      lastReviewedAt:
          json['lastReviewedAt'] != null
              ? DateTime.tryParse(json['lastReviewedAt'].toString())
              : null,
      suspended: json['suspended'] == true,
      buriedUntil:
          json['buriedUntil'] != null
              ? DateTime.tryParse(json['buriedUntil'].toString())
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'state': state,
    'intervalDays': intervalDays,
    'easeFactor': easeFactor,
    'dueAt': dueAt?.toIso8601String(),
    'lapses': lapses,
    'repetitions': repetitions,
    'learningStep': learningStep,
    'lastReviewedAt': lastReviewedAt?.toIso8601String(),
    'suspended': suspended,
    'buriedUntil': buriedUntil?.toIso8601String(),
  };
}

class FlashcardModel {
  final int id;
  final int deckId;
  final int? noteId;
  final String? noteTypeId;
  final String front;
  final String back;
  final String cardType;
  final String? clozeText;
  final int? clozeIndex;
  final String templateName;
  final int templateOrdinal;
  final int? siblingCardCount;
  final List<String> tags;
  final String? mediaUrl;
  final int flag;
  final String languageCode;
  final String? deckName;
  final bool noteMarked;
  final CardReviewStateModel? reviewState;
  final OcclusionData? occlusionData;

  const FlashcardModel({
    required this.id,
    required this.deckId,
    this.noteId,
    this.noteTypeId,
    required this.front,
    required this.back,
    this.cardType = 'basic',
    this.clozeText,
    this.clozeIndex,
    this.templateName = 'Card 1',
    this.templateOrdinal = 0,
    this.siblingCardCount,
    this.tags = const [],
    this.mediaUrl,
    this.flag = 0,
    this.languageCode = 'en',
    this.deckName,
    this.noteMarked = false,
    this.reviewState,
    this.occlusionData,
  });

  bool get isImageOcclusion => cardType == 'image_occlusion';

  String get displayFront =>
      cardType == 'cloze' && clozeText != null && clozeText!.isNotEmpty
          ? clozeText!
          : front;

  factory FlashcardModel.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];
    return FlashcardModel(
      id: json['id'] as int? ?? 0,
      deckId: json['deckId'] as int? ?? 0,
      noteId: json['noteId'] as int?,
      noteTypeId: json['noteTypeId'] as String?,
      front: json['front'] as String? ?? '',
      back: json['back'] as String? ?? '',
      cardType: json['cardType'] as String? ?? 'basic',
      clozeText: json['clozeText'] as String?,
      clozeIndex: json['clozeIndex'] as int?,
      templateName: json['templateName'] as String? ?? 'Card 1',
      templateOrdinal: json['templateOrdinal'] as int? ?? 0,
      siblingCardCount: json['siblingCardCount'] as int?,
      tags:
          rawTags is List
              ? rawTags.map((e) => e.toString()).toList()
              : const [],
      mediaUrl: json['mediaUrl'] as String?,
      flag: json['flag'] as int? ?? 0,
      languageCode: json['languageCode'] as String? ?? 'en',
      deckName: json['deckName'] as String?,
      noteMarked: json['noteMarked'] == true,
      occlusionData:
          json['occlusionData'] is Map
              ? OcclusionData.fromJson(
                Map<String, dynamic>.from(json['occlusionData'] as Map),
              )
              : null,
      reviewState: CardReviewStateModel.fromJson(
        json['reviewState'] is Map
            ? Map<String, dynamic>.from(json['reviewState'] as Map)
            : null,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'deckId': deckId,
    if (noteId != null) 'noteId': noteId,
    if (noteTypeId != null) 'noteTypeId': noteTypeId,
    'front': front,
    'back': back,
    'cardType': cardType,
    'clozeText': clozeText,
    if (clozeIndex != null) 'clozeIndex': clozeIndex,
    'templateName': templateName,
    'templateOrdinal': templateOrdinal,
    if (siblingCardCount != null) 'siblingCardCount': siblingCardCount,
    'tags': tags,
    'mediaUrl': mediaUrl,
    'flag': flag,
    if (deckName != null) 'deckName': deckName,
    'noteMarked': noteMarked,
    if (occlusionData != null) 'occlusionData': occlusionData!.toJson(),
    'reviewState': reviewState?.toJson(),
  };
}

class DeckOptionsModel {
  final int newCardsPerDay;
  final int maxReviewsPerDay;
  final int leechThreshold;
  final List<int> learningStepsMinutes;
  final double graduatingIntervalDays;
  final double easyIntervalDays;
  final double easyBonus;
  final List<int> lapseStepsMinutes;
  final double minimumIntervalDays;

  const DeckOptionsModel({
    this.newCardsPerDay = 20,
    this.maxReviewsPerDay = 200,
    this.leechThreshold = 8,
    this.learningStepsMinutes = const [2, 8, 10],
    this.graduatingIntervalDays = 1,
    this.easyIntervalDays = 5,
    this.easyBonus = 1.3,
    this.lapseStepsMinutes = const [10],
    this.minimumIntervalDays = 1,
  });

  factory DeckOptionsModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return DeckSchedulingDefaults.deckOptions;
    final fallbackSteps = DeckSchedulingDefaults.learningStepsMinutes;
    final fallbackEasy = DeckSchedulingDefaults.easyIntervalDays;
    return DeckOptionsModel(
      newCardsPerDay: json['newCardsPerDay'] as int? ?? 20,
      maxReviewsPerDay: json['maxReviewsPerDay'] as int? ?? 200,
      leechThreshold: json['leechThreshold'] as int? ?? 8,
      learningStepsMinutes: _parseIntList(json['learningStepsMinutes'], fallbackSteps),
      graduatingIntervalDays:
          (json['graduatingIntervalDays'] as num?)?.toDouble() ?? 1,
      easyIntervalDays:
          (json['easyIntervalDays'] as num?)?.toDouble() ?? fallbackEasy,
      easyBonus: (json['easyBonus'] as num?)?.toDouble() ?? 1.3,
      lapseStepsMinutes: _parseIntList(json['lapseStepsMinutes'], const [10]),
      minimumIntervalDays:
          (json['minimumIntervalDays'] as num?)?.toDouble() ?? 1,
    );
  }

  static List<int> _parseIntList(dynamic raw, List<int> fallback) {
    if (raw is! List) return fallback;
    final parsed =
        raw
            .map((e) => int.tryParse('$e') ?? 0)
            .where((n) => n > 0)
            .toList();
    return parsed.isEmpty ? fallback : parsed;
  }

  Map<String, dynamic> toJson() => {
    'newCardsPerDay': newCardsPerDay,
    'maxReviewsPerDay': maxReviewsPerDay,
    'leechThreshold': leechThreshold,
    'learningStepsMinutes': learningStepsMinutes,
    'graduatingIntervalDays': graduatingIntervalDays,
    'easyIntervalDays': easyIntervalDays,
    'easyBonus': easyBonus,
    'lapseStepsMinutes': lapseStepsMinutes,
    'minimumIntervalDays': minimumIntervalDays,
  };
}

class FlashcardDeckModel {
  final int id;
  final String name;
  final String deckSlug;
  final bool isDefault;
  final bool isFiltered;
  final Map<String, dynamic>? filterQuery;
  final int? parentDeckId;
  final String description;
  final DeckOptionsModel? deckOptions;
  final int total;
  final int newCount;
  final int learningCount;
  final int reviewDueCount;

  const FlashcardDeckModel({
    required this.id,
    required this.name,
    this.deckSlug = '',
    this.isDefault = false,
    this.isFiltered = false,
    this.filterQuery,
    this.parentDeckId,
    this.description = '',
    this.deckOptions,
    this.total = 0,
    this.newCount = 0,
    this.learningCount = 0,
    this.reviewDueCount = 0,
  });

  int get dueCount => learningCount + reviewDueCount;

  bool get isDeletable => !isDefault;

  factory FlashcardDeckModel.fromJson(Map<String, dynamic> json) {
    final rawFilter = json['filterQuery'];
    return FlashcardDeckModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      deckSlug: json['deckSlug'] as String? ?? '',
      isDefault: json['isDefault'] == true,
      isFiltered: json['isFiltered'] == true,
      filterQuery:
          rawFilter is Map ? Map<String, dynamic>.from(rawFilter) : null,
      parentDeckId: json['parentDeckId'] as int?,
      description: json['description'] as String? ?? '',
      deckOptions:
          json['deckOptions'] is Map
              ? DeckOptionsModel.fromJson(
                Map<String, dynamic>.from(json['deckOptions'] as Map),
              )
              : null,
      total: json['total'] as int? ?? 0,
      newCount: json['newCount'] as int? ?? 0,
      learningCount: json['learningCount'] as int? ?? 0,
      reviewDueCount: json['reviewDueCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'deckSlug': deckSlug,
    'isDefault': isDefault,
    'isFiltered': isFiltered,
    if (filterQuery != null) 'filterQuery': filterQuery,
    if (parentDeckId != null) 'parentDeckId': parentDeckId,
    'description': description,
    if (deckOptions != null) 'deckOptions': deckOptions!.toJson(),
    'total': total,
    'newCount': newCount,
    'learningCount': learningCount,
    'reviewDueCount': reviewDueCount,
  };
}

class FlashcardStudyStats {
  final int totalCards;
  final int dueNow;
  final int newCards;
  final int? newCardsDailyLimit;
  final int reviewStreakDays;
  final bool isPremium;
  final int todayReviews;
  final int todayDurationMs;

  const FlashcardStudyStats({
    this.totalCards = 0,
    this.dueNow = 0,
    this.newCards = 0,
    this.newCardsDailyLimit,
    this.reviewStreakDays = 0,
    this.isPremium = false,
    this.todayReviews = 0,
    this.todayDurationMs = 0,
  });

  String get todayDurationLabel {
    if (todayDurationMs < 1000) return '${todayDurationMs}ms';
    final secs = todayDurationMs ~/ 1000;
    if (secs < 60) return '${secs}s';
    final mins = secs ~/ 60;
    final rem = secs % 60;
    return rem > 0 ? '${mins}m ${rem}s' : '${mins}m';
  }

  factory FlashcardStudyStats.fromJson(Map<String, dynamic> json) {
    final limit = json['newCardsDailyLimit'];
    return FlashcardStudyStats(
      totalCards: json['totalCards'] as int? ?? 0,
      dueNow: json['dueNow'] as int? ?? 0,
      newCards: json['newCards'] as int? ?? 0,
      newCardsDailyLimit: limit == null ? null : (limit as num).toInt(),
      reviewStreakDays: json['reviewStreakDays'] as int? ?? 0,
      isPremium: json['isPremium'] == true,
      todayReviews: json['todayReviews'] as int? ?? 0,
      todayDurationMs: json['todayDurationMs'] as int? ?? 0,
    );
  }
}

class FlashcardImportResult {
  final bool ok;
  final int imported;
  final int skipped;
  final List<String> errors;

  const FlashcardImportResult({
    this.ok = false,
    this.imported = 0,
    this.skipped = 0,
    this.errors = const [],
  });

  factory FlashcardImportResult.fromJson(dynamic data) {
    if (data is! Map) {
      throw Exception('Invalid import response');
    }
    final err = data['error'];
    if (err is Map && err['message'] != null) {
      throw Exception(err['message'].toString());
    }
    final rawErrors = data['errors'];
    return FlashcardImportResult(
      ok: data['ok'] == true,
      imported: data['imported'] as int? ?? 0,
      skipped: data['skipped'] as int? ?? 0,
      errors:
          rawErrors is List
              ? rawErrors.map((e) => e.toString()).toList()
              : const [],
    );
  }
}
