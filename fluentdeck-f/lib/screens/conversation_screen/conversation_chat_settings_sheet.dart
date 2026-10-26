import 'package:fluentdeck/ui_elements/app_toast.dart';
import 'package:flutter/material.dart';

import '../../models/speaking_preferences.dart';
import '../../services/conversation_service.dart';
import '../../services/rio_preferences.dart';
import '../../services/subscription_service.dart';
import '../../services/speaking_preferences_service.dart';
import '../../ui_elements/frosted_bottom_sheet.dart';
import '../../ui_elements/modern_page_widgets.dart';

/// Quick toggles for the active conversation (same prefs as Profile → Settings).
Future<void> showConversationChatSettingsSheet(BuildContext context) {
  return showFrostedBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => const _ConversationChatSettingsSheet(),
  );
}

class _ConversationChatSettingsSheet extends StatefulWidget {
  const _ConversationChatSettingsSheet();

  @override
  State<_ConversationChatSettingsSheet> createState() =>
      _ConversationChatSettingsSheetState();
}

class _ConversationChatSettingsSheetState
    extends State<_ConversationChatSettingsSheet> {
  SpeakingPreferences _prefs = const SpeakingPreferences();
  bool _loading = true;
  bool _saving = false;
  bool _isPremium = false;

  static const _levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
  static const _premiumOnlyLevels = {'B2', 'C1', 'C2'};

  @override
  void initState() {
    super.initState();
    _load();
    RioPreferences.instance.load();
  }

  Future<void> _load() async {
    final prefs = await SpeakingPreferencesService.instance.load(
      forceRefresh: true,
    );
    var premium = false;
    try {
      premium = (await SubscriptionService.instance.fetchStatus()).isPremium;
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _isPremium = premium;
      _loading = false;
    });
  }

  Future<void> _save(SpeakingPreferences next) async {
    setState(() {
      _prefs = next;
      _saving = true;
    });
    final result = await SpeakingPreferencesService.instance.saveWithDetails(
      next,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    if (!result.ok) {
      final restored = await SpeakingPreferencesService.instance.load(
        forceRefresh: true,
      );
      if (!mounted) return;
      setState(() => _prefs = restored);
      AppToast.showSnackBar(
        context,
        SnackBar(
          content: Text(result.errorMessage ?? 'Could not update settings'),
        ),
      );
      return;
    }

    await ConversationService.instance.refreshSpeakingSettings();
    if (mounted) setState(() {});
  }

  Widget _label(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppPageColors.textPrimaryOf(context),
      ),
    ),
  );

  void _premiumNotice() {
    AppToast.showSnackBar(
      context,
      const SnackBar(content: Text('This one is part of Premium.')),
    );
  }

  /// A1–C2 as one row of square buttons; the current level is solid teal.
  Widget _levelButton(BuildContext context, String level) {
    final selected = (_prefs.englishLevel ?? 'A1') == level;
    final locked = !_isPremium && _premiumOnlyLevels.contains(level);
    final accent = AppPageColors.accentOf(context);
    return Material(
      color: selected ? accent : AppPageColors.fieldBgOf(context),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (locked) return _premiumNotice();
          if (!selected) _save(_prefs.copyWith(englishLevel: level));
        },
        child: SizedBox(
          height: 44,
          child: Center(
            child: locked
                ? Icon(Icons.lock_outline_rounded, size: 16, color: AppPageColors.subtitleOf(context))
                : Text(
                    level,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: selected
                          ? AppPageColors.onAccentOf(context)
                          : AppPageColors.textPrimaryOf(context),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _voiceChip(BuildContext context, String id) {
    final selected = _prefs.tutorVoice == id;
    final locked = !_isPremium && !SpeakingPreferences.freeVoiceIds.contains(id);
    final accent = AppPageColors.accentOf(context);
    final name = SpeakingPreferences.voiceOptions[id]!.split(' — ').first;
    return Material(
      color: selected ? accent.withValues(alpha: 0.14) : AppPageColors.cardBgOf(context),
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? accent : AppPageColors.subtleBorderOf(context),
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () {
          if (locked) return _premiumNotice();
          if (!selected) _save(_prefs.copyWith(tutorVoice: id));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (locked) ...[
                Icon(Icons.lock_outline_rounded, size: 14, color: AppPageColors.subtitleOf(context)),
                const SizedBox(width: 4),
              ],
              Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? accent : AppPageColors.textPrimaryOf(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppPageColors.subtleBorderOf(context),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Conversation settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Rubik',
                    ),
                  ),
                ),
                if (_saving)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Applies to this conversation and saves to your account.',
              style: TextStyle(
                fontSize: 13,
                color: AppPageColors.subtitleOf(context),
              ),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _label(context, 'Your level'),
                      Row(
                        children: [
                          for (var i = 0; i < _levels.length; i++) ...[
                            if (i > 0) const SizedBox(width: 6),
                            Expanded(child: _levelButton(context, _levels[i])),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      _label(context, 'Tutor voice'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final id in SpeakingPreferences.voiceOptions.keys)
                            _voiceChip(context, id),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ValueListenableBuilder<bool>(
                        valueListenable: RioPreferences.instance.showRio,
                        builder: (context, show, _) => AppToggleRow(
                          title: 'Show tutor',
                          subtitle:
                              'Your tutor (Rio the otter) talks with you. Turn off for the plain chat (this device).',
                          value: show,
                          enabled: true,
                          onChanged: RioPreferences.instance.setShowRio,
                        ),
                      ),
                      AppToggleRow(
                        title: 'AI voice',
                        subtitle:
                            'Speak tutor replies out loud. Turn off to read only.',
                        value: _prefs.soundOn && _prefs.autoPlayVoice,
                        enabled: true,
                        onChanged: (value) {
                          _save(
                            _prefs.copyWith(
                              soundOn: value,
                              autoPlayVoice: value,
                            ),
                          );
                        },
                      ),
                      AppToggleRow(
                        title: 'Auto-start recording',
                        subtitle:
                            'Open the mic after the tutor finishes speaking.',
                        value:
                            _prefs.autoStartRecording ||
                            _prefs.autoConversation,
                        enabled: true,
                        onChanged: (value) {
                          // Hands-free was merged into this toggle; clear the legacy flag.
                          _save(
                            _prefs.copyWith(
                              autoStartRecording: value,
                              autoConversation: false,
                            ),
                          );
                        },
                      ),
                      AppToggleRow(
                        title: 'Type messages',
                        subtitle:
                            'Show a text field to type instead of only using the mic.',
                        value: _prefs.typeMessagesEnabled,
                        enabled: true,
                        onChanged: (value) {
                          _save(_prefs.copyWith(typeMessagesEnabled: value));
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
