import '../models/user_note_model.dart';
import '../utils/strapi_response.dart';
import 'api_service.dart';
import 'auth_service.dart';

class NoteService {
  NoteService._();
  static final NoteService instance = NoteService._();

  Future<List<UserNoteModel>> fetchNotes({String? query}) async {
    final q = query != null && query.trim().isNotEmpty
        ? '?q=${Uri.encodeComponent(query.trim())}'
        : '';
    final data = await ApiService.get('notes$q');
    final rows = StrapiResponse.list(data);

    return rows
        .whereType<Map>()
        .map((row) => UserNoteModel.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<StudySettingsModel> fetchStudySettings() async {
    final data = await ApiService.get('notes/study-settings');
    if (data is! Map) {
      return const StudySettingsModel();
    }
    return StudySettingsModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<bool> updateAutoCreateFlashcards(bool enabled) async {
    final res = await AuthService.updateUser({
      'auto_create_flashcards': enabled,
    });
    return res['status'] == 'success';
  }

  Future<SaveNoteResult> createNote({
    required String word,
    String? definition,
    String? exampleSentence,
    List<String>? tags,
  }) async {
    final data = await ApiService.post('notes', {
      'word': word,
      'definition': definition,
      'exampleSentence': exampleSentence,
      'tags': tags ?? [],
      'source': 'manual',
    });

    return _parseSaveResult(data);
  }

  Future<SaveNoteResult> saveFromCorrection({
    required String correctedText,
    String? originalText,
    String? explanation,
    String? errorType,
  }) async {
    final data = await ApiService.post('notes/from-correction', {
      'correctedText': correctedText,
      'originalText': originalText,
      'explanation': explanation,
      'errorType': errorType,
    });

    return _parseSaveResult(data);
  }

  Future<bool> updateNote({
    required int id,
    String? word,
    String? definition,
    String? exampleSentence,
    List<String>? tags,
  }) async {
    final body = <String, dynamic>{};
    if (word != null) body['word'] = word;
    if (definition != null) body['definition'] = definition;
    if (exampleSentence != null) body['exampleSentence'] = exampleSentence;
    if (tags != null) body['tags'] = tags;

    final data = await ApiService.put('notes/$id', body);
    return data is Map && data['ok'] == true;
  }

  Future<bool> deleteNote(int id) async {
    final data = await ApiService.delete('notes/$id');
    return data is Map && data['ok'] == true;
  }

  SaveNoteResult _parseSaveResult(dynamic data) {
    if (data is Map && data['ok'] == true) {
      final noteJson = data['note'];
      return SaveNoteResult(
        ok: true,
        note:
            noteJson is Map
                ? UserNoteModel.fromJson(Map<String, dynamic>.from(noteJson))
                : null,
        flashcardCreated: data['flashcardCreated'] == true,
        autoCreateEnabled: data['autoCreateEnabled'] != false,
      );
    }

    return SaveNoteResult(
      ok: false,
      message: _extractErrorMessage(data) ?? 'Could not save note.',
    );
  }

  String? _extractErrorMessage(dynamic data) {
    if (data is! Map) return null;
    final error = data['error'];
    if (error is Map && error['message'] != null) {
      return error['message'].toString();
    }
    return null;
  }
}
