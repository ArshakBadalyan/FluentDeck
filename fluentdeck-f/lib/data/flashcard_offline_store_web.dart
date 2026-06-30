import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluentdeck/models/flashcard_model.dart';
import 'package:fluentdeck/models/flashcard_note_model.dart';

const _webCacheKey = 'flashcard_offline_cache_v1';
const _webPendingKey = 'flashcard_pending_reviews_v1';
const _webQueuePrefix = 'flashcard_review_queue_v1_';
const _webNoteTypesKey = 'flashcard_note_types_cache_v1';

String reviewQueueDeckKey(int? deckId) =>
    deckId == null ? 'all' : 'deck:$deckId';

class FlashcardOfflineStore {
  FlashcardOfflineStore._();
  static final FlashcardOfflineStore instance = FlashcardOfflineStore._();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
  }

  Future<void> saveSnapshot({
    required List<FlashcardDeckModel> decks,
    required List<FlashcardModel> cards,
  }) async {
    await init();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _webCacheKey,
      jsonEncode({
        'decks': decks.map((d) => d.toJson()).toList(),
        'cards': cards.map((c) => c.toJson()).toList(),
      }),
    );
  }

  Future<void> mergeSnapshot({
    required List<FlashcardDeckModel> decks,
    required List<FlashcardModel> cards,
  }) async {
    final existing = await loadSnapshot();
    final deckById = {for (final d in existing.decks) d.id: d};
    for (final d in decks) {
      deckById[d.id] = d;
    }
    final cardById = {for (final c in existing.cards) c.id: c};
    for (final c in cards) {
      cardById[c.id] = c;
    }
    await saveSnapshot(decks: deckById.values.toList(), cards: cardById.values.toList());
  }

  Future<({List<FlashcardDeckModel> decks, List<FlashcardModel> cards})>
  loadSnapshot() async {
    await init();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_webCacheKey);
    if (raw == null) {
      return (decks: <FlashcardDeckModel>[], cards: <FlashcardModel>[]);
    }
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final decks =
        (json['decks'] as List? ?? [])
            .whereType<Map>()
            .map(
              (m) => FlashcardDeckModel.fromJson(Map<String, dynamic>.from(m)),
            )
            .toList();
    final cards =
        (json['cards'] as List? ?? [])
            .whereType<Map>()
            .map((m) => FlashcardModel.fromJson(Map<String, dynamic>.from(m)))
            .toList();
    return (decks: decks, cards: cards);
  }

  Future<void> saveReviewQueue(
    List<FlashcardModel> queue, {
    int? deckId,
  }) async {
    await init();
    final prefs = await SharedPreferences.getInstance();
    final key = '$_webQueuePrefix${reviewQueueDeckKey(deckId)}';
    await prefs.setString(
      key,
      jsonEncode(queue.map((c) => c.toJson()).toList()),
    );

    final snapshot = await loadSnapshot();
    final byId = {for (final c in snapshot.cards) c.id: c};
    for (final card in queue) {
      byId[card.id] = card;
    }
    await saveSnapshot(decks: snapshot.decks, cards: byId.values.toList());
  }

  Future<List<FlashcardModel>> loadReviewQueue({int? deckId}) async {
    await init();
    final prefs = await SharedPreferences.getInstance();
    final key = '$_webQueuePrefix${reviewQueueDeckKey(deckId)}';
    final raw = prefs.getString(key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .whereType<Map>()
          .map((m) => FlashcardModel.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> updateCachedCard(FlashcardModel card) async {
    final snapshot = await loadSnapshot();
    final cards =
        snapshot.cards.map((c) => c.id == card.id ? card : c).toList();
    if (!cards.any((c) => c.id == card.id)) {
      cards.add(card);
    }
    await saveSnapshot(decks: snapshot.decks, cards: cards);
  }

  Future<void> queueReview({
    required int flashcardId,
    required String rating,
    required DateTime reviewedAt,
  }) async {
    await init();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_webPendingKey);
    final list =
        raw != null
            ? (jsonDecode(raw) as List).whereType<Map>().toList()
            : <Map>[];
    list.add({
      'flashcardId': flashcardId,
      'rating': rating,
      'reviewedAt': reviewedAt.toIso8601String(),
    });
    await prefs.setString(_webPendingKey, jsonEncode(list));
  }

  Future<List<({int flashcardId, String rating, DateTime reviewedAt})>>
  pendingReviews() async {
    await init();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_webPendingKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .whereType<Map>()
        .map(
          (m) => (
            flashcardId: m['flashcardId'] as int,
            rating: m['rating'] as String,
            reviewedAt: DateTime.parse(m['reviewedAt'] as String),
          ),
        )
        .toList();
  }

  Future<int> pendingReviewCount() async {
    final pending = await pendingReviews();
    return pending.length;
  }

  Future<void> clearPendingReviews() async {
    await init();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_webPendingKey);
  }

  Future<void> removePendingReviews(
    List<({int flashcardId, DateTime reviewedAt})> applied,
  ) async {
    if (applied.isEmpty) return;
    final pending = await pendingReviews();
    final remaining =
        pending
            .where(
              (p) =>
                  !applied.any(
                    (a) =>
                        a.flashcardId == p.flashcardId &&
                        a.reviewedAt.isAtSameMomentAs(p.reviewedAt),
                  ),
            )
            .toList();
    final prefs = await SharedPreferences.getInstance();
    if (remaining.isEmpty) {
      await prefs.remove(_webPendingKey);
      return;
    }
    await prefs.setString(
      _webPendingKey,
      jsonEncode(
        remaining
            .map(
              (p) => {
                'flashcardId': p.flashcardId,
                'rating': p.rating,
                'reviewedAt': p.reviewedAt.toIso8601String(),
              },
            )
            .toList(),
      ),
    );
  }

  Future<void> saveNoteTypes(List<NoteTypeModel> types) async {
    await init();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _webNoteTypesKey,
      jsonEncode(types.map((t) => t.toJson()).toList()),
    );
  }

  Future<List<NoteTypeModel>> loadNoteTypes() async {
    await init();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_webNoteTypesKey);
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
