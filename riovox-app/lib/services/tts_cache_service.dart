import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class TtsCacheService {
  TtsCacheService._();
  static final TtsCacheService instance = TtsCacheService._();

  static const _maxFiles = 80;
  Directory? _cacheDir;

  Future<Directory> _dir() async {
    if (_cacheDir != null) return _cacheDir!;
    final base = await getApplicationSupportDirectory();
    _cacheDir = Directory('${base.path}/tts_cache');
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
    return _cacheDir!;
  }

  String _key(String text) {
    final trimmed = text.trim();
    final prefix = trimmed.length > 32 ? trimmed.substring(0, 32) : trimmed;
    final safe = prefix.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    return '${trimmed.length}_${trimmed.hashCode}_$safe';
  }

  Future<File> _fileFor(String text) async {
    final dir = await _dir();
    return File('${dir.path}/${_key(text)}.mp3');
  }

  Future<List<int>?> readBytes(String text) async {
    if (kIsWeb) return null;
    try {
      final file = await _fileFor(text);
      if (!await file.exists()) return null;
      await file.setLastModified(DateTime.now());
      return file.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  Future<void> writeBytes(String text, List<int> bytes) async {
    if (kIsWeb) return;
    try {
      final file = await _fileFor(text);
      await file.writeAsBytes(bytes, flush: true);
      await _pruneIfNeeded();
    } catch (_) {
      // ignore cache failures
    }
  }

  Future<void> _pruneIfNeeded() async {
    final dir = await _dir();
    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.mp3'))
            .toList()
          ..sort(
            (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
          );

    for (final file in files.skip(_maxFiles)) {
      try {
        await file.delete();
      } catch (_) {}
    }
  }
}
