import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/models/user_note_model.dart';
import 'package:fluentdeck/services/note_service.dart';

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

  static const _pageBg = Color(0xFFF7F5FB);

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
      backgroundColor: _pageBg,
      appBar: AppBar(
        title: const Text('Saved phrases'),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
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
                    style: TextStyle(color: Colors.grey.shade600, height: 1.45),
                  ),
                ),
              )
              : RefreshIndicator(
                onRefresh: _load,
                color: AppColors.primaryPurple,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: _phrases.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return _SavedPhraseCard(text: _phrases[index].word);
                  },
                ),
              ),
    );
  }
}

class _SavedPhraseCard extends StatelessWidget {
  const _SavedPhraseCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryPurple.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.format_quote_rounded,
            size: 18,
            color: AppColors.primaryPurple.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
