import '../models/user_note_model.dart';
import '../utils/api_exception.dart';
import '../utils/strapi_response.dart';
import 'api_service.dart';
import 'auth_service.dart';

class NoteService {
  NoteService._();
  static final NoteService instance = NoteService._();

  Future<List<UserNoteModel>> fetchNotes({
    String? query,
    String? source,
    String? cefrLevel,
    String? topic,
    String? languageCode,
  }) async {
    final params = <String, String>{};
    if (query != null && query.trim().isNotEmpty) {
      params['q'] = query.trim();
    }
    if (source != null && source.isNotEmpty && source != 'all') {
      params['source'] = source;
    }
    if (cefrLevel != null && cefrLevel.isNotEmpty && cefrLevel != 'all') {
      params['cefrLevel'] = cefrLevel;
    }
    if (topic != null && topic.isNotEmpty && topic != 'all') {
      params['topic'] = topic;
    }
    if (languageCode != null && languageCode.isNotEmpty && languageCode != 'all') {
      params['languageCode'] = languageCode;
    }

    final q = params.isEmpty
        ? ''
        : '?${params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
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
    String? languageCode,
    String? cefrLevel,
    String? topic,
  }) async {
    final data = await ApiService.post('notes', {
      'word': word,
      'definition': definition,
      'exampleSentence': exampleSentence,
      'tags': tags ?? [],
      'source': 'manual',
      if (languageCode != null && languageCode.isNotEmpty)
        'languageCode': languageCode,
      if (cefrLevel != null && cefrLevel.isNotEmpty) 'cefrLevel': cefrLevel,
      if (topic != null && topic.isNotEmpty) 'topic': topic,
    });

    return _parseSaveResult(data);
  }

  Future<SaveNoteResult> saveFromCorrection({
    required String correctedText,
    String? originalText,
    String? explanation,
    String? errorType,
    String? exampleSentence,
    String? languageCode,
    String? cefrLevel,
    String? topic,
  }) async {
    final data = await ApiService.post('notes/from-correction', {
      'correctedText': correctedText,
      'originalText': originalText,
      'explanation': explanation,
      'errorType': errorType,
      if (exampleSentence != null && exampleSentence.trim().isNotEmpty)
        'exampleSentence': exampleSentence.trim(),
      if (languageCode != null && languageCode.isNotEmpty)
        'languageCode': languageCode,
      if (cefrLevel != null && cefrLevel.isNotEmpty) 'cefrLevel': cefrLevel,
      if (topic != null && topic.isNotEmpty) 'topic': topic,
    });

    return _parseSaveResult(data);
  }

  /// Saves a phrase the user highlighted in the speaking chat, with the
  /// meaning they typed or generated via AI (falls back to a placeholder
  /// if left blank).
  Future<SaveNoteResult> saveChatHighlight({
    required String selectedText,
    String? sourceSentence,
    String? meaning,
    String? exampleSentence,
    String? languageCode,
    String? cefrLevel,
    String? topic,
  }) async {
    return saveFromCorrection(
      correctedText: selectedText,
      originalText: sourceSentence,
      explanation:
          (meaning != null && meaning.trim().isNotEmpty)
              ? meaning.trim()
              : 'Saved from speaking chat',
      exampleSentence: exampleSentence,
      errorType: 'highlight',
      languageCode: languageCode,
      cefrLevel: cefrLevel,
      topic: topic,
    );
  }

  /// Generates a short definition + example for a word/expression via AI.
  /// Premium-only server-side — only call this when the button is shown
  /// (i.e. the caller already knows the user is premium).
  Future<WordMeaningResult> generateWordMeaning({
    required String word,
    String? context,
  }) async {
    try {
      final data = await ApiService.post('ai/word-meaning', {
        'word': word,
        if (context != null && context.isNotEmpty) 'context': context,
      });
      if (data is Map && data['definition'] != null) {
        return WordMeaningResult(
          ok: true,
          definition: data['definition'].toString(),
          example: data['example']?.toString() ?? '',
        );
      }
      return const WordMeaningResult(
        ok: false,
        message: 'Could not generate a meaning.',
      );
    } on ApiException catch (e) {
      return WordMeaningResult(
        ok: false,
        premiumRequired: e.statusCode == 402,
        message: e.message,
      );
    } catch (_) {
      return const WordMeaningResult(
        ok: false,
        message: 'Could not generate a meaning.',
      );
    }
  }

  Future<bool> updateNote({
    required int id,
    String? word,
    String? definition,
    String? exampleSentence,
    List<String>? tags,
    String? languageCode,
    String? cefrLevel,
    String? topic,
    bool clearCefrLevel = false,
    bool clearTopic = false,
  }) async {
    final body = <String, dynamic>{};
    if (word != null) body['word'] = word;
    if (definition != null) body['definition'] = definition;
    if (exampleSentence != null) body['exampleSentence'] = exampleSentence;
    if (tags != null) body['tags'] = tags;
    if (languageCode != null) body['languageCode'] = languageCode;
    if (clearCefrLevel) {
      body['cefrLevel'] = null;
    } else if (cefrLevel != null) {
      body['cefrLevel'] = cefrLevel.isEmpty ? null : cefrLevel;
    }
    if (clearTopic) {
      body['topic'] = null;
    } else if (topic != null) {
      body['topic'] = topic.isEmpty ? null : topic;
    }

    final data = await ApiService.put('notes/$id', body);
    return data is Map && data['ok'] == true;
  }

  Future<bool> deleteNote(int id) async {
    final data = await ApiService.delete('notes/$id');
    return data is Map && data['ok'] == true;
  }

  Future<ImportDecksResult> importFromDecks({required List<int> deckIds}) async {
    try {
      final data = await ApiService.post('notes/import-from-decks', {
        'deckIds': deckIds,
      });
      if (data is Map && data['ok'] == true) {
        return ImportDecksResult(
          ok: true,
          created: (data['created'] as num?)?.round() ?? 0,
          skipped: (data['skipped'] as num?)?.round() ?? 0,
          deckNames:
              (data['deckNames'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const [],
          linkedDecks: const [],
          limitReached: data['limitReached'] == true,
        );
      }
      return ImportDecksResult(
        ok: false,
        message: _extractErrorMessage(data) ?? 'Could not import decks.',
      );
    } on ApiException catch (e) {
      return ImportDecksResult(ok: false, message: e.message);
    } catch (_) {
      return const ImportDecksResult(
        ok: false,
        message: 'Could not import decks.',
      );
    }
  }

  /// Premium-only — detects CEFR level for a word/phrase via AI.
  Future<CefrLevelResult> detectCefrLevel({
    required String word,
    String? languageCode,
    String? definition,
    String? exampleSentence,
  }) async {
    try {
      final data = await ApiService.post('ai/cefr-level', {
        'word': word,
        if (languageCode != null && languageCode.isNotEmpty)
          'languageCode': languageCode,
        if (definition != null && definition.isNotEmpty) 'definition': definition,
        if (exampleSentence != null && exampleSentence.isNotEmpty)
          'exampleSentence': exampleSentence,
      });
      if (data is Map && data['cefrLevel'] != null) {
        return CefrLevelResult(
          ok: true,
          cefrLevel: data['cefrLevel'].toString(),
        );
      }
      return const CefrLevelResult(
        ok: false,
        message: 'Could not detect CEFR level.',
      );
    } on ApiException catch (e) {
      return CefrLevelResult(
        ok: false,
        premiumRequired: e.statusCode == 402,
        message: e.message,
      );
    } catch (_) {
      return const CefrLevelResult(
        ok: false,
        message: 'Could not detect CEFR level.',
      );
    }
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
