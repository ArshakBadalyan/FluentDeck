import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_note_model.dart';

/// Decks the user linked to My notes via the + button (shown as source chips).
class MyNotesLinkedDecksStore {
  MyNotesLinkedDecksStore._();
  static final MyNotesLinkedDecksStore instance = MyNotesLinkedDecksStore._();

  static const _key = 'my_notes_linked_decks_v1';

  Future<List<LinkedMyNotesDeck>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      return list
          .whereType<Map>()
          .map((row) => LinkedMyNotesDeck.fromJson(Map<String, dynamic>.from(row)))
          .where((d) => d.id > 0 && d.name.isNotEmpty && !d.duplicatesSpeakingSource)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> save(List<LinkedMyNotesDeck> decks) async {
    final prefs = await SharedPreferences.getInstance();
    final unique = <int, LinkedMyNotesDeck>{};
    for (final deck in decks) {
      if (deck.id > 0 && deck.name.isNotEmpty && !deck.duplicatesSpeakingSource) {
        unique[deck.id] = deck;
      }
    }
    final sorted = unique.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    await prefs.setString(
      _key,
      jsonEncode(sorted.map((d) => d.toJson()).toList()),
    );
  }

  Future<List<LinkedMyNotesDeck>> merge(List<LinkedMyNotesDeck> incoming) async {
    final existing = await load();
    final byId = {for (final d in existing) d.id: d};
    for (final deck in incoming) {
      if (deck.id > 0 && deck.name.isNotEmpty && !deck.duplicatesSpeakingSource) {
        byId[deck.id] = deck;
      }
    }
    final merged = byId.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    await save(merged);
    return merged;
  }
}
