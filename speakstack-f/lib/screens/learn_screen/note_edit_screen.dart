import 'package:flutter/material.dart';
import 'package:speakstack/app_colors.dart';
import 'package:speakstack/models/user_note_model.dart';
import 'package:speakstack/services/note_service.dart';
import 'package:speakstack/ui_elements/primary_button.dart';

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

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    _wordCtrl = TextEditingController(text: note?.word ?? '');
    _definitionCtrl = TextEditingController(text: note?.definition ?? '');
    _exampleCtrl = TextEditingController(text: note?.exampleSentence ?? '');
    _tagsCtrl = TextEditingController(text: note?.tags.join(', ') ?? '');
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
