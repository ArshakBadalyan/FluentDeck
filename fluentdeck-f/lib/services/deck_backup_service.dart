import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riovox/services/flashcard_service.dart';
import 'package:riovox/services/review_settings_store.dart';
import 'package:riovox/utils/file_download.dart';

/// Local JSON backups for flashcard collection (Phase 5B).
class DeckBackupService {
  DeckBackupService._();
  static final DeckBackupService instance = DeckBackupService._();

  static const _lastBackupKey = 'deck_last_backup_ms_v1';
  static const _maxLocalBackups = 3;

  Future<int?> getLastBackupMs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastBackupKey);
  }

  Future<void> _setLastBackupMs(int ms) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastBackupKey, ms);
  }

  String formatLastBackup(int? ms) {
    if (ms == null) return 'Never';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /// True when an automatic backup should run: never backed up, the interval
  /// has fully passed, or the last backup looks to be in the future (clock
  /// was moved back), which would otherwise block backups indefinitely.
  static bool isAutoBackupDue({
    required int? lastBackupMs,
    required int intervalDays,
    required DateTime now,
  }) {
    if (lastBackupMs == null) return true;
    final elapsed = now.difference(
      DateTime.fromMillisecondsSinceEpoch(lastBackupMs),
    );
    return elapsed.isNegative || elapsed >= Duration(days: intervalDays);
  }

  /// Runs a silent backup when auto-backup is on and due. Called on app start,
  /// on resume and when the setting changes. Returns true if a backup was
  /// made; never throws, since callers fire it and forget.
  Future<bool> runAutoBackupIfDue() async {
    try {
      final settings = await ReviewSettingsStore.instance.load();
      if (!settings.autoBackupEnabled) return false;
      final due = isAutoBackupDue(
        lastBackupMs: await getLastBackupMs(),
        intervalDays: settings.autoBackupIntervalDays,
        now: DateTime.now(),
      );
      if (!due) return false;
      await performBackup(silent: true);
      return true;
    } catch (e) {
      debugPrint('Auto backup failed: $e');
      return false;
    }
  }

  Future<void>? _inFlight;

  /// Backs up the collection. Joins a backup already in progress instead of
  /// running two at once. Throws if the collection could not be exported.
  Future<void> performBackup({bool silent = false}) {
    return _inFlight ??= _performBackup(
      silent: silent,
    ).whenComplete(() => _inFlight = null);
  }

  Future<void> _performBackup({required bool silent}) async {
    final data = await FlashcardService.instance.exportJson();
    if (data == null) {
      throw Exception(
        'Could not export your collection. Check your connection and try again.',
      );
    }

    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    final bytes = utf8.encode(jsonStr);
    final filename = 'flashcards_backup_${DateTime.now().millisecondsSinceEpoch}.json';

    if (kIsWeb) {
      if (!silent) {
        downloadBytesInBrowser(
          filename: filename,
          bytes: bytes,
          mimeType: 'application/json',
        );
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('deck_auto_backup_json_v1', jsonStr);
      }
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${dir.path}/flashcard_backups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      final file = File('${backupDir.path}/$filename');
      await file.writeAsBytes(bytes);
      await _pruneOldBackups(backupDir);
    }

    await _setLastBackupMs(DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _pruneOldBackups(Directory dir) async {
    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.json'))
            .toList()
          ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    for (final f in files.skip(_maxLocalBackups)) {
      try {
        await f.delete();
      } catch (_) {
        // ignore
      }
    }
  }
}
