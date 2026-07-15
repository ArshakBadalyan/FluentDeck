import '../models/builtin_note_types.dart';
import '../models/flashcard_model.dart';
import '../models/flashcard_note_model.dart';
import '../models/flashcard_stats_model.dart';
import '../data/flashcard_offline_store.dart';
import '../utils/strapi_response.dart';
import 'api_service.dart';
import 'flashcard_sync_store.dart';
import 'review_settings_store.dart';

class ReviewSubmitResult {
  final FlashcardModel? card;
  final bool leechSuspended;

  const ReviewSubmitResult({this.card, this.leechSuspended = false});
}

class FlashcardSyncAllResult {
  final bool online;
  final int applied;
  final int skipped;
  final bool incremental;
  final String? serverCursor;

  const FlashcardSyncAllResult({
    required this.online,
    this.applied = 0,
    this.skipped = 0,
    this.incremental = false,
    this.serverCursor,
  });
}

class FlashcardCardInfo {
  final FlashcardModel card;
  final FlashcardNoteModel? note;
  final int siblingCount;
  final int templateOrdinal;
  final String templateName;

  const FlashcardCardInfo({
    required this.card,
    this.note,
    this.siblingCount = 1,
    this.templateOrdinal = 0,
    this.templateName = 'Card 1',
  });

  factory FlashcardCardInfo.fromJson(Map<String, dynamic> json) {
    final cardJson = json['card'];
    final noteJson = json['note'];
    final pos = json['position'];
    return FlashcardCardInfo(
      card:
          cardJson is Map
              ? FlashcardModel.fromJson(Map<String, dynamic>.from(cardJson))
              : throw const FormatException('Missing card'),
      note:
          noteJson is Map
              ? FlashcardNoteModel.fromJson(Map<String, dynamic>.from(noteJson))
              : null,
      siblingCount: pos is Map ? pos['siblingCount'] as int? ?? 1 : 1,
      templateOrdinal: pos is Map ? pos['templateOrdinal'] as int? ?? 0 : 0,
      templateName: pos is Map ? pos['templateName']?.toString() ?? 'Card 1' : 'Card 1',
    );
  }
}

class FlashcardService {
  FlashcardService._();
  static final FlashcardService instance = FlashcardService._();

  String? _extractError(dynamic data) {
    if (data is! Map) return null;
    final error = data['error'];
    if (error is Map && error['message'] != null) {
      return error['message'].toString();
    }
    return null;
  }

  Future<List<FlashcardDeckModel>> fetchDecks() async {
    final data = await ApiService.get('flashcards/decks');
    if (data is Map && data['error'] != null) {
      final message = _extractError(data) ?? 'Could not load decks';
      throw Exception(message);
    }
    final rows = StrapiResponse.list(data);
    return rows
        .whereType<Map>()
        .map((m) => FlashcardDeckModel.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  /// Online fetch with cached fallback for offline deck list (Phase 5E).
  Future<List<FlashcardDeckModel>> fetchDecksWithCache() async {
    try {
      return await fetchDecks();
    } catch (_) {
      final cached = await FlashcardOfflineStore.instance.loadSnapshot();
      return cached.decks;
    }
  }

  Future<FlashcardStudyStats> fetchStats() async {
    final data = await ApiService.get('flashcards/stats');
    if (data is! Map) return const FlashcardStudyStats();
    return FlashcardStudyStats.fromJson(Map<String, dynamic>.from(data));
  }

  Future<FlashcardDetailedStats> fetchDetailedStats({
    int? deckId,
    String range = '12m',
  }) async {
    final params = <String>['range=$range'];
    if (deckId != null) params.add('deckId=$deckId');
    final data = await ApiService.get('flashcards/stats/detailed?${params.join('&')}');
    if (data is! Map) return const FlashcardDetailedStats();

    final stats = FlashcardDetailedStats.fromJson(Map<String, dynamic>.from(data));
    try {
      final basic = await fetchStats();
      return FlashcardDetailedStats(
        scope: stats.scope,
        deckId: stats.deckId,
        deckName: stats.deckName,
        range: stats.range,
        today: stats.today,
        cardCounts: stats.cardCounts,
        totalCards: stats.totalCards,
        buttonCounts: stats.buttonCounts,
        reviewsByDay: stats.reviewsByDay,
        addedByDay: stats.addedByDay,
        futureDueByDay: stats.futureDueByDay,
        calendar: stats.calendar,
        totalReviewsInRange: stats.totalReviewsInRange,
        reviewStreakDays: basic.reviewStreakDays,
        easeBuckets: stats.easeBuckets,
        intervalBuckets: stats.intervalBuckets,
        retention: stats.retention,
        hourly: stats.hourly,
      );
    } catch (_) {
      return stats;
    }
  }

  Future<List<FlashcardReviewLogEntry>> fetchReviewLog({
    int? deckId,
    int limit = 50,
  }) async {
    final params = <String>['limit=$limit'];
    if (deckId != null) params.add('deckId=$deckId');
    final data = await ApiService.get('flashcards/review-log?${params.join('&')}');
    final rows = StrapiResponse.list(data);
    return rows
        .whereType<Map>()
        .map((m) => FlashcardReviewLogEntry.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<({FlashcardDeckModel deck, List<FlashcardModel> cards})> fetchDeckDetail(
    int deckId,
  ) async {
    final data = await ApiService.get('flashcards/decks/$deckId');
    if (data is! Map) {
      throw Exception('Could not load deck');
    }
    final deckJson = data['deck'];
    final cardsJson = data['cards'] as List? ?? [];
    final cards =
        cardsJson
            .whereType<Map>()
            .map((m) => FlashcardModel.fromJson(Map<String, dynamic>.from(m)))
            .toList();
    return (deck: FlashcardDeckModel.fromJson(Map<String, dynamic>.from(deckJson as Map)), cards: cards);
  }

  Future<List<FlashcardModel>> fetchReviewQueue({
    int? deckId,
    int limit = 20,
    NewCardPosition? newCardOrder,
    int? learnAheadMinutes,
  }) async {
    final params = <String>['limit=$limit'];
    if (deckId != null) params.add('deckId=$deckId');
    if (newCardOrder != null) {
      params.add('newCardOrder=${_newCardOrderQuery(newCardOrder)}');
    }
    if (learnAheadMinutes != null && learnAheadMinutes > 0) {
      params.add('learnAheadMinutes=$learnAheadMinutes');
    }
    final data = await ApiService.get('flashcards/review/queue?${params.join('&')}');
    final rows = data is Map ? data['queue'] as List? : null;
    return (rows ?? [])
        .whereType<Map>()
        .map((m) => FlashcardModel.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<ReviewSubmitResult> submitReview({
    required int flashcardId,
    required String rating,
    int? durationMs,
  }) async {
    final data = await ApiService.post('flashcards/review/answer', {
      'flashcardId': flashcardId,
      'rating': rating,
      if (durationMs != null) 'durationMs': durationMs,
    });
    if (data is! Map) return const ReviewSubmitResult();
    final err = _extractError(data);
    if (err != null) throw Exception(err);
    final card = data['card'];
    FlashcardModel? model;
    if (card is Map) {
      model = FlashcardModel.fromJson(Map<String, dynamic>.from(card));
    }
    return ReviewSubmitResult(
      card: model,
      leechSuspended: data['leechSuspended'] == true,
    );
  }

  Future<FlashcardDeckModel?> createDeck({
    required String name,
    String? description,
    int? parentDeckId,
  }) async {
    final data = await ApiService.post('flashcards/decks', {
      'name': name,
      'description': description,
      if (parentDeckId != null) 'parentDeckId': parentDeckId,
    });
    if (data is! Map) return null;
    final err = _extractError(data);
    if (err != null) throw Exception(err);
    final deck = data['deck'];
    if (deck is! Map) return null;
    return FlashcardDeckModel.fromJson(Map<String, dynamic>.from(deck));
  }

  Future<FlashcardDeckModel?> updateDeck(
    int deckId, {
    String? name,
    String? description,
    int? parentDeckId,
    bool clearParent = false,
    Map<String, dynamic>? deckOptions,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (clearParent) {
      body['parentDeckId'] = null;
    } else if (parentDeckId != null) {
      body['parentDeckId'] = parentDeckId;
    }
    if (deckOptions != null) body['deckOptions'] = deckOptions;
    final data = await ApiService.put('flashcards/decks/$deckId', body);
    if (data is! Map) return null;
    final err = _extractError(data);
    if (err != null) throw Exception(err);
    final deck = data['deck'];
    if (deck is! Map) return null;
    return FlashcardDeckModel.fromJson(Map<String, dynamic>.from(deck));
  }

  Future<FlashcardDeckModel?> createFilteredDeck({
    required String name,
    required Map<String, dynamic> filterQuery,
    String? description,
  }) async {
    final data = await ApiService.post('flashcards/decks/filtered', {
      'name': name,
      'filterQuery': filterQuery,
      if (description != null) 'description': description,
    });
    if (data is! Map) return null;
    final err = _extractError(data);
    if (err != null) throw Exception(err);
    final deck = data['deck'];
    if (deck is! Map) return null;
    return FlashcardDeckModel.fromJson(Map<String, dynamic>.from(deck));
  }

  Future<List<NoteTypeModel>> fetchNoteTypes() async {
    final data = await ApiService.get('flashcards/note-types');
    final rows = StrapiResponse.list(data);
    final types =
        rows
            .whereType<Map>()
            .map((m) => NoteTypeModel.fromJson(Map<String, dynamic>.from(m)))
            .where((t) => t.available)
            .toList();
    await FlashcardOfflineStore.instance.saveNoteTypes(types);
    return types;
  }

  /// Online fetch with cached / built-in fallback (Phase 5E).
  Future<List<NoteTypeModel>> fetchNoteTypesWithCache() async {
    try {
      return await fetchNoteTypes();
    } catch (_) {
      final cached = await FlashcardOfflineStore.instance.loadNoteTypes();
      if (cached.isNotEmpty) {
        return cached.where((t) => t.available).toList();
      }
      return builtinNoteTypes().where((t) => t.available).toList();
    }
  }

  Future<NoteTypeModel> createCustomNoteType(NoteTypeModel draft) async {
    final data = await ApiService.post(
      'flashcards/note-types/custom',
      draft.toCustomPayload(),
    );
    if (data is! Map) throw Exception('Could not create note type');
    final err = _extractError(data);
    if (err != null) throw Exception(err);
    final row = StrapiResponse.row(data);
    if (row == null) throw Exception('Invalid note type response');
    return NoteTypeModel.fromJson(row);
  }

  Future<NoteTypeModel> updateCustomNoteType({
    required int id,
    required NoteTypeModel draft,
  }) async {
    final data = await ApiService.put(
      'flashcards/note-types/custom/$id',
      draft.toCustomPayload(),
    );
    if (data is! Map) throw Exception('Could not update note type');
    final err = _extractError(data);
    if (err != null) throw Exception(err);
    final row = StrapiResponse.row(data);
    if (row == null) throw Exception('Invalid note type response');
    return NoteTypeModel.fromJson(row);
  }

  Future<void> deleteCustomNoteType(int id) async {
    final data = await ApiService.delete('flashcards/note-types/custom/$id');
    if (data is Map && data['error'] != null) {
      throw Exception(_extractError(data) ?? 'Could not delete note type');
    }
  }

  Future<FlashcardNoteModel?> fetchNote(int noteId) async {
    final data = await ApiService.get('flashcards/notes/$noteId');
    if (data is! Map) return null;
    final note = data['note'];
    if (note is! Map) return null;
    return FlashcardNoteModel.fromJson(Map<String, dynamic>.from(note));
  }

  Future<({FlashcardNoteModel note, List<FlashcardModel> cards})> createNote({
    required int deckId,
    required String noteType,
    required Map<String, String> fields,
    List<String>? tags,
    bool createReverse = false,
    String? mediaUrl,
    String? languageCode,
  }) async {
    final data = await ApiService.post('flashcards/notes', {
      'deckId': deckId,
      'noteType': noteType,
      'fields': fields,
      'tags': tags ?? [],
      'createReverse': createReverse,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      if (languageCode != null && languageCode.isNotEmpty) 'languageCode': languageCode,
    });
    if (data is! Map) throw Exception('Could not create note');
    final err = _extractError(data);
    if (err != null) throw Exception(err);

    final noteJson = data['note'];
    final cardsJson = data['cards'] as List? ?? [];
    if (noteJson is! Map) throw Exception('Invalid note response');

    final cards =
        cardsJson
            .whereType<Map>()
            .map((m) => FlashcardModel.fromJson(Map<String, dynamic>.from(m)))
            .toList();
    return (
      note: FlashcardNoteModel.fromJson(Map<String, dynamic>.from(noteJson)),
      cards: cards,
    );
  }

  Future<FlashcardNoteModel?> updateNote({
    required int noteId,
    String? noteType,
    Map<String, String>? fields,
    List<String>? tags,
    bool? createReverse,
    String? mediaUrl,
    int? deckId,
    bool? marked,
  }) async {
    final body = <String, dynamic>{};
    if (noteType != null) body['noteType'] = noteType;
    if (fields != null) body['fields'] = fields;
    if (tags != null) body['tags'] = tags;
    if (createReverse != null) body['createReverse'] = createReverse;
    if (mediaUrl != null) body['mediaUrl'] = mediaUrl;
    if (deckId != null) body['deckId'] = deckId;
    if (marked != null) body['marked'] = marked;

    final data = await ApiService.put('flashcards/notes/$noteId', body);
    if (data is! Map) return null;
    final err = _extractError(data);
    if (err != null) throw Exception(err);
    final noteJson = data['note'];
    if (noteJson is! Map) return null;
    return FlashcardNoteModel.fromJson(Map<String, dynamic>.from(noteJson));
  }

  /// Safe note-type migration with card regeneration (Step 7 API).
  Future<({FlashcardNoteModel note, List<FlashcardModel> cards})> changeNoteType({
    required int noteId,
    required String noteType,
    bool? createReverse,
  }) async {
    final body = <String, dynamic>{'noteType': noteType};
    if (createReverse != null) body['createReverse'] = createReverse;

    final data = await ApiService.post('flashcards/notes/$noteId/change-type', body);
    if (data is! Map) throw Exception('Could not change note type');
    final err = _extractError(data);
    if (err != null) throw Exception(err);

    final noteJson = data['note'];
    final cardsJson = data['cards'] as List? ?? [];
    if (noteJson is! Map) throw Exception('Invalid note response');

    return (
      note: FlashcardNoteModel.fromJson(Map<String, dynamic>.from(noteJson)),
      cards:
          cardsJson
              .whereType<Map>()
              .map((m) => FlashcardModel.fromJson(Map<String, dynamic>.from(m)))
              .toList(),
    );
  }

  Future<bool> deleteNote(int noteId) async {
    final data = await ApiService.delete('flashcards/notes/$noteId');
    if (data is Map && data['ok'] == true) return true;
    throw Exception(_extractError(data) ?? 'Could not delete note');
  }

  Future<FlashcardModel?> createCard({
    required int deckId,
    required String front,
    required String back,
    String noteType = 'basic',
    String cardType = 'basic',
    String? clozeText,
    List<String>? tags,
    String? mediaUrl,
    bool createReverse = false,
    String? languageCode,
  }) async {
    final resolvedNoteType =
        noteType != 'basic' ? noteType : (cardType == 'cloze' ? 'cloze' : 'basic');

    final fields =
        resolvedNoteType == 'cloze'
            ? {'Text': clozeText ?? front, 'Back': back}
            : {'Front': front, 'Back': back};

    final result = await createNote(
      deckId: deckId,
      noteType: resolvedNoteType,
      fields: fields,
      tags: tags,
      createReverse: createReverse,
      mediaUrl: mediaUrl,
      languageCode: languageCode,
    );
    return result.cards.isNotEmpty ? result.cards.first : null;
  }

  Future<bool> deleteCard(int cardId) async {
    final data = await ApiService.delete('flashcards/cards/$cardId');
    if (data is Map && data['ok'] == true) return true;
    throw Exception(_extractError(data) ?? 'Could not delete card');
  }

  Future<FlashcardCardInfo> fetchCardInfo(int cardId) async {
    final data = await ApiService.get('flashcards/cards/$cardId/info');
    if (data is! Map) throw Exception('Could not load card info');
    final err = _extractError(data);
    if (err != null) throw Exception(err);
    return FlashcardCardInfo.fromJson(Map<String, dynamic>.from(data));
  }

  Future<FlashcardModel?> setCardDue(int cardId, DateTime dueAt) async {
    final data = await ApiService.post('flashcards/cards/$cardId/set-due', {
      'dueAt': dueAt.toIso8601String(),
    });
    return _parseCardResponse(data);
  }

  Future<FlashcardModel?> resetCardProgress(int cardId) async {
    final data = await ApiService.post('flashcards/cards/$cardId/reset-progress', {});
    return _parseCardResponse(data);
  }

  Future<FlashcardModel?> gradeCardNow(int cardId, String rating) async {
    final data = await ApiService.post('flashcards/cards/$cardId/grade', {
      'rating': rating,
    });
    return _parseCardResponse(data);
  }

  Future<FlashcardModel?> repositionCard(int cardId, {required bool down}) async {
    final data = await ApiService.post('flashcards/cards/$cardId/reposition', {
      'direction': down ? 'down' : 'up',
    });
    return _parseCardResponse(data);
  }

  Future<Map<String, dynamic>> exportCardJson(int cardId) async {
    final data = await ApiService.get('flashcards/cards/$cardId/export');
    if (data is! Map) throw Exception('Export failed');
    final err = _extractError(data);
    if (err != null) throw Exception(err);
    return Map<String, dynamic>.from(data);
  }

  FlashcardModel? _parseCardResponse(dynamic data) {
    if (data is! Map) return null;
    final err = _extractError(data);
    if (err != null) throw Exception(err);
    final card = data['card'];
    if (card is! Map) return null;
    return FlashcardModel.fromJson(Map<String, dynamic>.from(card));
  }

  Future<bool> deleteDeck(int deckId) async {
    final data = await ApiService.delete('flashcards/decks/$deckId');
    if (data is Map && data['error'] != null) {
      throw Exception(_extractError(data) ?? 'Could not delete deck');
    }
    return data is Map && data['ok'] == true;
  }

  Future<List<FlashcardModel>> browseCards({
    int? deckId,
    String? query,
    String? tag,
    String? state,
    bool? marked,
    int? flag,
    String? languageCode,
  }) async {
    final params = <String>[];
    if (deckId != null) params.add('deckId=$deckId');
    if (query != null && query.trim().isNotEmpty) {
      params.add('q=${Uri.encodeComponent(query.trim())}');
    }
    if (tag != null && tag.trim().isNotEmpty) {
      params.add('tag=${Uri.encodeComponent(tag.trim())}');
    }
    if (state != null && state.isNotEmpty) params.add('state=$state');
    if (marked != null) params.add('marked=$marked');
    if (flag != null) {
      params.add(flag == 0 ? 'flag=none' : 'flag=$flag');
    }
    if (languageCode != null && languageCode.isNotEmpty && languageCode != 'all') {
      params.add('languageCode=${Uri.encodeComponent(languageCode)}');
    }

    final qs = params.isEmpty ? '' : '?${params.join('&')}';
    final data = await ApiService.get('flashcards/browse$qs');
    final rows = StrapiResponse.list(data);
    final cards =
        rows
            .whereType<Map>()
            .map((m) => FlashcardModel.fromJson(Map<String, dynamic>.from(m)))
            .toList();
    return cards;
  }

  Future<FlashcardModel?> suspendCard(int cardId) async {
    final data = await ApiService.post('flashcards/cards/$cardId/suspend', {});
    if (data is! Map) return null;
    final card = data['card'];
    if (card is! Map) return null;
    return FlashcardModel.fromJson(Map<String, dynamic>.from(card));
  }

  Future<FlashcardModel?> unsuspendCard(int cardId) async {
    final data = await ApiService.post('flashcards/cards/$cardId/unsuspend', {});
    if (data is! Map) return null;
    final card = data['card'];
    if (card is! Map) return null;
    return FlashcardModel.fromJson(Map<String, dynamic>.from(card));
  }

  Future<FlashcardModel?> buryCard(int cardId) async {
    final data = await ApiService.post('flashcards/cards/$cardId/bury', {});
    if (data is! Map) return null;
    final card = data['card'];
    if (card is! Map) return null;
    return FlashcardModel.fromJson(Map<String, dynamic>.from(card));
  }

  Future<FlashcardModel?> setCardFlag(int cardId, int flag) async {
    final data = await ApiService.post('flashcards/cards/$cardId/flag', {
      'flag': flag,
    });
    if (data is! Map) return null;
    final card = data['card'];
    if (card is! Map) return null;
    return FlashcardModel.fromJson(Map<String, dynamic>.from(card));
  }

  Future<void> setNoteMarked(int noteId, bool marked) async {
    await updateNote(noteId: noteId, marked: marked);
  }

  Future<Map<String, dynamic>?> exportJson({int? deckId}) async {
    final path =
        deckId != null
            ? 'flashcards/export/json?deckId=$deckId'
            : 'flashcards/export/json';
    final data = await ApiService.get(path);
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  Future<List<int>> exportApkg({int? deckId}) async {
    final path =
        deckId != null
            ? 'flashcards/export/apkg?deckId=$deckId'
            : 'flashcards/export/apkg';
    final res = await ApiService.getRaw(path);
    if (res.statusCode >= 400) {
      throw Exception('Export failed (${res.statusCode})');
    }
    return res.bodyBytes;
  }

  Future<FlashcardImportResult> importCsv(
    String csv, {
    int? deckId,
    bool createDecks = true,
  }) async {
    final data = await ApiService.post('flashcards/import/csv', {
      'csv': csv,
      if (deckId != null) 'deckId': deckId,
      'createDecks': createDecks,
    });
    return FlashcardImportResult.fromJson(data);
  }

  Future<FlashcardImportResult> importTxt(
    String text, {
    int? deckId,
    bool createDecks = true,
  }) async {
    final data = await ApiService.post('flashcards/import/txt', {
      'text': text,
      if (deckId != null) 'deckId': deckId,
      'createDecks': createDecks,
    });
    return FlashcardImportResult.fromJson(data);
  }

  Future<FlashcardImportResult> importApkgBytes(
    List<int> bytes, {
    String filename = 'import.apkg',
    int? deckId,
    bool createDecks = true,
    bool importScheduling = false,
  }) async {
    final data = await ApiService.postMultipart(
      'flashcards/import/apkg',
      field: 'file',
      bytes: bytes,
      filename: filename,
      fields: {
        if (deckId != null) 'deckId': '$deckId',
        'createDecks': createDecks ? 'true' : 'false',
        'importScheduling': importScheduling ? 'true' : 'false',
      },
    );
    return FlashcardImportResult.fromJson(data);
  }

  Future<FlashcardImportResult> importJsonBackup(
    Map<String, dynamic> data, {
    bool createDecks = true,
  }) async {
    final res = await ApiService.post('flashcards/import/json', {
      'data': data,
      'createDecks': createDecks,
    });
    return FlashcardImportResult.fromJson(res);
  }

  Future<String?> uploadMedia(List<int> bytes, String filename) async {
    final data = await ApiService.postMultipart(
      'flashcards/media/upload',
      field: 'file',
      bytes: bytes,
      filename: filename,
    );
    if (data is! Map) return null;
    final err = _extractError(data);
    if (err != null) throw Exception(err);
    return data['url']?.toString();
  }

  Future<FlashcardModel?> undoReview() async {
    final data = await ApiService.post('flashcards/review/undo', {});
    if (data is! Map) return null;
    if (data['error'] != null) {
      throw Exception(data['error'].toString());
    }
    final card = data['card'];
    if (card is! Map) return null;
    return FlashcardModel.fromJson(Map<String, dynamic>.from(card));
  }

  Future<int> burySiblings(int cardId) async {
    final data = await ApiService.post('flashcards/cards/$cardId/bury-siblings', {});
    if (data is! Map) return 0;
    if (data['error'] != null) {
      throw Exception(data['error'].toString());
    }
    return data['buried'] as int? ?? 0;
  }

  Future<FlashcardModel?> unburyCard(int cardId) async {
    final data = await ApiService.post('flashcards/cards/$cardId/unbury', {});
    if (data is! Map) return null;
    final card = data['card'];
    if (card is! Map) return null;
    return FlashcardModel.fromJson(Map<String, dynamic>.from(card));
  }

  Future<({bool incremental, String? serverCursor})> syncPullAndCache() async {
    final log = await FlashcardSyncStore.instance.load();
    final query =
        log.serverCursor != null && log.serverCursor!.isNotEmpty
            ? {'since': log.serverCursor!}
            : null;

    final data = await ApiService.get('flashcards/sync/pull', query: query);
    if (data is! Map) return (incremental: false, serverCursor: log.serverCursor);

    final err = _extractError(data);
    if (err != null) throw Exception(err);

    final decks =
        (data['decks'] as List? ?? [])
            .whereType<Map>()
            .map((m) => FlashcardDeckModel.fromJson(Map<String, dynamic>.from(m)))
            .toList();
    final cards =
        (data['cards'] as List? ?? [])
            .whereType<Map>()
            .map((m) => FlashcardModel.fromJson(Map<String, dynamic>.from(m)))
            .toList();

    final incremental = data['incremental'] == true;
    if (incremental) {
      await FlashcardOfflineStore.instance.mergeSnapshot(decks: decks, cards: cards);
    } else {
      await FlashcardOfflineStore.instance.saveSnapshot(decks: decks, cards: cards);
    }

    final serverCursor = data['serverCursor']?.toString();
    await FlashcardSyncStore.instance.save(
      FlashcardSyncLog(
        lastSuccessAt: DateTime.now(),
        lastError: null,
        lastApplied: log.lastApplied,
        lastSkipped: log.lastSkipped,
        serverCursor: serverCursor ?? log.serverCursor,
      ),
    );
    return (incremental: incremental, serverCursor: serverCursor ?? log.serverCursor);
  }

  Future<FlashcardSyncLog> fetchSyncStatus() async {
    final data = await ApiService.get('flashcards/sync/status');
    if (data is! Map) return FlashcardSyncStore.instance.load();
    final err = _extractError(data);
    if (err != null) throw Exception(err);

    final local = await FlashcardSyncStore.instance.load();
    return FlashcardSyncLog(
      lastSuccessAt: local.lastSuccessAt,
      lastError: local.lastError,
      lastApplied: local.lastApplied,
      lastSkipped: local.lastSkipped,
      serverCursor: local.serverCursor ?? data['lastPullAt']?.toString(),
    );
  }

  Future<({int applied, int skipped})> syncPushPending() async {
    final pending = await FlashcardOfflineStore.instance.pendingReviews();
    if (pending.isEmpty) return (applied: 0, skipped: 0);

    final data = await ApiService.post('flashcards/sync/push', {
      'reviews':
          pending
              .map(
                (p) => {
                  'flashcardId': p.flashcardId,
                  'rating': p.rating,
                  'reviewedAt': p.reviewedAt.toIso8601String(),
                },
              )
              .toList(),
    });

    if (data is! Map) {
      throw Exception('Sync push failed');
    }
    final err = _extractError(data);
    if (err != null) throw Exception(err);

    final appliedRows = data['appliedReviews'];
    if (appliedRows is List && appliedRows.isNotEmpty) {
      final applied =
          appliedRows
              .whereType<Map>()
              .map(
                (m) => (
                  flashcardId: m['flashcardId'] as int,
                  reviewedAt: DateTime.parse(m['reviewedAt'].toString()),
                ),
              )
              .toList();
      await FlashcardOfflineStore.instance.removePendingReviews(applied);
    } else {
      final applied = data['applied'] as int? ?? 0;
      if (applied >= pending.length) {
        await FlashcardOfflineStore.instance.clearPendingReviews();
      }
    }

    return (
      applied: data['applied'] as int? ?? 0,
      skipped: data['skipped'] as int? ?? 0,
    );
  }

  Future<FlashcardSyncAllResult> syncAll() async {
    try {
      final push = await syncPushPending();
      final pull = await syncPullAndCache();

      await FlashcardSyncStore.instance.save(
        FlashcardSyncLog(
          lastSuccessAt: DateTime.now(),
          lastError: null,
          lastApplied: push.applied,
          lastSkipped: push.skipped,
          serverCursor: pull.serverCursor,
        ),
      );

      return FlashcardSyncAllResult(
        online: true,
        applied: push.applied,
        skipped: push.skipped,
        incremental: pull.incremental,
        serverCursor: pull.serverCursor,
      );
    } catch (e) {
      final log = await FlashcardSyncStore.instance.load();
      await FlashcardSyncStore.instance.save(
        FlashcardSyncLog(
          lastSuccessAt: log.lastSuccessAt,
          lastError: e.toString(),
          lastApplied: log.lastApplied,
          lastSkipped: log.lastSkipped,
          serverCursor: log.serverCursor,
        ),
      );
      return const FlashcardSyncAllResult(online: false);
    }
  }

  Future<void> cacheReviewQueue({
    required List<FlashcardModel> queue,
    int? deckId,
  }) async {
    await FlashcardOfflineStore.instance.saveReviewQueue(queue, deckId: deckId);
  }

  Future<List<FlashcardModel>> loadCachedReviewQueue({int? deckId}) async {
    return FlashcardOfflineStore.instance.loadReviewQueue(deckId: deckId);
  }

  String _newCardOrderQuery(NewCardPosition position) {
    switch (position) {
      case NewCardPosition.mixed:
        return 'mixed';
      case NewCardPosition.beforeReviews:
        return 'before_reviews';
      case NewCardPosition.afterReviews:
        return 'after_reviews';
    }
  }
}
