import 'dart:convert';

import 'package:fluentdeck/models/card_style_preset.dart';
import 'package:fluentdeck/models/flashcard_note_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists card style (theme) choices for built-in note types per device.
class NoteTypeStyleStore {
  NoteTypeStyleStore._();

  static final NoteTypeStyleStore instance = NoteTypeStyleStore._();

  static const _key = 'builtin_note_type_styles_v1';

  Future<Map<String, String>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
    } catch (_) {
      return const {};
    }
  }

  Future<void> save(String noteTypeId, String themeId) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await loadAll();
    all[noteTypeId] = themeId;
    await prefs.setString(_key, jsonEncode(all));
  }

  static List<NoteTypeModel> applyStyles(
    List<NoteTypeModel> types,
    Map<String, String> styles,
  ) {
    if (styles.isEmpty) return types;

    return types.map((type) {
      if (type.isCustom) return type;
      final themeId = styles[type.id];
      if (themeId == null || themeId.isEmpty) return type;

      final preset = CardStylePreset.byId(themeId);
      return NoteTypeModel(
        id: type.id,
        name: type.name,
        fields: type.fields,
        cardTemplateNames: type.cardTemplateNames,
        cardTemplates: type.cardTemplates,
        css: preset.toCss(),
        themeId: preset.id,
        available: type.available,
        isCustom: false,
      );
    }).toList();
  }
}
