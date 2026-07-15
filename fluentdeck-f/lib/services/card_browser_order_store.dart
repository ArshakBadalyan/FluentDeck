import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:fluentdeck/models/flashcard_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists manual row order for the card browser per filter scope.
class CardBrowserOrderStore {
  CardBrowserOrderStore._();

  static final CardBrowserOrderStore instance = CardBrowserOrderStore._();

  static const _prefix = 'card_browser_order_v1:';

  Future<List<int>> load(String scopeKey) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$scopeKey');
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded.map((e) => int.tryParse(e.toString()) ?? -1).where((id) => id > 0).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> save(String scopeKey, List<int> cardIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$scopeKey', jsonEncode(cardIds));
  }

  /// Applies stored order when no column sort is active; unknown cards append at end.
  static List<FlashcardModel> applyOrder(
    List<FlashcardModel> cards,
    List<int> orderedIds,
  ) {
    if (orderedIds.isEmpty) return List<FlashcardModel>.from(cards);

    final byId = {for (final c in cards) c.id: c};
    final ordered = <FlashcardModel>[];
    final seen = <int>{};

    for (final id in orderedIds) {
      final card = byId[id];
      if (card == null) continue;
      ordered.add(card);
      seen.add(id);
    }

    for (final card in cards) {
      if (!seen.contains(card.id)) ordered.add(card);
    }

    return ordered;
  }

  @visibleForTesting
  static String scopeKey({
    int? deckId,
    required String stateFilter,
    String? languageCode,
    String search = '',
    String tag = '',
  }) {
    return [
      'deck:${deckId ?? 'all'}',
      'state:$stateFilter',
      'lang:${languageCode ?? 'all'}',
      'q:${search.trim()}',
      'tag:${tag.trim()}',
    ].join('|');
  }
}
