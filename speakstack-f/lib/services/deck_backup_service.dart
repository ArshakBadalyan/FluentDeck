import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speakstack/services/flashcard_service.dart';
import 'package:speakstack/services/review_settings_store.dart';
import 'package:speakstack/utils/file_download.dart';

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

  Future<void> runAutoBackupIfDue() async {
    final settings = await ReviewSettingsStore.instance.load();
    if (!settings.autoBackupEnabled) return;

    final last = await getLastBackupMs();
    if (last != null) {
      final elapsed = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(last));
      if (elapsed.inDays < settings.autoBackupIntervalDays) return;
    }

    await performBackup(silent: true);
  }

  Future<void> performBackup({bool silent = false}) async {
    final data = await FlashcardService.instance.exportJson();
    if (data == null) return;

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
