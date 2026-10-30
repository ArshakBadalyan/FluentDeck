import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Stores last tag removal for undo (single note or bulk).
class CardTagUndoStore {
  CardTagUndoStore._();
  static final CardTagUndoStore instance = CardTagUndoStore._();

  static const _singleKey = 'card_tag_undo_v1';
  static const _bulkKey = 'card_tag_bulk_undo_v1';

  Future<void> save({
    required int noteId,
    required String removedTag,
    required List<String> previousTags,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _singleKey,
      jsonEncode({
        'noteId': noteId,
        'removedTag': removedTag,
        'previousTags': previousTags,
      }),
    );
    await prefs.remove(_bulkKey);
  }

  Future<({int noteId, String removedTag, List<String> previousTags})?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_singleKey);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return (
        noteId: json['noteId'] as int,
        removedTag: json['removedTag'] as String,
        previousTags:
            (json['previousTags'] as List? ?? [])
                .map((e) => e.toString())
                .toList(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveBulkRemove({
    required String removedTag,
    required Map<int, List<String>> previousTagsByNote,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _bulkKey,
      jsonEncode({
        'removedTag': removedTag,
        'notes': previousTagsByNote.map((k, v) => MapEntry('$k', v)),
      }),
    );
    await prefs.remove(_singleKey);
  }

  Future<({String removedTag, Map<int, List<String>> notes})?> loadBulk() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_bulkKey);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final notesRaw = json['notes'];
      final notes = <int, List<String>>{};
      if (notesRaw is Map) {
        for (final entry in notesRaw.entries) {
          final id = int.tryParse(entry.key.toString());
          if (id == null) continue;
          notes[id] =
              (entry.value as List? ?? [])
                  .map((e) => e.toString())
                  .toList();
        }
      }
      return (
        removedTag: json['removedTag']?.toString() ?? '',
        notes: notes,
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> hasBulkUndo() async => (await loadBulk()) != null;

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_singleKey);
    await prefs.remove(_bulkKey);
  }

  Future<void> clearBulk() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_bulkKey);
  }
}
