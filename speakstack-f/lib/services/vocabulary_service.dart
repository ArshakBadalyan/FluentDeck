import '../models/placement_test_model.dart';
import '../models/vocabulary_entry_model.dart';
import '../utils/strapi_response.dart';
import 'api_service.dart';
import 'english_level_service.dart';

class VocabularyService {
  VocabularyService._();
  static final VocabularyService instance = VocabularyService._();

  Future<VocabularyCatalogStats> fetchCatalogStats() async {
    final data = await ApiService.get('vocabulary/catalog/stats');
    if (data is! Map) {
      return const VocabularyCatalogStats(levelCounts: {});
    }
    return VocabularyCatalogStats.fromJson(Map<String, dynamic>.from(data));
  }

  Future<List<VocabularyEntryModel>> fetchCatalog({
    String? level,
    String? topic,
    String? frequencyBucket,
    int page = 1,
    int pageSize = 50,
  }) async {
    final params = <String>[
      'page=$page',
      'pageSize=$pageSize',
    ];
    if (level != null && level.isNotEmpty && level != 'All') {
      params.add('level=$level');
    }
    if (topic != null && topic.isNotEmpty) {
      params.add('topic=${Uri.encodeComponent(topic)}');
    }
    if (frequencyBucket != null && frequencyBucket.isNotEmpty) {
      params.add('frequencyBucket=${Uri.encodeComponent(frequencyBucket)}');
    }

    final data = await ApiService.get('vocabulary/catalog?${params.join('&')}');
    final rows = StrapiResponse.list(data);

    return rows
        .whereType<Map>()
        .map(
          (row) => VocabularyEntryModel.fromJson(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList();
  }

  Future<List<SavedWordModel>> fetchMyWords() async {
    final data = await ApiService.get('vocabulary/my-words');
    final rows = StrapiResponse.list(data);

    return rows
        .whereType<Map>()
        .map((row) => SavedWordModel.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<
    ({
      bool ok,
      String? message,
      bool flashcardCreated,
    })
  >
  saveWord(int vocabularyEntryId) async {
    final data = await ApiService.post('vocabulary/save', {
      'vocabularyEntryId': vocabularyEntryId,
    });

    if (data is Map && data['ok'] == true) {
      return (
        ok: true,
        message: null,
        flashcardCreated: data['flashcardCreated'] == true,
      );
    }

    final message = _extractErrorMessage(data);
    return (
      ok: false,
      message: message ?? 'Could not save word.',
      flashcardCreated: false,
    );
  }

  Future<({bool ok, String? message})> unsaveWord(int vocabularyEntryId) async {
    final data = await ApiService.post('vocabulary/unsave', {
      'vocabularyEntryId': vocabularyEntryId,
    });

    if (data is Map && data['ok'] == true) {
      return (ok: true, message: null);
    }

    final message = _extractErrorMessage(data);
    return (ok: false, message: message ?? 'Could not remove saved word.');
  }

  Future<List<PlacementQuestionModel>> fetchPlacementQuestions() async {
    final data = await ApiService.get('vocabulary/placement/questions');

    final message = _extractErrorMessage(data);
    if (message != null) {
      throw Exception(message);
    }

    if (data is! Map) {
      throw Exception('Unexpected placement questions response');
    }

    final rows = data['questions'] as List?;
    if (rows == null || rows.isEmpty) {
      throw Exception(
        'No placement questions available. Vocabulary catalog may be empty.',
      );
    }

    return rows
        .whereType<Map>()
        .map(
          (row) => PlacementQuestionModel.fromJson(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList();
  }

  Future<PlacementTestResultModel?> submitPlacement(
    List<Map<String, dynamic>> answers,
  ) async {
    final data = await ApiService.post('vocabulary/placement/submit', {
      'answers': answers,
    });

    if (data is! Map) return null;

    final message = _extractErrorMessage(data);
    if (message != null) {
      throw Exception(message);
    }

    final result = PlacementTestResultModel.fromJson(
      Map<String, dynamic>.from(data),
    );
    await EnglishLevelService.instance.applyLevelLocally(result.suggestedLevel);
    return result;
  }

  Future<PlacementTestResultModel?> fetchLatestPlacement() async {
    final data = await ApiService.get('vocabulary/placement/latest');
    if (data is! Map) return null;
    final result = data['result'];
    if (result == null) return null;
    if (result is! Map) return null;
    return PlacementTestResultModel.fromJson(
      Map<String, dynamic>.from(result),
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
