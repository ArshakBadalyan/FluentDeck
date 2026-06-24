import 'package:speakstack/services/api_service.dart';

class FlashcardCheckResult {
  final bool ok;
  final String summary;
  final List<String> details;

  const FlashcardCheckResult({
    required this.ok,
    required this.summary,
    this.details = const [],
  });
}

class FlashcardEmptyCardsResult {
  final bool ok;
  final int count;
  final int deleted;

  const FlashcardEmptyCardsResult({
    this.ok = true,
    this.count = 0,
    this.deleted = 0,
  });

  factory FlashcardEmptyCardsResult.fromJson(dynamic data) {
    if (data is! Map) return const FlashcardEmptyCardsResult();
    return FlashcardEmptyCardsResult(
      ok: data['ok'] == true,
      count: data['count'] as int? ?? 0,
      deleted: data['deleted'] as int? ?? 0,
    );
  }
}

/// Collection maintenance checks (AnkiDroid Check menu).
class FlashcardMaintenanceService {
  FlashcardMaintenanceService._();
  static final FlashcardMaintenanceService instance = FlashcardMaintenanceService._();

  String? _extractError(dynamic data) {
    if (data is! Map) return null;
    final error = data['error'];
    if (error is Map && error['message'] != null) {
      return error['message'].toString();
    }
    if (data['error'] != null) return data['error'].toString();
    return null;
  }

  Future<FlashcardCheckResult> checkAll() async {
    final data = await ApiService.post('flashcards/check', {});
    return _parseFullCheck(data);
  }

  Future<FlashcardCheckResult> checkDatabase() async {
    final data = await ApiService.post('flashcards/check/database', {});
    return _parseDatabaseCheck(data);
  }

  Future<FlashcardCheckResult> checkMedia() async {
    final data = await ApiService.post('flashcards/check/media', {});
    return _parseMediaCheck(data);
  }

  Future<FlashcardEmptyCardsResult> findEmptyCards() async {
    final data = await ApiService.get('flashcards/check/empty-cards');
    if (data is! Map) throw Exception('Empty cards check failed');
    final err = _extractError(data);
    if (err != null) throw Exception(err);
    return FlashcardEmptyCardsResult.fromJson(data);
  }

  Future<FlashcardEmptyCardsResult> deleteEmptyCards() async {
    final data = await ApiService.post('flashcards/check/empty-cards/delete', {});
    if (data is! Map) throw Exception('Delete empty cards failed');
    final err = _extractError(data);
    if (err != null) throw Exception(err);
    return FlashcardEmptyCardsResult(
      ok: data['ok'] == true,
      deleted: data['deleted'] as int? ?? 0,
    );
  }

  FlashcardCheckResult _parseFullCheck(dynamic data) {
    if (data is! Map) throw Exception('Check failed');
    final err = _extractError(data);
    if (err != null) throw Exception(err);

    final db = data['database'];
    final media = data['media'];
    final empty = data['emptyCards'];
    final details = <String>[];

    if (db is Map) {
      details.add(
        'Database: ${db['cards']} cards, ${db['notes']} notes, ${db['decks']} decks — '
        '${db['issueCount'] ?? 0} issue(s)',
      );
    }
    if (media is Map) {
      details.add(
        'Media: ${media['checked'] ?? 0} checked — ${media['missingCount'] ?? 0} missing',
      );
    }
    if (empty is Map) {
      details.add('Empty cards: ${empty['count'] ?? 0}');
    }

    return FlashcardCheckResult(
      ok: data['ok'] == true,
      summary: data['ok'] == true ? 'No problems found' : 'Issues found — see details',
      details: details,
    );
  }

  FlashcardCheckResult _parseDatabaseCheck(dynamic data) {
    if (data is! Map) throw Exception('Database check failed');
    final err = _extractError(data);
    if (err != null) throw Exception(err);

    final issueCount = data['issueCount'] as int? ?? 0;
    final issues = (data['issues'] as List? ?? []).whereType<Map>();
    final details =
        issues
            .map((i) => i['message']?.toString() ?? 'Issue')
            .take(20)
            .toList();

    return FlashcardCheckResult(
      ok: data['ok'] == true,
      summary:
          issueCount == 0
              ? 'Database OK (${data['cards']} cards, ${data['notes']} notes)'
              : '$issueCount database issue(s) found',
      details: details,
    );
  }

  FlashcardCheckResult _parseMediaCheck(dynamic data) {
    if (data is! Map) throw Exception('Media check failed');
    final err = _extractError(data);
    if (err != null) throw Exception(err);

    final missingCount = data['missingCount'] as int? ?? 0;
    final missing = (data['missing'] as List? ?? []).whereType<Map>();
    final details =
        missing
            .map((m) {
              final url = m['url']?.toString() ?? '';
              final reason = m['reason']?.toString() ?? 'missing';
              return '$reason: $url';
            })
            .take(20)
            .toList();

    return FlashcardCheckResult(
      ok: data['ok'] == true,
      summary:
          missingCount == 0
              ? 'All ${data['checked'] ?? 0} media reference(s) OK'
              : '$missingCount missing media file(s)',
      details: details,
    );
  }
}
