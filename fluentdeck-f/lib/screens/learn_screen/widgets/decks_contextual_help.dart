import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/screens/learn_screen/decks_help_screen.dart';
import 'package:fluentdeck/services/decks_help_hints_store.dart';

/// Help icon that opens [DecksHelpScreen]; optionally shows a first-visit hint once.
class DecksContextualHelpButton extends StatelessWidget {
  const DecksContextualHelpButton({
    super.key,
    this.hintKey,
    this.hintMessage,
    this.helpSectionId,
    this.iconSize = 22,
  });

  final String? hintKey;
  final String? hintMessage;
  final String? helpSectionId;
  final double iconSize;

  static Future<void> maybeShowFirstVisitHint(
    BuildContext context, {
    required String hintKey,
    required String message,
    String? helpSectionId,
  }) async {
    if (!context.mounted) return;
    if (await DecksHelpHintsStore.instance.hasSeen(hintKey)) return;
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.help_outline, color: AppColors.primaryPurple),
                const SizedBox(width: 8),
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
                style: FilledButton.styleFrom(backgroundColor: AppColors.primaryPurple),
                child: const Text('Open help'),
              ),
            ],
          ),
    );
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
    return IconButton(
      tooltip: 'Help',
      icon: Icon(Icons.help_outline, size: iconSize),
      onPressed: () => _openHelp(context),
    );
  }
}
