import 'package:fluentdeck/ui_elements/app_toast.dart';
import 'package:flutter/foundation.dart';
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

  /// The less-used switches stay folded so the sheet stays short.
  bool _moreOptions = false;

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
      color: selected ? accent : AppPageColors.pageBgOf(context),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (locked) return _premiumNotice();
          if (!selected) _save(_prefs.copyWith(englishLevel: level));
        },
        child: SizedBox(
          height: 40,
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
    final tint = AppPageColors.tintOf(context, AppTint.teal);
    final name = SpeakingPreferences.voiceOptions[id]!.split(' — ').first;
    return Material(
      color: selected ? tint.bg : AppPageColors.cardBgOf(context),
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
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.graphic_eq_rounded, size: 16, color: tint.fg),
                const SizedBox(width: 6),
              ],
              if (locked) ...[
                Icon(Icons.lock_outline_rounded, size: 14, color: AppPageColors.subtitleOf(context)),
                const SizedBox(width: 4),
              ],
              Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? tint.fg : AppPageColors.textPrimaryOf(context),
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
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppPageColors.subtleBorderOf(context)
                      : const Color(0xFFD5E0E1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Conversation settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppPageColors.textPrimaryOf(context),
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
            const SizedBox(height: 16),
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
                      const SizedBox(height: 16),
                      _CheckGroup(
                        rows: [
                          _CheckRow(
                            title: 'Show corrections',
                            subtitle: '“Say it better” after your message',
                            listenable: RioPreferences.instance.showCorrections,
                            onChanged: RioPreferences.instance.setShowCorrections,
                          ),
                          if (_prefs.translationLanguage != 'none')
                            _CheckRow(
                              title: 'Translate into ${SpeakingPreferences.translationLanguageOptions[_prefs.translationLanguage] ?? 'your language'}',
                              subtitle: 'Tap any message to see it',
                              value: _prefs.showTranslations,
                              onChanged: (v) => _save(_prefs.copyWith(showTranslations: v)),
                            ),
                          _CheckRow(
                            title: 'Auto-play voice',
                            subtitle: 'Rio speaks each answer',
                            value: _prefs.soundOn && _prefs.autoPlayVoice,
                            onChanged: (v) => _save(_prefs.copyWith(soundOn: v, autoPlayVoice: v)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => setState(() => _moreOptions = !_moreOptions),
                          icon: Icon(_moreOptions ? Icons.expand_less_rounded : Icons.expand_more_rounded),
                          label: Text(_moreOptions ? 'Fewer options' : 'More options'),
                          style: TextButton.styleFrom(foregroundColor: AppPageColors.accentOf(context)),
                        ),
                      ),
                      if (_moreOptions)
                      _CheckGroup(
                        rows: [
                          _CheckRow(
                            title: 'Auto-start recording',
                            subtitle: 'Open the mic after Rio finishes speaking',
                            value: _prefs.autoStartRecording || _prefs.autoConversation,
                            // Hands-free was merged into this toggle; clear the legacy flag.
                            onChanged: (v) => _save(
                              _prefs.copyWith(autoStartRecording: v, autoConversation: false),
                            ),
                          ),
                          _CheckRow(
                            title: 'Type messages',
                            subtitle: 'A text field next to the mic',
                            value: _prefs.typeMessagesEnabled,
                            onChanged: (v) => _save(_prefs.copyWith(typeMessagesEnabled: v)),
                          ),
                          _CheckRow(
                            title: 'Show tutor',
                            subtitle: 'Rio the otter in the chat (this device)',
                            listenable: RioPreferences.instance.showRio,
                            onChanged: RioPreferences.instance.setShowRio,
                          ),
                          _CheckRow(
                            title: 'Video-call view',
                            subtitle: 'Rio big on screen, his latest reply over him',
                            listenable: RioPreferences.instance.showRioStage,
                            onChanged: RioPreferences.instance.setShowRioStage,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 56,
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppPageColors.accentOf(context),
                            foregroundColor: AppPageColors.onAccentOf(context),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                          child: const Text('Done', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                        ),
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

/// One rounded card of rows split by hairlines.
class _CheckGroup extends StatelessWidget {
  const _CheckGroup({required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPageColors.subtleBorderOf(context)),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) Divider(height: 1, thickness: 1, color: AppPageColors.rowDividerOf(context)),
              rows[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// Title, one-line detail and a teal checkbox on the right.
class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.title,
    required this.subtitle,
    required this.onChanged,
    this.value = false,
    this.listenable,
  });

  final String title;
  final String subtitle;
  final bool value;

  /// When set, the row follows this instead of [value].
  final ValueListenable<bool>? listenable;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = listenable;
    if (l != null) {
      return ValueListenableBuilder<bool>(
        valueListenable: l,
        builder: (context, v, _) => _row(context, v),
      );
    }
    return _row(context, value);
  }

  Widget _row(BuildContext context, bool checked) {
    return InkWell(
      onTap: () => onChanged(!checked),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppPageColors.textPrimaryOf(context),
                    ),
                  ),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: AppPageColors.subtitleOf(context))),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: checked,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: AppPageColors.accentOf(context),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
