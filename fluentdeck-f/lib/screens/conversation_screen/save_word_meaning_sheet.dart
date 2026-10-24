import 'package:flutter/material.dart';

import '../../app_colors.dart';
import '../../models/speaking_preferences.dart';
import '../../services/note_service.dart';
import '../../services/speaking_preferences_service.dart';
import '../../services/subscription_service.dart';
import '../../ui_elements/frosted_bottom_sheet.dart';
import '../../ui_elements/modern_page_widgets.dart';
import '../../utils/speaking_premium_gate.dart';
import '../../widgets/cefr_level_chips.dart';
import '../../widgets/synced_learning_language_hint.dart';

/// Result of the save-word-meaning sheet: the phrase and meaning to save, or
/// null if the user cancelled.
class SaveWordMeaningResult {
  const SaveWordMeaningResult({
    required this.phrase,
    required this.meaning,
    this.example,
    this.translation,
    this.languageCode,
    this.cefrLevel,
    this.topic,
  });

  final String phrase;

  /// Short dictionary-style definition (flashcard back).
  final String meaning;
  final String? example;

  /// Phrase translated into the user's translation language.
  final String? translation;
  final String? languageCode;
  final String? cefrLevel;
  final String? topic;
}

/// Shown when the user taps "Save to deck" after selecting text in the
/// speaking chat. Lets them type their own meaning, or — if premium —
/// generate one with AI.
Future<SaveWordMeaningResult?> showSaveWordMeaningSheet({
  required BuildContext context,
  required String selectedText,
  required String sourceSentence,
}) {
  return showFrostedBottomSheet<SaveWordMeaningResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _SaveWordMeaningSheet(
      selectedText: selectedText,
      sourceSentence: sourceSentence,
    ),
  );
}

class _SaveWordMeaningSheet extends StatefulWidget {
  const _SaveWordMeaningSheet({
    required this.selectedText,
    required this.sourceSentence,
  });

  final String selectedText;
  final String sourceSentence;

  @override
  State<_SaveWordMeaningSheet> createState() => _SaveWordMeaningSheetState();
}

class _SaveWordMeaningSheetState extends State<_SaveWordMeaningSheet> {
  final _phraseController = TextEditingController();
  final _meaningController = TextEditingController();
  final _exampleController = TextEditingController();
  final _translationController = TextEditingController();
  final _topicController = TextEditingController();
  bool _checkingPremium = true;
  bool _isPremium = false;
  bool _translating = false;
  bool _generating = false;
  bool _detectingLevel = false;
  String? _error;
  String _languageCode = 'en';
  String _translationLanguage = 'none';
  bool _syncLearningLanguage = true;
  String? _cefrLevel;

  @override
  void initState() {
    super.initState();
    _phraseController.text = widget.selectedText;
    _loadPremiumStatus();
    _loadLanguagePrefs();
  }

  Future<void> _loadLanguagePrefs() async {
    final prefs = await SpeakingPreferencesService.instance.load();
    if (!mounted) return;
    setState(() {
      _syncLearningLanguage = prefs.syncLearningLanguage;
      _languageCode = prefs.practiceLanguage;
      _translationLanguage = prefs.translationLanguage;
    });
  }

  /// Translation field only makes sense when a different language is chosen.
  bool get _showTranslation =>
      _translationLanguage != 'none' && _translationLanguage != _languageCode;

  String _languageName(String code) =>
      SpeakingPreferences.translationLanguageOptions[code] ??
      SpeakingPreferences.practiceLanguageOptions[code] ??
      code;

  @override
  void dispose() {
    _phraseController.dispose();
    _meaningController.dispose();
    _exampleController.dispose();
    _translationController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _loadPremiumStatus() async {
    final status = await SubscriptionService.instance.fetchStatus(
      forceRefresh: true,
    );
    if (!mounted) return;
    setState(() {
      _isPremium = status.isPremium;
      _checkingPremium = false;
    });
  }

  Future<void> _generateWithAi() async {
    final word = _phraseController.text.trim();
    if (word.isEmpty) {
      setState(() => _error = 'Enter a word or phrase first.');
      return;
    }
    setState(() {
      _generating = true;
      _error = null;
    });

    final result = await NoteService.instance.generateWordMeaning(
      word: word,
      context: widget.sourceSentence,
      languageCode: _languageCode,
      translationLanguage: _showTranslation ? _translationLanguage : 'none',
    );

    if (!mounted) return;
    setState(() => _generating = false);

    if (result.ok) {
      _meaningController.text = result.definition;
      _exampleController.text = result.example;
      if (_showTranslation && result.translation.isNotEmpty) {
        _translationController.text = result.translation;
      }
    } else {
      setState(
        () => _error = result.message ?? 'Could not generate a meaning.',
      );
    }
  }

  /// Translates the phrase into the user's translation language.
  Future<void> _translateWithAi() async {
    if (!_isPremium) {
      showSpeakingPremiumSnackBar(context);
      return;
    }
    final word = _phraseController.text.trim();
    if (word.isEmpty) {
      setState(() => _error = 'Enter a word or phrase first.');
      return;
    }
    if (!_showTranslation) {
      setState(
        () => _error =
            'Choose a translation language (different from the word\'s) '
            'in Settings → AI Speaking to translate with AI.',
      );
      return;
    }
    setState(() {
      _translating = true;
      _error = null;
    });
    final translated = await NoteService.instance.translateText(
      text: word,
      targetLanguage: _translationLanguage,
    );
    if (!mounted) return;
    setState(() => _translating = false);
    if (translated == null) {
      setState(() => _error = 'Could not translate. Try again.');
      return;
    }
    _translationController.text = translated;
  }

  Future<void> _detectCefrWithAi() async {
    if (!_isPremium) {
      showSpeakingPremiumSnackBar(context);
      return;
    }

    final word = _phraseController.text.trim();
    if (word.isEmpty) {
      setState(() => _error = 'Enter a word or phrase first.');
      return;
    }

    setState(() {
      _detectingLevel = true;
      _error = null;
    });

    try {
      final result = await NoteService.instance.detectCefrLevel(
        word: word,
        languageCode: _languageCode,
        definition: _meaningController.text.trim(),
        exampleSentence: _exampleController.text.trim(),
      );
      if (!mounted) return;
      if (result.premiumRequired) {
        showSpeakingPremiumSnackBar(context);
        return;
      }
      if (result.ok && result.cefrLevel != null) {
        setState(() => _cefrLevel = result.cefrLevel);
      } else {
        setState(() => _error = result.message ?? 'Could not detect level.');
      }
    } finally {
      if (mounted) setState(() => _detectingLevel = false);
    }
  }

  void _save() {
    final phrase = _phraseController.text.trim();
    if (phrase.isEmpty) {
      setState(() => _error = 'Enter a word or phrase to save.');
      return;
    }
    Navigator.pop(
      context,
      SaveWordMeaningResult(
        phrase: phrase,
        meaning: _meaningController.text.trim(),
        example: _exampleController.text.trim(),
        translation: _translationController.text.trim().isEmpty
            ? null
            : _translationController.text.trim(),
        languageCode: _languageCode,
        cefrLevel: _cefrLevel,
        topic: _topicController.text.trim(),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppPageColors.subtitleOf(context),
    ),
  );

  Widget _fieldLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppPageColors.subtitleOf(context),
      ),
    ),
  );

  /// Compact 14sp input used for the meaning fields.
  Widget _field(TextEditingController controller, String hint) => TextField(
    controller: controller,
    maxLines: 3,
    minLines: 1,
    style: const TextStyle(fontSize: 14, height: 1.35),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 14,
        color: AppPageColors.subtitleOf(context),
      ),
      isDense: true,
      filled: true,
      fillColor: AppPageColors.fieldBgOf(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppPageColors.subtleBorderOf(context)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fields scroll; Save stays pinned so the sheet never overflows.
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppPageColors.subtleBorderOf(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    'Save to deck',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Saved to your From speaking deck',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppPageColors.subtitleOf(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Word or phrase',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppPageColors.subtitleOf(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _field(_phraseController, 'e.g. break the ice'),
                  const SizedBox(height: 16),
                  Text(
                    'Language',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppPageColors.subtitleOf(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  AppSelectField<String>(
                    label: 'Word language',
                    value: _languageCode,
                    enabled: !_syncLearningLanguage,
                    options: SpeakingPreferences.practiceLanguageOptions.entries
                        .map(
                          (e) => AppSelectOption(value: e.key, label: e.value),
                        )
                        .toList(),
                    onChanged: _syncLearningLanguage
                        ? null
                        : (value) => setState(() => _languageCode = value),
                  ),
                  if (_syncLearningLanguage)
                    const SyncedLearningLanguageHint(
                      padding: EdgeInsets.only(top: 4, bottom: 8),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'CEFR level (optional)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppPageColors.subtitleOf(context),
                          ),
                        ),
                      ),
                      if (!_checkingPremium)
                        TextButton.icon(
                          onPressed: _detectingLevel
                              ? null
                              : (_isPremium
                                    ? _detectCefrWithAi
                                    : () =>
                                          showSpeakingPremiumSnackBar(context)),
                          icon: _detectingLevel
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
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
                            foregroundColor: AppColors.brandPrimary,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  CefrLevelChips(
                    selectedLevel: _cefrLevel,
                    allowDeselect: true,
                    onLevelSelected: (level) =>
                        setState(() => _cefrLevel = level),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Topic (optional)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppPageColors.subtitleOf(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _field(_topicController, 'e.g. Travel, Business'),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: _label('Meaning')),
                      if (!_checkingPremium && _isPremium)
                        TextButton.icon(
                          onPressed: _generating ? null : _generateWithAi,
                          icon: _generating
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 16,
                                ),
                          label: Text(
                            _generating ? 'Generating…' : 'Generate with AI',
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.brandPrimary,
                            visualDensity: VisualDensity.compact,
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    _showTranslation
                        ? 'AI fills the translation, definition and example.'
                        : 'AI fills the definition and example for the flashcard back.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppPageColors.subtitleOf(context),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _fieldLabel('Definition (${_languageName(_languageCode)})'),
                  _field(_meaningController, 'Short dictionary-style gloss'),
                  const SizedBox(height: 10),
                  _fieldLabel(
                    'Example sentence (${_languageName(_languageCode)})',
                  ),
                  _field(
                    _exampleController,
                    'A short sentence using the phrase',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _label(
                          _showTranslation
                              ? 'Translation (${_languageName(_translationLanguage)})'
                              : 'Translation',
                        ),
                      ),
                      if (!_checkingPremium)
                        TextButton.icon(
                          onPressed: _translating ? null : _translateWithAi,
                          icon: _translating
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.translate_rounded, size: 16),
                          label: Text(
                            _translating
                                ? 'Translating…'
                                : (_isPremium
                                      ? 'Translate with AI'
                                      : 'Translate · Premium'),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.brandPrimary,
                            visualDensity: VisualDensity.compact,
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  _field(
                    _translationController,
                    'Translation of the word or phrase',
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
