import 'package:riovox/ui_elements/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:riovox/models/flashcard_model.dart';
import 'package:riovox/services/flashcard_import_service.dart';
import 'package:riovox/ui_elements/app_motion.dart';
import 'package:riovox/ui_elements/modern_page_widgets.dart';

/// Add a deck (Decks · Add a deck): start an empty deck, import an Anki or
/// text file, or find a shared deck on Riovox's shared-decks web page.
class SharedDecksScreen extends StatelessWidget {
  const SharedDecksScreen({
    super.key,
    this.decks = const [],
    this.onCreateEmptyDeck,
  });

  final List<FlashcardDeckModel> decks;

  /// Asks for a name and creates the deck; true when one was made. Null
  /// hides the "Empty deck" tile.
  final Future<bool> Function()? onCreateEmptyDeck;

  String? get _webUrl {
    final raw = dotenv.env['SHARED_DECKS_WEB_URL']?.trim();
    return (raw == null || raw.isEmpty) ? null : raw;
  }

  Future<void> _openWebPage(BuildContext context) async {
    final url = _webUrl;
    if (url == null) return;
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      AppToast.showSnackBar(context,
        const SnackBar(content: Text('Could not open the shared decks page.')),
      );
    }
  }

  Future<void> _openImportSheet(BuildContext context) async {
    await showFlashcardImportSheet(
      context,
      decks: decks,
      onImported: () {
        if (context.mounted) Navigator.pop(context, true);
      },
    );
  }

  Future<void> _createEmpty(BuildContext context) async {
    final created = await onCreateEmptyDeck!();
    if (created && context.mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final hasWebUrl = _webUrl != null;
    final accent = AppPageColors.accentOf(context);

    return Scaffold(
      backgroundColor: AppPageColors.pageBgOf(context),
      appBar: AppBar(
        backgroundColor: AppPageColors.pageBgOf(context),
        foregroundColor: AppPageColors.textPrimaryOf(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Add a deck', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (onCreateEmptyDeck != null) ...[
                  Expanded(
                    child: _AddTile(
                      icon: Icons.add_rounded,
                      title: 'Empty deck',
                      subtitle: 'Add your own cards',
                      onTap: () => _createEmpty(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: _AddTile(
                    icon: Icons.download_rounded,
                    title: 'Import other deck',
                    subtitle: '.apkg or text file',
                    onTap: () => _openImportSheet(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Shared decks',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppPageColors.textPrimaryOf(context)),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppPageColors.cardBgOf(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppPageColors.subtleBorderOf(context)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppPageColors.tintOf(context, AppTint.info).bg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.public_rounded, color: AppPageColors.tintIconOf(context, AppTint.info)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Community decks',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppPageColors.textPrimaryOf(context)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasWebUrl ? 'Find a deck on the web, then import it here' : 'Coming soon',
                        style: TextStyle(fontSize: 13, color: AppPageColors.subtitleOf(context)),
                      ),
                    ],
                  ),
                ),
                if (hasWebUrl)
                  TextButton(
                    onPressed: () => _openWebPage(context),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      backgroundColor: AppPageColors.tintOf(context, AppTint.teal).bg,
                      foregroundColor: accent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Browse'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// White tile: teal icon, bold title, one-line hint.
class _AddTile extends StatelessWidget {
  const _AddTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppPressScale(
      child: Material(
        color: AppPageColors.cardBgOf(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppPageColors.subtleBorderOf(context)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 24, color: AppPageColors.accentOf(context)),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppPageColors.textPrimaryOf(context)),
                ),
                const SizedBox(height: 8),
                Text(subtitle, style: TextStyle(fontSize: 12, color: AppPageColors.subtitleOf(context))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
