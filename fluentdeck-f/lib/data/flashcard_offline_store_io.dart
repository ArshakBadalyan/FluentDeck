import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluentdeck/data/isar/flashcard_cache.dart';
import 'package:fluentdeck/models/flashcard_model.dart';
import 'package:fluentdeck/models/flashcard_note_model.dart';
import 'package:fluentdeck/models/occlusion_model.dart';

const _noteTypesKey = 'flashcard_note_types_cache_v1';

String reviewQueueDeckKey(int? deckId) =>
    deckId == null ? 'all' : 'deck:$deckId';

class FlashcardOfflineStore {
  FlashcardOfflineStore._();
  static final FlashcardOfflineStore instance = FlashcardOfflineStore._();

  Isar? _isar;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        CachedFlashcardDeckSchema,
        CachedFlashcardSchema,
        CachedReviewQueueSchema,
        PendingFlashcardReviewSchema,
      ],
      directory: dir.path,
    );
    _initialized = true;
  }

  Future<void> saveSnapshot({
    required List<FlashcardDeckModel> decks,
    required List<FlashcardModel> cards,
  }) async {
    await init();

    final isar = _isar!;
    await isar.writeTxn(() async {
      await isar.cachedFlashcardDecks.clear();
      await isar.cachedFlashcards.clear();
      for (final deck in decks) {
        await isar.cachedFlashcardDecks.put(
          CachedFlashcardDeck()
            ..serverId = deck.id
            ..name = deck.name
            ..deckSlug = deck.deckSlug
            ..isDefault = deck.isDefault
            ..total = deck.total
            ..newCount = deck.newCount
            ..learningCount = deck.learningCount
            ..reviewDueCount = deck.reviewDueCount
            ..deckOptionsJson =
                deck.deckOptions != null
                    ? jsonEncode(deck.deckOptions!.toJson())
                    : '',
        );
      }
      for (final card in cards) {
        await isar.cachedFlashcards.put(_cardToRow(card));
      }
    });
  }

  Future<void> mergeSnapshot({
    required List<FlashcardDeckModel> decks,
    required List<FlashcardModel> cards,
  }) async {
    await init();
    await _isar!.writeTxn(() async {
      for (final deck in decks) {
        await _isar!.cachedFlashcardDecks.put(
          CachedFlashcardDeck()
            ..serverId = deck.id
            ..name = deck.name
            ..deckSlug = deck.deckSlug
            ..isDefault = deck.isDefault
            ..total = deck.total
            ..newCount = deck.newCount
            ..learningCount = deck.learningCount
            ..reviewDueCount = deck.reviewDueCount
            ..deckOptionsJson =
                deck.deckOptions != null
                    ? jsonEncode(deck.deckOptions!.toJson())
                    : '',
        );
      }
      for (final card in cards) {
        await _isar!.cachedFlashcards.put(_cardToRow(card));
      }
    });
  }

  CachedFlashcard _cardToRow(FlashcardModel card) {
    final rs = card.reviewState;
    return CachedFlashcard()
      ..serverId = card.id
      ..deckServerId = card.deckId
      ..front = card.front
      ..back = card.back
      ..cardType = card.cardType
      ..clozeText = card.clozeText
      ..clozeIndex = card.clozeIndex ?? 0
      ..mediaUrl = card.mediaUrl
      ..occlusionDataJson =
          card.occlusionData != null ? jsonEncode(card.occlusionData!.toJson()) : ''
      ..tagsJson = jsonEncode(card.tags)
      ..state = rs?.state ?? 'new'
      ..intervalDays = rs?.intervalDays ?? 0
      ..easeFactor = rs?.easeFactor ?? 2.5
      ..dueAt = rs?.dueAt
      ..lapses = rs?.lapses ?? 0
      ..repetitions = rs?.repetitions ?? 0
      ..learningStep = rs?.learningStep ?? 0;
  }

  FlashcardModel _rowToCard(CachedFlashcard c) {
    OcclusionData? occlusion;
    if (c.occlusionDataJson.isNotEmpty) {
      try {
        final raw = jsonDecode(c.occlusionDataJson);
        if (raw is Map) {
          occlusion = OcclusionData.fromJson(Map<String, dynamic>.from(raw));
        }
      } catch (_) {}
    }

    return FlashcardModel(
      id: c.serverId,
      deckId: c.deckServerId,
      front: c.front,
      back: c.back,
      cardType: c.cardType,
      clozeText: c.clozeText,
      clozeIndex: c.clozeIndex == 0 ? null : c.clozeIndex,
      mediaUrl: c.mediaUrl,
      tags:
          (jsonDecode(c.tagsJson) as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      occlusionData: occlusion,
      reviewState: CardReviewStateModel(
        state: c.state,
        intervalDays: c.intervalDays,
        easeFactor: c.easeFactor,
        dueAt: c.dueAt,
        lapses: c.lapses,
        repetitions: c.repetitions,
        learningStep: c.learningStep,
      ),
    );
  }

  Future<({List<FlashcardDeckModel> decks, List<FlashcardModel> cards})>
  loadSnapshot() async {
    await init();

    final isar = _isar!;
    final deckRows = await isar.cachedFlashcardDecks.where().findAll();
    final cardRows = await isar.cachedFlashcards.where().findAll();

    final decks =
        deckRows
            .map((d) {
              DeckOptionsModel? options;
              if (d.deckOptionsJson.isNotEmpty) {
                try {
                  final raw = jsonDecode(d.deckOptionsJson);
                  if (raw is Map) {
                    options = DeckOptionsModel.fromJson(
                      Map<String, dynamic>.from(raw),
                    );
                  }
                } catch (_) {}
              }
              return FlashcardDeckModel(
                id: d.serverId,
                name: d.name,
                deckSlug: d.deckSlug,
                isDefault: d.isDefault,
                deckOptions: options,
                total: d.total,
                newCount: d.newCount,
                learningCount: d.learningCount,
                reviewDueCount: d.reviewDueCount,
              );
            })
            .toList();

    final cards = cardRows.map(_rowToCard).toList();

    return (decks: decks, cards: cards);
  }

  Future<void> saveReviewQueue(
    List<FlashcardModel> queue, {
    int? deckId,
  }) async {
    await init();
    final key = reviewQueueDeckKey(deckId);
    await _isar!.writeTxn(() async {
      await _isar!.cachedReviewQueues.put(
        CachedReviewQueue()
          ..deckKey = key
          ..cardsJson = jsonEncode(queue.map((c) => c.toJson()).toList())
          ..savedAt = DateTime.now(),
      );
      for (final card in queue) {
        await _isar!.cachedFlashcards.put(_cardToRow(card));
      }
    });
  }

  Future<List<FlashcardModel>> loadReviewQueue({int? deckId}) async {
    await init();
    final key = reviewQueueDeckKey(deckId);
    final row = await _isar!.cachedReviewQueues.filter().deckKeyEqualTo(key).findFirst();
    if (row == null) return [];
    try {
      final list = jsonDecode(row.cardsJson) as List? ?? [];
      return list
          .whereType<Map>()
          .map((m) => FlashcardModel.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> updateCachedCard(FlashcardModel card) async {
    await init();
    await _isar!.writeTxn(() async {
      await _isar!.cachedFlashcards.put(_cardToRow(card));
    });
  }

  Future<void> queueReview({
    required int flashcardId,
    required String rating,
    required DateTime reviewedAt,
  }) async {
    await init();

    await _isar!.writeTxn(() async {
      await _isar!.pendingFlashcardReviews.put(
        PendingFlashcardReview()
          ..flashcardServerId = flashcardId
          ..rating = rating
          ..reviewedAt = reviewedAt,
      );
    });
  }

  Future<List<({int flashcardId, String rating, DateTime reviewedAt})>>
  pendingReviews() async {
    await init();

    final rows = await _isar!.pendingFlashcardReviews.where().findAll();
    return rows
        .map(
          (r) => (
            flashcardId: r.flashcardServerId,
            rating: r.rating,
            reviewedAt: r.reviewedAt,
          ),
        )
        .toList();
  }

  Future<int> pendingReviewCount() async {
    await init();
    return _isar!.pendingFlashcardReviews.count();
  }

  Future<void> clearPendingReviews() async {
    await init();
    await _isar!.writeTxn(() async {
      await _isar!.pendingFlashcardReviews.clear();
    });
  }

  Future<void> removePendingReviews(
    List<({int flashcardId, DateTime reviewedAt})> applied,
  ) async {
    if (applied.isEmpty) return;
    await init();
    await _isar!.writeTxn(() async {
      final rows = await _isar!.pendingFlashcardReviews.where().findAll();
      for (final row in rows) {
        final match = applied.any(
          (a) =>
              a.flashcardId == row.flashcardServerId &&
              a.reviewedAt.isAtSameMomentAs(row.reviewedAt),
        );
        if (match) {
          await _isar!.pendingFlashcardReviews.delete(row.id);
        }
      }
    });
  }

  Future<void> saveNoteTypes(List<NoteTypeModel> types) async {
    await init();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _noteTypesKey,
      jsonEncode(types.map((t) => t.toJson()).toList()),
    );
  }

  Future<List<NoteTypeModel>> loadNoteTypes() async {
    await init();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_noteTypesKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .whereType<Map>()
          .map((m) => NoteTypeModel.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
