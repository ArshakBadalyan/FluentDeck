import 'package:riovox/ui_elements/app_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/speaking_preferences.dart';
import '../../services/conversation_service.dart';
import '../../services/rio_preferences.dart';
import '../../services/subscription_service.dart';
import '../../services/speaking_preferences_service.dart';
import '../../ui_elements/frosted_bottom_sheet.dart';
import '../../ui_elements/modern_page_widgets.dart';
import '../../models/tutor_persona.dart';

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

  /// Rio and the six people; picking a person also picks their voice. With
  /// Rio picked, his voice is chosen below.
  Widget _tutorGrid(BuildContext context) {
    return ValueListenableBuilder<TutorPersona>(
      valueListenable: RioPreferences.instance.tutor,
      builder: (context, tutor, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, c) {
              const gap = 8.0;
              final columns = c.maxWidth >= 520 ? 4 : 3;
              final width = (c.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final p in TutorPersona.all)
                    SizedBox(
                      width: width,
                      child: _TutorCard(
                        persona: p,
                        selected: tutor.id == p.id,
                        locked: !p.isRio &&
                            !_isPremium &&
                            !SpeakingPreferences.freeVoiceIds.contains(p.voice),
                        onTap: () => _pickTutor(p),
                      ),
                    ),
                ],
              );
            },
          ),
          // Indonesian and Armenian: the tutor has no voice yet (text only).
          if (!SpeakingPreferences.hasTutorVoice(_prefs.responseLanguage)) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppPageColors.fieldBgOf(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.volume_off_rounded, size: 18, color: AppPageColors.subtitleOf(context)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your tutor writes in ${SpeakingPreferences.responseLanguageOptions[_prefs.responseLanguage] ?? 'this language'} '
                      'but doesn\'t speak it yet. You can still talk; replies are text only.',
                      style: TextStyle(fontSize: 13, height: 1.35, color: AppPageColors.subtitleOf(context)),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (tutor.isRio) ...[
            const SizedBox(height: 14),
            _label(context, "Rio's voice"),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final id in SpeakingPreferences.voiceOptions.keys)
                  _voiceChip(context, id),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _pickTutor(TutorPersona p) {
    final voice = p.voice;
    if (voice != null && !_isPremium && !SpeakingPreferences.freeVoiceIds.contains(voice)) {
      _premiumNotice();
      return;
    }
    RioPreferences.instance.setTutor(p);
    if (voice != null && _prefs.tutorVoice != voice) {
      _save(_prefs.copyWith(tutorVoice: voice));
    }
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
                      _label(context, 'Your tutor'),
                      _tutorGrid(context),
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
                          if (SpeakingPreferences.hasTutorVoice(_prefs.responseLanguage))
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
                            subtitle: 'A video call with your tutor instead of the chat (this device)',
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

/// One tutor in the "Your tutor" grid: portrait, name, and what they're like.
class _TutorCard extends StatelessWidget {
  const _TutorCard({
    required this.persona,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final TutorPersona persona;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AppPageColors.accentOf(context);
    final voice = persona.voice;
    final voiceName = voice == null ? null : SpeakingPreferences.voiceOptions[voice]?.split(' — ').first;
    return Semantics(
      button: true,
      selected: selected,
      label: '${persona.name}, ${persona.blurb}${locked ? ', Premium' : ''}',
      excludeSemantics: true,
      child: Material(
        color: selected ? AppPageColors.tintOf(context, AppTint.teal).bg : AppPageColors.cardBgOf(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: selected ? accent : AppPageColors.subtleBorderOf(context), width: selected ? 2 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 10, 6, 10),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SizedBox(
                      height: 72,
                      child: Opacity(
                        opacity: locked ? 0.55 : 1,
                        child: Image.asset(persona.image, fit: BoxFit.contain, excludeFromSemantics: true),
                      ),
                    ),
                    if (locked)
                      Positioned(
                        right: -4,
                        bottom: 0,
                        child: Icon(Icons.lock_rounded, size: 16, color: AppPageColors.subtitleOf(context)),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  persona.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppPageColors.textPrimaryOf(context)),
                ),
                Text(
                  voiceName == null ? persona.blurb : '$voiceName · ${persona.blurb}',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, height: 1.25, color: AppPageColors.subtitleOf(context)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
