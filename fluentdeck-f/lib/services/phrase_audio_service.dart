import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'api_service.dart';
import 'tts_cache_service.dart';

/// Reads a saved phrase aloud outside a conversation (Saved phrases → Listen).
///
/// Off unless `SAVED_PHRASES_LISTEN_ENABLED=true` in the app config: each new
/// phrase is a server TTS call that counts toward the daily practice time.
/// Replays come from [TtsCacheService] and cost nothing.
class PhraseAudioService {
  PhraseAudioService._();
  static final PhraseAudioService instance = PhraseAudioService._();

  final AudioPlayer _player = AudioPlayer();

  /// The phrase currently loading or playing, for the button's state.
  final ValueNotifier<String?> playing = ValueNotifier<String?>(null);

  static bool get enabled =>
      dotenv.env['SAVED_PHRASES_LISTEN_ENABLED']?.trim().toLowerCase() == 'true';

  Future<void> play(String text) async {
    final phrase = text.trim();
    if (phrase.isEmpty) return;
    await _player.stop();
    playing.value = phrase;
    try {
      var bytes = await TtsCacheService.instance.readBytes(phrase);
      if (bytes == null || bytes.isEmpty) {
        final data = await ApiService.post('ai/tts', {'text': phrase});
        if (data is! Map || data['audioBase64'] is! String) {
          throw Exception('Unexpected TTS response');
        }
        bytes = base64Decode(data['audioBase64'] as String);
        await TtsCacheService.instance.writeBytes(phrase, bytes);
      }
      if (playing.value != phrase) return; // another phrase started meanwhile
      await _player.play(
        kIsWeb
            ? UrlSource('data:audio/mpeg;base64,${base64Encode(bytes)}')
            : BytesSource(Uint8List.fromList(bytes)),
      );
      await _player.onPlayerComplete.first;
    } finally {
      if (playing.value == phrase) playing.value = null;
    }
  }

  Future<void> stop() async {
    playing.value = null;
    await _player.stop();
  }
}
