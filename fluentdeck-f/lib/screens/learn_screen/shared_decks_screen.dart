import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/models/flashcard_model.dart';
import 'package:fluentdeck/services/flashcard_import_service.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';

/// Entry point for finding decks from outside the app: FluentDeck's own
/// shared-decks web page, or importing a deck package file you already have.
class SharedDecksScreen extends StatelessWidget {
  const SharedDecksScreen({
    super.key,
    this.decks = const [],
  });

  final List<FlashcardDeckModel> decks;

  String? get _webUrl {
    final raw = dotenv.env['SHARED_DECKS_WEB_URL']?.trim();
    return (raw == null || raw.isEmpty) ? null : raw;
  }

  Future<void> _openWebPage(BuildContext context) async {
    final url = _webUrl;
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shared decks page is coming soon.'),
        ),
      );
      return;
    }
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
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

  @override
  Widget build(BuildContext context) {
    final hasWebUrl = _webUrl != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppPageColors.pageBgOf(context),
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Shared decks'),
      ),
      body: AppPageBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppSectionCard(
              title: 'Browse shared decks',
              icon: Icons.public_rounded,
              subtitle:
                  hasWebUrl
                      ? 'Find community decks on the FluentDeck website, then import the file here.'
                      : 'Coming soon — we\'re building a place to discover community decks.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPurple.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.travel_explore_rounded,
                            color: AppColors.primaryPurple,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            hasWebUrl
                                ? 'Opens fluentdeck.com in your browser'
                                : 'Check back soon for a browsable deck library',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _openWebPage(context),
                      icon: Icon(
                        hasWebUrl ? Icons.open_in_browser_rounded : Icons.hourglass_top_rounded,
                      ),
                      label: Text(hasWebUrl ? 'Open shared decks' : 'Coming soon'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppSectionCard(
              title: 'Have a deck file already?',
              icon: Icons.folder_open_rounded,
              subtitle: 'Import a deck package or spreadsheet from your device',
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openImportSheet(context),
                  icon: const Icon(Icons.file_upload_outlined),
                  label: const Text('Import a file'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryPurple,
                    side: const BorderSide(color: AppColors.primaryPurple),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
