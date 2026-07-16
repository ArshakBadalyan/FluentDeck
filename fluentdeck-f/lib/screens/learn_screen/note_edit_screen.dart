import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/models/speaking_preferences.dart';
import 'package:fluentdeck/models/user_note_model.dart';
import 'package:fluentdeck/services/note_service.dart';
import 'package:fluentdeck/services/speaking_preferences_service.dart';
import 'package:fluentdeck/services/subscription_service.dart';
import 'package:fluentdeck/ui_elements/primary_button.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';
import 'package:fluentdeck/utils/speaking_premium_gate.dart';
import 'package:fluentdeck/widgets/cefr_level_chips.dart';
import 'package:fluentdeck/widgets/synced_learning_language_hint.dart';

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
  late final TextEditingController _topicCtrl;
  bool _saving = false;
  String _languageCode = 'en';
  String? _cefrLevel;
  bool _syncLearningLanguage = true;
  bool _loadingPrefs = true;
  bool _isPremium = false;
  bool _checkingPremium = true;
  bool _detectingLevel = false;

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    _wordCtrl = TextEditingController(text: note?.word ?? '');
    _definitionCtrl = TextEditingController(text: note?.definition ?? '');
    _exampleCtrl = TextEditingController(text: note?.exampleSentence ?? '');
    _tagsCtrl = TextEditingController(text: note?.tags.join(', ') ?? '');
    _topicCtrl = TextEditingController(text: note?.topic ?? '');
    _languageCode = note?.languageCode ?? 'en';
    _cefrLevel = note?.cefrLevel;
    _loadPrefs();
    _loadPremium();
  }

  Future<void> _loadPremium() async {
    final status = await SubscriptionService.instance.fetchStatus();
    if (!mounted) return;
    setState(() {
      _isPremium = status.isPremium;
      _checkingPremium = false;
    });
  }

  Future<void> _loadPrefs() async {
    final prefs = await SpeakingPreferencesService.instance.load();
    if (!mounted) return;
    setState(() {
      _syncLearningLanguage = prefs.syncLearningLanguage;
      if (!widget.isEditing) {
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
    _topicCtrl.dispose();
    super.dispose();
  }

  List<String> _parseTags() {
    return _tagsCtrl.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }

  Future<void> _detectCefrWithAi() async {
    if (!_isPremium) {
      showSpeakingPremiumSnackBar(context);
      return;
    }

    final word = _wordCtrl.text.trim();
    if (word.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a word or phrase first')),
      );
      return;
    }

    setState(() => _detectingLevel = true);
    try {
      final result = await NoteService.instance.detectCefrLevel(
        word: word,
        languageCode: _languageCode,
        definition: _definitionCtrl.text.trim(),
        exampleSentence: _exampleCtrl.text.trim(),
      );
      if (!mounted) return;
      if (result.premiumRequired) {
        showSpeakingPremiumSnackBar(context);
        return;
      }
      if (result.ok && result.cefrLevel != null) {
        setState(() => _cefrLevel = result.cefrLevel);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Suggested level: ${result.cefrLevel}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Could not detect level')),
        );
      }
    } finally {
      if (mounted) setState(() => _detectingLevel = false);
    }
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
          cefrLevel: _cefrLevel,
          clearCefrLevel: _cefrLevel == null,
          topic: _topicCtrl.text.trim(),
          clearTopic: _topicCtrl.text.trim().isEmpty,
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
          cefrLevel: _cefrLevel,
          topic: _topicCtrl.text.trim(),
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
      backgroundColor: AppPageColors.pageBgOf(context),
      appBar: AppBar(
        backgroundColor: AppPageColors.pageBgOf(context),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
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
              AppSelectField<String>(
                label: 'Word language',
                value: _languageCode,
                enabled: !(_syncLearningLanguage && !widget.isEditing),
                options:
                    SpeakingPreferences.practiceLanguageOptions.entries
                        .map(
                          (e) => AppSelectOption(value: e.key, label: e.value),
                        )
                        .toList(),
                onChanged:
                    _syncLearningLanguage && !widget.isEditing
                        ? null
                        : (value) => setState(() => _languageCode = value),
              ),
              if (_syncLearningLanguage && !widget.isEditing)
                const SyncedLearningLanguageHint(
                  includeSettingsSuffix: true,
                  padding: EdgeInsets.only(top: 6),
                ),
              const SizedBox(height: 16),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  child: Text(
                    'CEFR level (optional)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (!_checkingPremium)
                  TextButton.icon(
                    onPressed:
                        _detectingLevel
                            ? null
                            : (_isPremium
                                ? _detectCefrWithAi
                                : () => showSpeakingPremiumSnackBar(context)),
                    icon:
                        _detectingLevel
                            ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : Icon(
                              _isPremium
                                  ? Icons.auto_awesome_rounded
                                  : Icons.lock_outline_rounded,
                              size: 16,
                            ),
                    label: Text(
                      _detectingLevel
                          ? 'Analyzing…'
                          : (_isPremium ? 'Detect with AI' : 'Premium'),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryPurple,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            CefrLevelChips(
              selectedLevel: _cefrLevel,
              allowDeselect: true,
              onLevelSelected: (level) => setState(() => _cefrLevel = level),
            ),
            const SizedBox(height: 16),
            _field('Topic (optional)', _topicCtrl),
            const SizedBox(height: 16),
            _field('Tags (comma-separated)', _tagsCtrl),
            const SizedBox(height: 32),
            PrimaryButton(
              text: _saving ? 'SAVING…' : 'SAVE',
              enabled: !_saving,
              onPressed: _save,
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
            fillColor: AppPageColors.fieldBgOf(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppPageColors.subtleBorderOf(context), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppPageColors.subtleBorderOf(context), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryPurple, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
