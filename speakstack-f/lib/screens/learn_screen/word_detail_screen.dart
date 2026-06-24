import 'package:flutter/material.dart';
import 'package:speakstack/app_colors.dart';
import 'package:speakstack/models/vocabulary_entry_model.dart';
import 'package:speakstack/services/vocabulary_service.dart';
import 'package:speakstack/ui_elements/primary_button.dart';

class WordDetailScreen extends StatefulWidget {
  const WordDetailScreen({
    super.key,
    required this.entry,
    this.onSaved,
  });

  final VocabularyEntryModel entry;
  final VoidCallback? onSaved;

  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen> {
  bool _saving = false;
  late bool _isSaved = widget.entry.isSaved;

  Future<void> _toggleSave() async {
    if (_saving || widget.entry.previewLimited) return;

    setState(() => _saving = true);
    try {
      if (_isSaved) {
        final result = await VocabularyService.instance.unsaveWord(widget.entry.id);
        if (!mounted) return;

        if (result.ok) {
          setState(() => _isSaved = false);
          widget.onSaved?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from saved words')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message ?? 'Could not unsave word')),
          );
        }
      } else {
        final result = await VocabularyService.instance.saveWord(widget.entry.id);
        if (!mounted) return;

        if (result.ok) {
          setState(() => _isSaved = true);
          widget.onSaved?.call();
          final msg =
              result.flashcardCreated
                  ? 'Word saved — note and flashcard added'
                  : 'Word saved to your notes';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message ?? 'Could not save word')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text(entry.word),
        actions: [
          if (!entry.previewLimited)
            IconButton(
              tooltip: _isSaved ? 'Remove from saved' : 'Save word',
              icon: Icon(
                _isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: _isSaved ? AppColors.primaryPurple : Colors.grey,
              ),
              onPressed: _saving ? null : _toggleSave,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (entry.cefrLevel != null && entry.cefrLevel!.isNotEmpty)
                  _chip(entry.cefrLevel!, AppColors.primaryPurple),
                if (entry.cefrLevel != null && entry.cefrLevel!.isNotEmpty)
                  const SizedBox(width: 8),
                if (entry.partOfSpeech.isNotEmpty)
                  _chip(entry.partOfSpeech, Colors.blueGrey),
                if (entry.partOfSpeech.isNotEmpty) const SizedBox(width: 8),
                if (entry.topic.isNotEmpty) _chip(entry.topic, Colors.grey.shade700),
                if (entry.topic.isNotEmpty) const SizedBox(width: 8),
                _chip(entry.entryType, Colors.grey.shade600),
              ],
            ),
            const SizedBox(height: 24),
            if (entry.previewLimited) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'This word is in preview mode on the free plan. Upgrade to premium for full definitions and unlimited saves.',
                ),
              ),
            ] else ...[
              const Text(
                'Definition',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                entry.definition ?? '',
                style: const TextStyle(fontSize: 16, height: 1.4),
              ),
              if (entry.exampleSentence != null &&
                  entry.exampleSentence!.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Example',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  entry.exampleSentence!,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.4,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 32),
            if (!entry.previewLimited)
              PrimaryButton(
                text: _isSaved ? 'REMOVE FROM SAVED' : 'SAVE WORD',
                enabled: !_saving,
                onPressed: _toggleSave,
                color: _isSaved ? Colors.grey.shade600 : AppColors.primaryYellow,
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
