import 'package:flutter/material.dart';
import 'package:riovox/app_colors.dart';
import 'package:riovox/models/user_note_model.dart';
import 'package:riovox/services/note_service.dart';
import 'package:riovox/services/phrase_audio_service.dart';
import 'package:riovox/ui_elements/app_toast.dart';
import 'package:riovox/ui_elements/app_motion.dart';
import 'package:riovox/ui_elements/app_skeletons.dart';
import 'package:riovox/ui_elements/modern_page_widgets.dart';

class SpeakingSavedPhrasesScreen extends StatefulWidget {
  const SpeakingSavedPhrasesScreen({super.key});

  @override
  State<SpeakingSavedPhrasesScreen> createState() =>
      _SpeakingSavedPhrasesScreenState();
}

class _SpeakingSavedPhrasesScreenState extends State<SpeakingSavedPhrasesScreen> {
  bool _loading = true;
  String? _error;
  List<UserNoteModel> _phrases = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final notes = await NoteService.instance.fetchNotes();
      final speakingNotes =
          notes.where((n) => n.source == 'speaking').toList();
      if (!mounted) return;
      setState(() {
        _phrases = speakingNotes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPageColors.pageBgOf(context),
      appBar: AppBar(
        title: const Text('Saved phrases'),
        backgroundColor: AppPageColors.pageBgOf(context),
        foregroundColor: AppPageColors.textPrimaryOf(context),
        elevation: 0,
      ),
      body:
          _loading
              ? const AppListSkeleton()
              : _error != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                ),
              )
              : _phrases.isEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Save corrections from speaking conversations to build your phrase list.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppPageColors.subtitleOf(context), height: 1.45),
                  ),
                ),
              )
              : RefreshIndicator(
                onRefresh: _load,
                color: AppColors.brandPrimary,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  itemCount: _phrases.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return AppStaggeredFadeIn(
                      index: index,
                      child: _SavedPhraseCard(note: _phrases[index]),
                    );
                  },
                ),
              ),
    );
  }
}

class _SavedPhraseCard extends StatelessWidget {
  const _SavedPhraseCard({required this.note});

  final UserNoteModel note;

  @override
  Widget build(BuildContext context) {
    final subtitle = AppPageColors.subtitleOf(context);
    final meaning = note.translation.trim().isNotEmpty
        ? note.translation.trim()
        : note.definition.trim();
    final example = note.exampleSentence.trim();
    // Phrase, its meaning and an example, on a flat card.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPageColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPageColors.subtleBorderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  note.word,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, height: 1.3),
                ),
              ),
              // Listen button; off unless SAVED_PHRASES_LISTEN_ENABLED=true.
              if (PhraseAudioService.enabled && PhraseAudioService.hasVoice) _ListenButton(text: note.word),
            ],
          ),
          if (meaning.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(meaning, style: TextStyle(fontSize: 14, color: subtitle, height: 1.4)),
          ],
          if (example.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '“$example”',
              style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

class _ListenButton extends StatelessWidget {
  const _ListenButton({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final accent = AppPageColors.accentOf(context);
    return ValueListenableBuilder<String?>(
      valueListenable: PhraseAudioService.instance.playing,
      builder: (context, playing, _) {
        final active = playing == text.trim();
        return IconButton(
          tooltip: active ? 'Stop' : 'Listen',
          onPressed: () async {
            if (active) return PhraseAudioService.instance.stop();
            try {
              await PhraseAudioService.instance.play(text);
            } catch (_) {
              if (!context.mounted) return;
              AppToast.showSnackBar(
                context,
                const SnackBar(content: Text("Couldn't play this phrase. Try again.")),
              );
            }
          },
          style: IconButton.styleFrom(
            side: BorderSide(color: AppPageColors.subtleBorderOf(context)),
          ),
          icon: Icon(
            active ? Icons.stop_rounded : Icons.volume_up_rounded,
            color: accent,
          ),
        );
      },
    );
  }
}
