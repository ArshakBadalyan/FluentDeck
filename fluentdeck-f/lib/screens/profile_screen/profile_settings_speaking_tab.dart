import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/models/speaking_preferences.dart';
import 'package:fluentdeck/services/conversation_service.dart';
import 'package:fluentdeck/services/english_level_service.dart';
import 'package:fluentdeck/services/speaking_preferences_service.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';
import 'package:fluentdeck/widgets/cefr_level_chips.dart';

/// AI Speaking section for Profile → Settings (no outer scroll view).
class ProfileSettingsSpeakingSection extends StatefulWidget {
  const ProfileSettingsSpeakingSection({super.key});

  @override
  State<ProfileSettingsSpeakingSection> createState() =>
      _ProfileSettingsSpeakingSectionState();
}

class _ProfileSettingsSpeakingSectionState
    extends State<ProfileSettingsSpeakingSection> {
  bool _loading = true;
  bool _saving = false;
  SpeakingPreferences _speakingPrefs = const SpeakingPreferences();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final speakingPrefs = await SpeakingPreferencesService.instance.load(
        forceRefresh: true,
      );
      if (!mounted) return;
      setState(() {
        _speakingPrefs = speakingPrefs;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _saveSpeakingPreferences(SpeakingPreferences next) async {
    setState(() {
      _speakingPrefs = next;
      _saving = true;
    });

    final result = await SpeakingPreferencesService.instance.saveWithDetails(next);
    if (!mounted) return;

    setState(() => _saving = false);

    if (!result.ok) {
      final restored = await SpeakingPreferencesService.instance.load(
        forceRefresh: true,
      );
      if (!mounted) return;
      setState(() => _speakingPrefs = restored);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.errorMessage ?? 'Could not update speaking settings',
          ),
        ),
      );
      return;
    }

    await ConversationService.instance.refreshSpeakingSettings();
    if (next.englishLevel != null) {
      await EnglishLevelService.instance.applyLevelLocally(next.englishLevel!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Language',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _speakingPrefs.practiceLanguage,
          decoration: appDropdownDecoration('Language you are learning'),
          items:
              SpeakingPreferences.practiceLanguageOptions.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
          onChanged:
              _saving
                  ? null
                  : (value) {
                    if (value == null) return;
                    _saveSpeakingPreferences(
                      _speakingPrefs.copyWith(practiceLanguage: value),
                    );
                  },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _speakingPrefs.responseLanguage,
          decoration: appDropdownDecoration('Tutor response language'),
          items:
              SpeakingPreferences.responseLanguageOptions.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
          onChanged:
              _saving
                  ? null
                  : (value) {
                    if (value == null) return;
                    _saveSpeakingPreferences(
                      _speakingPrefs.copyWith(responseLanguage: value),
                    );
                  },
        ),
        const SizedBox(height: 16),
        Text(
          'Proficiency level',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        CefrLevelChips(
          selectedLevel: _speakingPrefs.englishLevel,
          enabled: !_saving,
          onLevelSelected: (level) {
            if (level == null) return;
            _saveSpeakingPreferences(
              _speakingPrefs.copyWith(englishLevel: level),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Chat',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        AppToggleRow(
          title: 'Auto-save corrected words',
          subtitle:
              'Automatically add vocabulary and spelling fixes to From speaking.',
          value: _speakingPrefs.autoSaveCorrections,
          enabled: !_saving,
          onChanged: (value) {
            _saveSpeakingPreferences(
              _speakingPrefs.copyWith(autoSaveCorrections: value),
            );
          },
        ),
        AppToggleRow(
          title: 'Sound on',
          subtitle: 'Play tutor voice responses automatically.',
          value: _speakingPrefs.soundOn,
          enabled: !_saving,
          onChanged: (value) {
            _saveSpeakingPreferences(_speakingPrefs.copyWith(soundOn: value));
          },
        ),
        AppToggleRow(
          title: 'Type messages',
          subtitle: 'Show a text field to type instead of only using the mic.',
          value: _speakingPrefs.typeMessagesEnabled,
          enabled: !_saving,
          onChanged: (value) {
            _saveSpeakingPreferences(
              _speakingPrefs.copyWith(typeMessagesEnabled: value),
            );
          },
        ),
        AppToggleRow(
          title: 'Auto-start recording',
          subtitle: 'Open the mic automatically after the tutor finishes speaking.',
          value: _speakingPrefs.autoStartRecording,
          enabled: !_saving,
          onChanged: (value) {
            _saveSpeakingPreferences(
              _speakingPrefs.copyWith(autoStartRecording: value),
            );
          },
        ),
        AppToggleRow(
          title: 'Show translations',
          subtitle: 'Display a helper translation under each tutor message.',
          value: _speakingPrefs.showTranslations,
          enabled: !_saving,
          onChanged: (value) {
            _saveSpeakingPreferences(
              _speakingPrefs.copyWith(showTranslations: value),
            );
          },
        ),
        AppToggleRow(
          title: 'Auto-play tutor voice',
          subtitle:
              'Play AI replies automatically. Turn off to use the Play button on each message.',
          value: _speakingPrefs.autoPlayVoice,
          enabled: !_saving,
          onChanged: (value) {
            _saveSpeakingPreferences(
              _speakingPrefs.copyWith(
                autoPlayVoice: value,
                autoConversation: value ? _speakingPrefs.autoConversation : false,
              ),
            );
          },
        ),
        AppToggleRow(
          title: 'Hands-free conversation',
          subtitle:
              'After the tutor speaks, reopen the mic automatically for continuous practice.',
          value: _speakingPrefs.autoConversation,
          enabled: !_saving,
          onChanged: (value) {
            _saveSpeakingPreferences(
              _speakingPrefs.copyWith(
                autoConversation: value,
                autoPlayVoice: value ? true : _speakingPrefs.autoPlayVoice,
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        AppSliderRow(
          title: 'Correct sentence goal',
          value: _speakingPrefs.correctSentenceGoal.toDouble(),
          min: 1,
          max: 50,
          divisions: 49,
          label: '${_speakingPrefs.correctSentenceGoal} sentences',
          enabled: !_saving,
          onChanged: (value) {
            _saveSpeakingPreferences(
              _speakingPrefs.copyWith(
                correctSentenceGoal: value.round(),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        _CorrectSentenceProgress(
          today: _speakingPrefs.correctSentencesToday,
          goal: _speakingPrefs.correctSentenceGoal,
        ),
        if (_speakingPrefs.showTranslations) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue:
                _speakingPrefs.translationLanguage == 'none'
                    ? 'en'
                    : _speakingPrefs.translationLanguage,
            decoration: appDropdownDecoration('Translation language'),
            items:
                SpeakingPreferences.translationLanguageOptions.entries
                    .where((entry) => entry.key != 'none')
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
            onChanged:
                _saving
                    ? null
                    : (value) {
                      if (value == null) return;
                      _saveSpeakingPreferences(
                        _speakingPrefs.copyWith(translationLanguage: value),
                      );
                    },
          ),
        ],
        if (_saving)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }
}

/// Shows progress toward today's "correct sentence goal" — resets daily.
class _CorrectSentenceProgress extends StatelessWidget {
  const _CorrectSentenceProgress({required this.today, required this.goal});

  final int today;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final safeGoal = goal <= 0 ? 1 : goal;
    final progress = (today / safeGoal).clamp(0.0, 1.0);
    final reached = today >= safeGoal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Today',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            Text(
              '$today / $goal correct sentences',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: reached ? AppColors.greenCorrect : Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            color: reached ? AppColors.greenCorrect : AppColors.primaryPurple,
          ),
        ),
      ],
    );
  }
}
