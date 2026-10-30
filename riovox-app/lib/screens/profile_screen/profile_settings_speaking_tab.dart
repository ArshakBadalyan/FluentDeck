import 'dart:async';

import 'package:riovox/ui_elements/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:riovox/app_colors.dart';
import 'package:riovox/models/speaking_preferences.dart';
import 'package:riovox/services/conversation_service.dart';
import 'package:riovox/services/english_level_service.dart';
import 'package:riovox/services/speaking_preferences_service.dart';
import 'package:riovox/services/subscription_service.dart';
import 'package:riovox/ui_elements/app_skeletons.dart';
import 'package:riovox/ui_elements/modern_page_widgets.dart';
import 'package:riovox/utils/speaking_premium_gate.dart';
import 'package:riovox/widgets/cefr_level_chips.dart';
import 'package:riovox/models/tutor_persona.dart';
import 'package:riovox/services/rio_preferences.dart';

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
  bool _isPremium = false;
  SpeakingPreferences _speakingPrefs = const SpeakingPreferences();
  Timer? _goalSaveDebounce;
  int? _pendingGoal;

  @override
  void initState() {
    super.initState();
    SpeakingPreferencesService.instance.addListener(_onPrefsChanged);
    _load();
  }

  @override
  void dispose() {
    SpeakingPreferencesService.instance.removeListener(_onPrefsChanged);
    if (_goalSaveDebounce?.isActive ?? false) {
      _goalSaveDebounce!.cancel();
      final goal = _pendingGoal;
      final toSave = goal == null
          ? _speakingPrefs
          : SpeakingPreferencesService.instance.current.copyWith(
              correctSentenceGoal: goal,
            );
      SpeakingPreferencesService.instance.saveWithDetails(toSave);
    }
    super.dispose();
  }

  // Lets this screen pick up goal changes dragged in on Activity →
  // Speaking's gauge icon (and vice versa) while both are mounted.
  void _onPrefsChanged() {
    if (!mounted) return;
    setState(() => _speakingPrefs = SpeakingPreferencesService.instance.current);
  }

  /// Updates the goal locally right away so the slider stays responsive,
  /// then waits for the user to settle on a value before sending the PUT
  /// request — sending one per drag tick would otherwise fire a network
  /// call per pixel of drag.
  void _onGoalSliderChanged(double value) {
    final goal = value.round();
    // Base the update on the service's latest cached value, not this
    // screen's possibly-stale local copy — otherwise an older snapshot
    // here (e.g. `correctSentencesToday` logged by a session elsewhere)
    // can clobber a newer value when merged back into the shared cache.
    final next = SpeakingPreferencesService.instance.current.copyWith(
      correctSentenceGoal: goal,
    );
    setState(() => _speakingPrefs = next);
    SpeakingPreferencesService.instance.updateLocal(next);
    _pendingGoal = goal;
    _goalSaveDebounce?.cancel();
    // Re-read the cache (not `_speakingPrefs`) when the timer fires: if
    // something else updated the cache in the meantime (e.g. the other
    // screen's own reload racing this one), this still saves the goal the
    // user actually chose instead of silently losing it to that race.
    _goalSaveDebounce = Timer(const Duration(seconds: 2), () {
      _pendingGoal = null;
      _saveSpeakingPreferences(
        SpeakingPreferencesService.instance.current.copyWith(
          correctSentenceGoal: goal,
        ),
      );
    });
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
    setState(() => _speakingPrefs = next);

    final result = await SpeakingPreferencesService.instance.saveWithDetails(next);
    if (!mounted) return;

    if (!result.ok) {
      final restored = await SpeakingPreferencesService.instance.load(
        forceRefresh: true,
      );
      if (!mounted) return;
      setState(() => _speakingPrefs = restored);
      AppToast.showSnackBar(context, 
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
      // This section is always embedded inside the parent category
      // screen's ListView — use the shrink-wrapped skeleton, not
      // ProfileSettingsCardSkeleton (which owns its own ListView and
      // would be given unbounded height here).
      return const AppSectionCardSkeleton(rows: 4);
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
              AppSelectField<String>(
                label: 'Language you are learning',
                value: _speakingPrefs.practiceLanguage,
                enabled: true,
                options:
                    SpeakingPreferences.selectablePracticeLanguages(
                          current: _speakingPrefs.practiceLanguage,
                        ).entries
                        .map(
                          (entry) => AppSelectOption(
                            value: entry.key,
                            label: entry.value,
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  // The tutor follows the new learning language; it can
                  // still be changed separately under Tutor below.
                  final tutorLanguage =
                      SpeakingPreferences.responseLanguageOptions
                              .containsKey(value)
                          ? value
                          : _speakingPrefs.responseLanguage;
                  _saveSpeakingPreferences(
                    _speakingPrefs.copyWith(
                      practiceLanguage: value,
                      responseLanguage: tutorLanguage,
                    ),
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
                enabled: true,
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
              AppSelectField<String>(
                label: 'Tutor response language',
                value: _speakingPrefs.responseLanguage,
                enabled: true,
                options:
                    SpeakingPreferences.selectableResponseLanguages(
                          current: _speakingPrefs.responseLanguage,
                        ).entries
                        .map(
                          (entry) => AppSelectOption(
                            value: entry.key,
                            label: entry.value,
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  _saveSpeakingPreferences(
                    _speakingPrefs.copyWith(responseLanguage: value),
                  );
                },
              ),
              const SizedBox(height: 12),
              AppSelectField<String>(
                label: 'Tutor voice',
                value: _speakingPrefs.tutorVoice,
                enabled: true,
                options:
                    SpeakingPreferences.voiceOptions.entries
                        .map(
                          (entry) => AppSelectOption(
                            value: entry.key,
                            label: entry.value,
                            trailing:
                                _voiceLocked(entry.key)
                                    ? Icon(
                                        Icons.lock_outline_rounded,
                                        size: 16,
                                        color: AppPageColors.subtitleOf(context),
                                      )
                                    : null,
                          ),
                        )
                        .toList(),
                canSelect: (option) {
                  if (_voiceLocked(option.value)) {
                    showSpeakingPremiumSnackBar(context);
                    return false;
                  }
                  return true;
                },
                onChanged: (value) {
                  _saveSpeakingPreferences(
                    _speakingPrefs.copyWith(tutorVoice: value),
                  );
                  // A person tutor follows the voice (each has their own);
                  // Rio keeps whatever voice is chosen.
                  final rio = RioPreferences.instance;
                  if (!rio.tutor.value.isRio) {
                    rio.setTutor(TutorPersona.personForVoice(value) ?? TutorPersona.rio);
                  }
                },
              ),
              const SizedBox(height: 12),
              CefrLevelChips(
                selectedLevel: _speakingPrefs.englishLevel,
                enabled: true,
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
          child: AppSelectField<String>(
            label: 'Translation language',
            value: _speakingPrefs.translationLanguage,
            enabled: true,
            options:
                SpeakingPreferences.translationLanguageOptions.entries
                    .map(
                      (entry) => AppSelectOption(
                        value: entry.key,
                        label: entry.value,
                      ),
                    )
                    .toList(),
            onChanged: (value) {
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
                enabled: true,
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
                enabled: true,
                onChanged: (value) {
                  _saveSpeakingPreferences(_speakingPrefs.copyWith(soundOn: value));
                },
              ),
              AppToggleRow(
                title: 'Type messages',
                subtitle: 'Show a text field instead of mic-only input.',
                value: _speakingPrefs.typeMessagesEnabled,
                enabled: true,
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
                enabled: true,
                onChanged: (value) {
                  _saveSpeakingPreferences(
                    _speakingPrefs.copyWith(autoPlayVoice: value),
                  );
                },
              ),
              AppToggleRow(
                title: 'Auto-start recording',
                subtitle: 'Open the mic after the tutor finishes speaking.',
                value: _speakingPrefs.autoStartRecording ||
                    _speakingPrefs.autoConversation,
                enabled: true,
                onChanged: (value) {
                  // Hands-free was merged into this toggle; clear the legacy flag.
                  _saveSpeakingPreferences(
                    _speakingPrefs.copyWith(
                      autoStartRecording: value,
                      autoConversation: false,
                    ),
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
                  enabled: true,
                  onChanged: (value) {
                    _saveSpeakingPreferences(
                      _speakingPrefs.copyWith(
                        autoStartRecordingDelaySeconds: value.round(),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        AppSettingsGroup(
          borderRadius: 24,
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
                enabled: true,
                onChanged: _onGoalSliderChanged,
              ),
              const SizedBox(height: 8),
              _CorrectSentenceProgress(
                today: _speakingPrefs.correctSentencesToday,
                goal: _speakingPrefs.correctSentenceGoal,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shows today's progress toward the "correct sentence goal" as plain text
/// — resets daily. The visual ring for this lives on the Activity → Speaking
/// tab, around the streak icon, not duplicated here.
class _CorrectSentenceProgress extends StatelessWidget {
  const _CorrectSentenceProgress({required this.today, required this.goal});

  final int today;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final safeGoal = goal <= 0 ? 1 : goal;
    final reached = today >= safeGoal;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Today',
          style: TextStyle(fontSize: 12, color: AppPageColors.subtitleOf(context)),
        ),
        Text(
          '$today / $goal correct sentences',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: reached ? AppColors.greenCorrect : AppPageColors.subtitleOf(context),
          ),
        ),
      ],
    );
  }
}
