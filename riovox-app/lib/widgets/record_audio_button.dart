import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:riovox/ui_elements/modern_page_widgets.dart';

/// Mic button for card field toolbars: tap to record, tap again to stop.
/// Hands the clip's bytes and a filename to [onRecorded] (e.g. to upload it
/// as the card's audio).
class RecordAudioButton extends StatefulWidget {
  const RecordAudioButton({super.key, required this.onRecorded, this.onError});

  final Future<void> Function(List<int> bytes, String filename) onRecorded;
  final ValueChanged<String>? onError;

  @override
  State<RecordAudioButton> createState() => _RecordAudioButtonState();
}

class _RecordAudioButtonState extends State<RecordAudioButton> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _recording = false;
  bool _busy = false;
  String _filename = 'card-audio.m4a';

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_busy) return;
    if (_recording) {
      await _stop();
    } else {
      await _start();
    }
  }

  Future<void> _start() async {
    try {
      if (!await _recorder.hasPermission()) {
        widget.onError?.call('Allow microphone access to record.');
        return;
      }
      await _startRecorder();
      if (mounted) setState(() => _recording = true);
    } catch (e, st) {
      debugPrint('RecordAudioButton start failed: $e\n$st');
      widget.onError?.call('Could not start recording: $e');
    }
  }

  Future<void> _startRecorder() async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    RecordConfig config;
    String? path;
    if (kIsWeb) {
      final opus = await _recorder.isEncoderSupported(AudioEncoder.opus);
      _filename = opus ? 'card-audio-$stamp.webm' : 'card-audio-$stamp.wav';
      config = opus
          ? const RecordConfig(encoder: AudioEncoder.opus, numChannels: 1)
          : const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1);
    } else {
      _filename = 'card-audio-$stamp.m4a';
      config = const RecordConfig(encoder: AudioEncoder.aacLc);
      path = '${(await getTemporaryDirectory()).path}/$_filename';
    }
    await _recorder.start(config, path: path ?? '');
  }

  Future<void> _stop() async {
    setState(() {
      _recording = false;
      _busy = true;
    });
    try {
      final path = await _recorder.stop();
      if (path == null || path.isEmpty) {
        widget.onError?.call('Recording failed. Try again.');
        return;
      }
      final bytes = kIsWeb
          ? (await http.get(Uri.parse(path))).bodyBytes
          : await File(path).readAsBytes();
      if (bytes.isEmpty) {
        widget.onError?.call('Recording failed. Try again.');
        return;
      }
      await widget.onRecorded(bytes, _filename);
    } catch (e, st) {
      debugPrint('RecordAudioButton stop/upload failed: $e\n$st');
      widget.onError?.call('Could not save the recording: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final voice = AppPageColors.tintOf(context, AppTint.voice);
    if (_busy) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    // Material 2 ignores IconButton.style, so the recording tint is a box.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _recording ? voice.bg : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        icon: Icon(_recording ? Icons.stop_rounded : Icons.mic_rounded, size: 20),
        color: voice.fg,
        tooltip: _recording ? 'Stop recording' : 'Record audio',
        onPressed: _toggle,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
