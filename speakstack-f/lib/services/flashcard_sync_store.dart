import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class FlashcardSyncLog {
  final DateTime? lastSuccessAt;
  final String? lastError;
  final int lastApplied;
  final int lastSkipped;
  final String? serverCursor;

  const FlashcardSyncLog({
    this.lastSuccessAt,
    this.lastError,
    this.lastApplied = 0,
    this.lastSkipped = 0,
    this.serverCursor,
  });

  String get lastSuccessLabel {
    if (lastSuccessAt == null) return 'Never synced';
    final local = lastSuccessAt!.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class FlashcardSyncStore {
  FlashcardSyncStore._();
  static final FlashcardSyncStore instance = FlashcardSyncStore._();

  static const _key = 'flashcard_sync_log_v1';

  Future<FlashcardSyncLog> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const FlashcardSyncLog();
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return FlashcardSyncLog(
        lastSuccessAt:
            json['lastSuccessAt'] != null
                ? DateTime.tryParse(json['lastSuccessAt'].toString())
                : null,
        lastError: json['lastError'] as String?,
        lastApplied: json['lastApplied'] as int? ?? 0,
        lastSkipped: json['lastSkipped'] as int? ?? 0,
        serverCursor: json['serverCursor'] as String?,
      );
    } catch (_) {
      return const FlashcardSyncLog();
    }
  }

  Future<void> save(FlashcardSyncLog log) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        if (log.lastSuccessAt != null)
          'lastSuccessAt': log.lastSuccessAt!.toIso8601String(),
        'lastError': log.lastError,
        'lastApplied': log.lastApplied,
        'lastSkipped': log.lastSkipped,
        'serverCursor': log.serverCursor,
      }),
    );
  }
}
