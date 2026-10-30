import 'package:riovox/models/card_style_preset.dart';
import 'package:riovox/models/flashcard_note_model.dart';
import 'package:riovox/services/api_service.dart';
import 'package:riovox/services/auth_service.dart';

/// Per-account card style (theme) choices for built-in note types.
///
/// Stored on the user record server-side (not on-device) so it follows the
/// account across devices, reinstalls, and web — a device-local store (e.g.
/// SharedPreferences) would silently "reset" on every new install/browser
/// origin, which looked like data loss but was really just never having
/// been there for that device in the first place.
class NoteTypeStyleStore {
  NoteTypeStyleStore._();

  static final NoteTypeStyleStore instance = NoteTypeStyleStore._();

  Future<Map<String, String>> loadAll() async {
    try {
      final data = await ApiService.get('flashcards/note-type-styles');
      if (data is! Map) return <String, String>{};
      final styles = data['styles'];
      if (styles is! Map) return <String, String>{};
      return styles.map((k, v) => MapEntry(k.toString(), v.toString()));
    } catch (_) {
      return <String, String>{};
    }
  }

  Future<void> save(String noteTypeId, String themeId) async {
    final all = await loadAll();
    all[noteTypeId] = themeId;
    final res = await AuthService.updateUser({'note_type_styles': all});
    if (res['status'] != 'success') {
      throw Exception(res['message'] ?? 'Could not save card style');
    }
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
