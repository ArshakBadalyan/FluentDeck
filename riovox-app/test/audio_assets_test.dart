import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every sound key in AudioService must point at a file that ships, and Save
/// buttons use the new "save" chime (not the old formSubmit sound).
void main() {
  final source = File('lib/services/audio_service.dart').readAsStringSync();
  final entries = {
    for (final m in RegExp(r"'(\w+)':\s*'(audios/[^']+)'").allMatches(source))
      m.group(1)!: m.group(2)!,
  };

  test('every sound key points at an existing asset', () {
    expect(entries, isNotEmpty);
    entries.forEach((key, path) {
      expect(File('assets/$path').existsSync(), isTrue, reason: '$key → $path');
    });
  });

  test('every played sound key exists in the map', () {
    final played = <String>{};
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      for (final m in RegExp(r"AudioService\(\)\.play\('(\w+)'\)")
          .allMatches(file.readAsStringSync())) {
        played.add(m.group(1)!);
      }
    }
    expect(played, isNotEmpty);
    for (final key in played) {
      expect(entries.keys, contains(key), reason: 'play(\'$key\') has no sound');
    }
  });

  test('Save uses the new chime; the old formSubmit sound is gone', () {
    expect(entries['save'], 'audios/save.wav');
    expect(entries.containsKey('formSubmit'), isFalse);
    expect(File('assets/audios/formSubmit.wav').existsSync(), isFalse);
  });
}
