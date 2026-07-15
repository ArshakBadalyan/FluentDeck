import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/models/speaking_preferences.dart';
import 'package:fluentdeck/models/user_note_model.dart';
import 'package:fluentdeck/services/note_service.dart';
import 'package:fluentdeck/services/speaking_preferences_service.dart';
import 'package:fluentdeck/ui_elements/primary_button.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';

class NoteEditScreen extends StatefulWidget {
  const NoteEditScreen({super.key, this.note});

  final UserNoteModel? note;

  bool get isEditing => note != null;

  @override
  State<NoteEditScreen> createState() => _NoteEditScreenState();
}

class _NoteEditScreenState extends State<NoteEditScreen> {
  late final TextEditingController _wordCtrl;
  late final TextEditingController _definitionCtrl;
  late final TextEditingController _exampleCtrl;
  late final TextEditingController _tagsCtrl;
  bool _saving = false;
  String _languageCode = 'en';
  bool _syncLearningLanguage = true;
  bool _loadingPrefs = true;

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    _wordCtrl = TextEditingController(text: note?.word ?? '');
    _definitionCtrl = TextEditingController(text: note?.definition ?? '');
    _exampleCtrl = TextEditingController(text: note?.exampleSentence ?? '');
    _tagsCtrl = TextEditingController(text: note?.tags.join(', ') ?? '');
    _languageCode = note?.languageCode ?? 'en';
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SpeakingPreferencesService.instance.load();
    if (!mounted) return;
    setState(() {
      _syncLearningLanguage = prefs.syncLearningLanguage;
      if (!widget.isEditing && prefs.syncLearningLanguage) {
        _languageCode = prefs.practiceLanguage;
      } else if (!widget.isEditing) {
        _languageCode = prefs.practiceLanguage;
      }
      _loadingPrefs = false;
    });
  }

  @override
  void dispose() {
    _wordCtrl.dispose();
    _definitionCtrl.dispose();
    _exampleCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  List<String> _parseTags() {
    return _tagsCtrl.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }

  Future<void> _save() async {
    final word = _wordCtrl.text.trim();
    if (word.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Word or phrase is required')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      if (widget.isEditing) {
        final ok = await NoteService.instance.updateNote(
          id: widget.note!.id,
          word: word,
          definition: _definitionCtrl.text.trim(),
          exampleSentence: _exampleCtrl.text.trim(),
          tags: _parseTags(),
          languageCode: _languageCode,
        );
        if (!mounted) return;
        if (ok) {
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not update note')),
          );
        }
      } else {
        final result = await NoteService.instance.createNote(
          word: word,
          definition: _definitionCtrl.text.trim(),
          exampleSentence: _exampleCtrl.text.trim(),
          tags: _parseTags(),
          languageCode: _languageCode,
        );
        if (!mounted) return;
        if (result.ok) {
          final msg =
              result.flashcardCreated
                  ? 'Note saved and flashcard added'
                  : 'Note saved';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message ?? 'Could not save note')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text(widget.isEditing ? 'Edit note' : 'New note'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _field('Word or phrase', _wordCtrl),
            const SizedBox(height: 16),
            _field('Definition', _definitionCtrl, maxLines: 3),
            const SizedBox(height: 16),
            _field('Example sentence', _exampleCtrl, maxLines: 2),
            const SizedBox(height: 16),
            if (!_loadingPrefs) ...[
              Text(
                'Language',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _languageCode,
                decoration: appDropdownDecoration('Word language'),
                items:
                    SpeakingPreferences.practiceLanguageOptions.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                onChanged:
                    _syncLearningLanguage && !widget.isEditing
                        ? null
                        : (value) {
                          if (value == null) return;
                          setState(() => _languageCode = value);
                        },
              ),
              if (_syncLearningLanguage && !widget.isEditing)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Synced to your learning language in Settings.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              const SizedBox(height: 16),
            ],
            _field('Tags (comma-separated)', _tagsCtrl),
            const SizedBox(height: 32),
            PrimaryButton(
              text: _saving ? 'SAVING…' : 'SAVE',
              enabled: !_saving,
              onPressed: _save,
              color: AppColors.primaryYellow,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF2F2F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
