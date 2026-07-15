import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/models/speaking_preferences.dart';
import 'package:fluentdeck/services/conversation_service.dart';
import 'package:fluentdeck/services/english_level_service.dart';
import 'package:fluentdeck/services/speaking_preferences_service.dart';
import 'package:fluentdeck/services/subscription_service.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';
import 'package:fluentdeck/utils/speaking_premium_gate.dart';
import 'package:fluentdeck/widgets/cefr_level_chips.dart';

/// AI Speaking section for Profile → Settings (grouped sub-sections).
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
  bool _isPremium = false;
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
      final status = await SubscriptionService.instance.fetchStatus();
      if (!mounted) return;
      final level =
          speakingPrefs.englishLevel ?? EnglishLevelService.defaultLevel;
      final normalized = speakingPrefs.copyWith(englishLevel: level);
      if (!mounted) return;
      setState(() {
        _speakingPrefs = normalized;
        _isPremium = status.isPremium;
        _loading = false;
      });
      if (speakingPrefs.englishLevel == null) {
        await _saveSpeakingPreferences(normalized);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  bool _voiceLocked(String voiceId) =>
      !_isPremium && !SpeakingPreferences.freeVoiceIds.contains(voiceId);

  static const _premiumOnlyLevels = {'B2', 'C1', 'C2'};

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
        AppSettingsGroup(
          title: 'Your language',
          subtitle: 'What you are learning and how decks stay in sync.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const SizedBox(height: 4),
              AppToggleRow(
                title: 'Sync deck language',
                subtitle:
                    'Decks, notes, and filters use only your learning language '
                    '(${SpeakingPreferences.practiceLanguageOptions[_speakingPrefs.practiceLanguage] ?? _speakingPrefs.practiceLanguage}).',
                value: _speakingPrefs.syncLearningLanguage,
                enabled: !_saving,
                onChanged: (value) {
                  _saveSpeakingPreferences(
                    _speakingPrefs.copyWith(syncLearningLanguage: value),
                  );
                },
              ),
            ],
          ),
        ),
        AppSettingsGroup(
          title: 'Tutor',
          subtitle: 'How the AI tutor speaks and how hard it challenges you.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _speakingPrefs.tutorVoice,
                decoration: appDropdownDecoration('Tutor voice'),
                items:
                    SpeakingPreferences.voiceOptions.entries
                        .map(
                          (entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(entry.value),
                                if (_voiceLocked(entry.key)) ...[
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.lock_outline_rounded,
                                    size: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                        .toList(),
                onChanged:
                    _saving
                        ? null
                        : (value) {
                          if (value == null) return;
                          if (_voiceLocked(value)) {
                            showSpeakingPremiumSnackBar(context);
                            return;
                          }
                          _saveSpeakingPreferences(
                            _speakingPrefs.copyWith(tutorVoice: value),
                          );
                        },
              ),
              const SizedBox(height: 12),
              CefrLevelChips(
                selectedLevel: _speakingPrefs.englishLevel,
                enabled: !_saving,
                lockedLevels: _isPremium ? const {} : _premiumOnlyLevels,
                onLockedLevelTap: (_) => showSpeakingPremiumSnackBar(context),
                onLevelSelected: (level) {
                  if (level == null) return;
                  _saveSpeakingPreferences(
                    _speakingPrefs.copyWith(englishLevel: level),
                  );
                },
              ),
            ],
          ),
        ),
        AppSettingsGroup(
          title: 'Translation',
          subtitle: 'Tap the translate icon on any tutor message in chat.',
          child: DropdownButtonFormField<String>(
            initialValue: _speakingPrefs.translationLanguage,
            decoration: appDropdownDecoration('Translation language'),
            items:
                SpeakingPreferences.translationLanguageOptions.entries
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
        ),
        AppSettingsGroup(
          title: 'Chat behavior',
          subtitle: 'Mic, typing, and hands-free conversation options.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppToggleRow(
                title: 'Auto-save corrected words',
                subtitle: 'Add vocabulary fixes to From speaking automatically.',
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
                subtitle: 'Show a text field instead of mic-only input.',
                value: _speakingPrefs.typeMessagesEnabled,
                enabled: !_saving,
                onChanged: (value) {
                  _saveSpeakingPreferences(
                    _speakingPrefs.copyWith(typeMessagesEnabled: value),
                  );
                },
              ),
              AppToggleRow(
                title: 'Auto-play tutor voice',
                subtitle: 'Play replies automatically, or use Play on each message.',
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
                title: 'Auto-start recording',
                subtitle: 'Open the mic after the tutor finishes speaking.',
                value: _speakingPrefs.autoStartRecording,
                enabled: !_saving,
                onChanged: (value) {
                  _saveSpeakingPreferences(
                    _speakingPrefs.copyWith(autoStartRecording: value),
                  );
                },
              ),
              if (_speakingPrefs.autoStartRecording ||
                  _speakingPrefs.autoConversation)
                AppSliderRow(
                  title: 'Mic start delay',
                  value: _speakingPrefs.autoStartRecordingDelaySeconds.toDouble(),
                  min: 0,
                  max: 10,
                  divisions: 10,
                  label:
                      '${_speakingPrefs.autoStartRecordingDelaySeconds}s after tutor finishes',
                  enabled: !_saving,
                  onChanged: (value) {
                    _saveSpeakingPreferences(
                      _speakingPrefs.copyWith(
                        autoStartRecordingDelaySeconds: value.round(),
                      ),
                    );
                  },
                ),
              AppToggleRow(
                title: 'Hands-free conversation',
                subtitle: 'Auto-play voice and reopen mic after every reply.',
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
            ],
          ),
        ),
        AppSettingsGroup(
          title: 'Daily goal',
          subtitle: 'Track correct sentences toward your daily target.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                    _speakingPrefs.copyWith(correctSentenceGoal: value.round()),
                  );
                },
              ),
              const SizedBox(height: 8),
              _CorrectSentenceProgress(
                today: _speakingPrefs.correctSentencesToday,
                goal: _speakingPrefs.correctSentenceGoal,
              ),
            ],
          ),
        ),
        if (_saving)
          const Padding(
            padding: EdgeInsets.only(top: 4),
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
