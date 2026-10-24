import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioService {

  static final AudioService _instance = AudioService._internal();

  factory AudioService() => _instance;


  final AudioPlayer _player = AudioPlayer();


  bool _isSoundEnabled = true;

  bool _audioContextConfigured = false;


  final Map<String, String> _audioMap = {
    'lose': 'audios/lose.mp3',
    'skipped': 'audios/skipped.mp3',
    'notification': 'audios/notification.mp3',
    'achtung_short': 'audios/achtung_short.mp3',
    'correct': 'audios/correct.wav',
    'draw': 'audios/draw.wav',
    'win': 'audios/win.wav',
    'wrong': 'audios/wrong.wav',
    'tabChange': 'audios/nav_tap.wav',
    // Save buttons: soft G5→C6 chime, same family as signIn / settingsPreview.
    'save': 'audios/save.wav',
    'signIn': 'audios/sign_in.wav',
    'settingsPreview': 'audios/settings_preview.wav',
    'goalUpdate': 'audios/goalUpdate.mp3',
    'notificationOpen': 'audios/notification_chime.wav',
    'redirect': 'audios/redirect.mp3',
  };

  AudioService._internal();

  /// Binds playback to OS “silent mode” semantics: when the device is muted,
  /// short sounds do not play; when it is not, [updateSettings] volume applies.
  ///
  /// Call once before any [play]; [main] awaits this alongside other startup work.
  Future<void> ensureInitialized() async {
    if (_audioContextConfigured) return;
    _audioContextConfigured = true;
    try {
      await _player.setAudioContext(
        AudioContextConfig(respectSilence: true).build(),
      );
    } catch (_) {
      // Unavailable platform or plugin quirk — keep plugin defaults rather than failing startup.
    }
  }


  void updateSettings({required bool enabled, required double volumePercent}) {
    _isSoundEnabled = enabled;



    double vol = volumePercent / 100;
    _player.setVolume(vol);

  }

  void enableSound({required bool enabled}) {
    _isSoundEnabled = enabled;
  }


  Future<void> play(String name) async {

    if (!_isSoundEnabled) return;

    final path = _audioMap[name];
    if (path == null) {
      debugPrint("AudioService: sound '$name' is not registered");
      return;
    }

    try {

      await _player.stop();
      await _player.play(AssetSource(path));
    } catch (e) {
      // A newer sound stopping this one (web AbortError) is expected; skip it.
      if (!e.toString().contains('AbortError')) {
        debugPrint('AudioService: could not play $name: $e');
      }
    }
  }
}
