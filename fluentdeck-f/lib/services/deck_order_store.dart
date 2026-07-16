import 'dart:convert';

import 'package:fluentdeck/models/flashcard_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists manual deck list order on the Decks home screen.
class DeckOrderStore {
  DeckOrderStore._();

  static final DeckOrderStore instance = DeckOrderStore._();

  static const _key = 'deck_list_order_v1';

  Future<List<int>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .map((e) => int.tryParse(e.toString()) ?? -1)
          .where((id) => id > 0)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> save(List<int> deckIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(deckIds));
  }

  static List<T> applyOrder<T>({
    required List<T> items,
    required List<int> orderedIds,
    required int Function(T item) idFor,
  }) {
    if (orderedIds.isEmpty) return List<T>.from(items);

    final byId = {for (final item in items) idFor(item): item};
    final ordered = <T>[];
    final seen = <int>{};

    for (final id in orderedIds) {
      final item = byId[id];
      if (item == null) continue;
      ordered.add(item);
      seen.add(id);
    }

    for (final item in items) {
      final id = idFor(item);
      if (!seen.contains(id)) ordered.add(item);
    }

    return ordered;
  }

  static List<FlashcardDeckModel> applyDeckOrder(
    List<FlashcardDeckModel> decks,
    List<int> orderedIds,
  ) {
    return applyOrder(
      items: decks,
      orderedIds: orderedIds,
      idFor: (d) => d.id,
    );
  }
}
