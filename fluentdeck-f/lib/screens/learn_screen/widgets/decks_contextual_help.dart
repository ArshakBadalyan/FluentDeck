import 'package:riovox/ui_elements/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:riovox/app_colors.dart';
import 'package:riovox/screens/learn_screen/decks_help_screen.dart';
import 'package:riovox/services/decks_help_hints_store.dart';
import 'package:riovox/widgets/professor.dart';
import 'package:riovox/widgets/rio.dart';
import 'package:riovox/ui_elements/modern_page_widgets.dart';
import 'package:riovox/ui_elements/app_circle_icon_button.dart';

/// Help icon that opens [DecksHelpScreen]; optionally shows a first-visit hint once.
class DecksContextualHelpButton extends StatelessWidget {
  const DecksContextualHelpButton({
    super.key,
    this.hintKey,
    this.hintMessage,
    this.helpSectionId,
    this.iconSize = 22,
    this.color,
  });

  final String? hintKey;
  final String? hintMessage;
  final String? helpSectionId;
  final double iconSize;
  final Color? color;

  static Future<void> maybeShowFirstVisitHint(
    BuildContext context, {
    required String hintKey,
    required String message,
    String? helpSectionId,
  }) async {
    if (!context.mounted) return;
    if (await DecksHelpHintsStore.instance.hasSeen(hintKey)) return;
    if (!context.mounted) return;

    await showAppDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Row(
              children: [
                RioImage.asset(ProfessorFace.winking.asset, height: 48, motion: RioMotion.pop),
                const SizedBox(width: 10),
                const Expanded(child: Text('Quick tip')),
              ],
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () async {
                  await DecksHelpHintsStore.instance.markSeen(hintKey);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Got it'),
              ),
              FilledButton(
                onPressed: () async {
                  await DecksHelpHintsStore.instance.markSeen(hintKey);
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  if (!context.mounted) return;
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DecksHelpScreen(initialSectionId: helpSectionId),
                    ),
                  );
                },
                style: FilledButton.styleFrom(backgroundColor: AppColors.brandPrimary),
                child: const Text('Open help'),
              ),
            ],
          ),
    );
  }

  /// First sign-in on this device: the "Getting started" tips once. Seeing
  /// them also counts for the per-screen tips, so no more pop-ups follow.
  static Future<void> maybeShowGettingStarted(BuildContext context) async {
    final store = DecksHelpHintsStore.instance;
    if (await store.hasSeen(DecksHelpHintsStore.gettingStartedKey)) return;
    if (!context.mounted) return;
    Future<void> markAll() async {
      await store.markSeen(DecksHelpHintsStore.gettingStartedKey);
      await store.markSeen(DecksHelpHintsStore.cardBrowserKey);
      await store.markSeen(DecksHelpHintsStore.statisticsKey);
    }

    final openHelp = await showAppDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _GettingStartedDialog(),
    );
    await markAll();
    if (openHelp == true && context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const DecksHelpScreen(initialSectionId: 'getting-started'),
        ),
      );
    }
  }

  void _openHelp(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DecksHelpScreen(initialSectionId: helpSectionId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Same round style as the other top-bar buttons.
    return AppCircleIconButton(
      tooltip: 'Help',
      icon: const Icon(Icons.help_outline_rounded),
      onPressed: () => _openHelp(context),
    );
  }
}

/// "Getting started" quick tips: a compact card with a teal header, short
/// sections that scroll, and the buttons always visible at the bottom.
/// Pops true for "Open help".
class _GettingStartedDialog extends StatefulWidget {
  const _GettingStartedDialog();

  @override
  State<_GettingStartedDialog> createState() => _GettingStartedDialogState();
}

class _GettingStartedDialogState extends State<_GettingStartedDialog> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = (MediaQuery.sizeOf(context).height * 0.7).clamp(320.0, 560.0);
    final accent = AppPageColors.accentOf(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: AppPageColors.cardBgOf(context),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 400, maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 18, 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: AppColors.heroGradient),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      ProfessorFace.happy.asset,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      excludeFromSemantics: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'QUICK TIPS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: Color(0xFFBFE4E7),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Getting started with Decks',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Body: scrolls when it doesn't fit.
            Flexible(
              child: Scrollbar(
                controller: _scroll,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _TipHeading('Two tabs'),
                      Row(
                        children: [
                          const Expanded(
                            child: _TabCard(
                              icon: Icons.filter_none_rounded,
                              title: 'Decks',
                              subtitle: 'Study home',
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: _TabCard(
                              icon: Icons.manage_search_rounded,
                              title: 'Card browser',
                              subtitle: 'Search and edit',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const _TipLine(
                        icon: Icons.bar_chart_rounded,
                        bold: 'Statistics',
                        rest: ' live under Progress → Decks.',
                      ),
                      const SizedBox(height: 14),
                      const _TipHeading('Start studying'),
                      const _TipLine(icon: Icons.touch_app_rounded, bold: 'Tap a deck name', rest: ' to open its overview.'),
                      const _TipLine(icon: Icons.play_circle_rounded, bold: 'Tap ▶ or a count', rest: ' to start studying.'),
                      const _TipLine(
                        icon: Icons.add_circle_rounded,
                        bold: 'Tap +',
                        rest: ' to add a note, create a deck, or build a filtered deck.',
                      ),
                      const SizedBox(height: 14),
                      const _TipHeading('Icons at the top'),
                      const _TipLine(icon: Icons.cloud_done_outlined, bold: 'Cloud', rest: ': synced, waiting to upload, or offline.'),
                      const _TipLine(icon: Icons.public_rounded, bold: 'Globe', rest: ': browse and import shared decks.'),
                      const _TipLine(icon: Icons.import_export_rounded, bold: 'Arrows', rest: ': import or export your collection.'),
                      const _TipLine(
                        icon: Icons.settings_outlined,
                        bold: 'Settings',
                        rest: ': General, Reviewing, Sync, Appearance, Backups and more.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Footer: always visible.
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 16, 14),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppPageColors.subtleBorderOf(context))),
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(foregroundColor: accent),
                    child: const Text('Open help'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      minimumSize: const Size(120, 44),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('Got it'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipHeading extends StatelessWidget {
  const _TipHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: AppPageColors.subtitleOf(context),
        ),
      ),
    );
  }
}

/// One tip: a tinted icon, then the key words in bold and the rest plain.
class _TipLine extends StatelessWidget {
  const _TipLine({required this.icon, required this.bold, required this.rest});

  final IconData icon;
  final String bold;
  final String rest;

  @override
  Widget build(BuildContext context) {
    final tint = AppPageColors.tintOf(context, AppTint.teal);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: tint.bg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: tint.fg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text.rich(
                TextSpan(
                  style: TextStyle(fontSize: 14, height: 1.4, color: AppPageColors.subtitleOf(context)),
                  children: [
                    TextSpan(
                      text: bold,
                      style: TextStyle(fontWeight: FontWeight.w700, color: AppPageColors.textPrimaryOf(context)),
                    ),
                    TextSpan(text: rest),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One of the two Decks tabs, as a small card.
class _TabCard extends StatelessWidget {
  const _TabCard({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final accent = AppPageColors.accentOf(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPageColors.fieldBgOf(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppPageColors.textPrimaryOf(context)),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: AppPageColors.subtitleOf(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
