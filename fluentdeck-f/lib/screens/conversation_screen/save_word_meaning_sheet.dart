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
    this.languageCode,
    this.cefrLevel,
    this.topic,
  });

  final String phrase;
  /// Short dictionary-style definition (flashcard back).
  final String meaning;
  final String? example;
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
    builder:
        (ctx) => _SaveWordMeaningSheet(
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
  final _topicController = TextEditingController();
  bool _checkingPremium = true;
  bool _isPremium = false;
  bool _generating = false;
  bool _detectingLevel = false;
  String? _error;
  String _languageCode = 'en';
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
    });
  }

  @override
  void dispose() {
    _phraseController.dispose();
    _meaningController.dispose();
    _exampleController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _loadPremiumStatus() async {
    final status = await SubscriptionService.instance.fetchStatus(forceRefresh: true);
    if (!mounted) return;
    setState(() {
      _isPremium = status.isPremium;
      _checkingPremium = false;
    });
  }

  Future<void> _generateWithAi() async {
    setState(() {
      _generating = true;
      _error = null;
    });

    final result = await NoteService.instance.generateWordMeaning(
      word: widget.selectedText,
      context: widget.sourceSentence,
    );

    if (!mounted) return;
    setState(() => _generating = false);

    if (result.ok) {
      _meaningController.text = result.definition;
      _exampleController.text = result.example;
    } else {
      setState(() => _error = result.message ?? 'Could not generate a meaning.');
    }
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
        languageCode: _languageCode,
        cefrLevel: _cefrLevel,
        topic: _topicController.text.trim(),
      ),
    );
  }

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
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Save to deck',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Saved to your From speaking deck',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          Text(
            'Word or phrase',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _phraseController,
            maxLines: 2,
            minLines: 1,
            decoration: InputDecoration(
              hintText: 'e.g. break the ice',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Language',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          AppSelectField<String>(
            label: 'Word language',
            value: _languageCode,
            enabled: !_syncLearningLanguage,
            options:
                SpeakingPreferences.practiceLanguageOptions.entries
                    .map((e) => AppSelectOption(value: e.key, label: e.value))
                    .toList(),
            onChanged:
                _syncLearningLanguage
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
                    color: Colors.grey.shade700,
                  ),
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
          const SizedBox(height: 6),
          CefrLevelChips(
            selectedLevel: _cefrLevel,
            allowDeselect: true,
            onLevelSelected: (level) => setState(() => _cefrLevel = level),
          ),
          const SizedBox(height: 12),
          Text(
            'Topic (optional)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _topicController,
            decoration: InputDecoration(
              hintText: 'e.g. Travel, Business',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Definition',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              if (!_checkingPremium && _isPremium)
                TextButton.icon(
                  onPressed: _generating ? null : _generateWithAi,
                  icon:
                      _generating
                          ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: Text(_generating ? 'Generating…' : 'Generate with AI'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryPurple,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Short dictionary-style gloss for the flashcard back',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _meaningController,
            maxLines: 2,
            minLines: 1,
            decoration: InputDecoration(
              hintText: 'e.g. To start a friendly conversation',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Example sentence',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _exampleController,
            maxLines: 2,
            minLines: 1,
            decoration: InputDecoration(
              hintText: 'e.g. She told a joke to break the ice.',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(fontSize: 12, color: Colors.redAccent),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
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
