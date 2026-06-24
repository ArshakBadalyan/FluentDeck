import 'package:flutter/material.dart';
import 'package:speakstack/app_colors.dart';
import 'package:speakstack/models/flashcard_model.dart';
import 'package:speakstack/screens/learn_screen/card_browser_screen.dart';
import 'package:speakstack/screens/learn_screen/card_edit_screen.dart';
import 'package:speakstack/screens/learn_screen/deck_detail_screen.dart';
import 'package:speakstack/screens/learn_screen/review_session_screen.dart';
import 'package:speakstack/screens/learn_screen/widgets/deck_count_buttons.dart';
import 'package:speakstack/screens/learn_screen/widgets/deck_edit_sheet.dart';

/// Deck overview — opened by tapping deck name or count buttons (AnkiDroid pattern).
class DeckOverviewScreen extends StatefulWidget {
  const DeckOverviewScreen({
    super.key,
    required this.deck,
    this.allDecks = const [],
  });

  final FlashcardDeckModel deck;
  final List<FlashcardDeckModel> allDecks;

  @override
  State<DeckOverviewScreen> createState() => _DeckOverviewScreenState();
}

class _DeckOverviewScreenState extends State<DeckOverviewScreen> {
  Future<void> _editDeck(BuildContext context) async {
    final saved = await showDeckEditSheet(
      context,
      deck: widget.deck,
      allDecks: widget.allDecks,
    );
    if (saved == true && context.mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deck = widget.deck;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Row(
          children: [
            if (deck.isFiltered) ...[
              Icon(Icons.filter_list, size: 20, color: Colors.grey.shade700),
              const SizedBox(width: 6),
            ],
            Expanded(child: Text(deck.name)),
          ],
        ),
        actions: [
          if (!deck.isFiltered)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit deck',
              onPressed: () => _editDeck(context),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (deck.isFiltered && deck.filterQuery != null)
            Text(
              _filterDescription(deck.filterQuery!),
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DeckCountButton(
                count: deck.newCount,
                kind: DeckCountKind.newCards,
                size: DeckCountButtonSize.large,
              ),
              const SizedBox(width: 16),
              DeckCountButton(
                count: deck.learningCount,
                kind: DeckCountKind.learning,
                size: DeckCountButtonSize.large,
              ),
              const SizedBox(width: 16),
              DeckCountButton(
                count: deck.reviewDueCount,
                kind: DeckCountKind.review,
                size: DeckCountButtonSize.large,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 72,
                child: Text(
                  'New',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 72,
                child: Text(
                  'Learning',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 72,
                child: Text(
                  'To review',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (!deck.isFiltered) ...[
            FilledButton.icon(
              onPressed: () async {
                final saved = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => CardEditScreen(deckId: deck.id),
                  ),
                );
                if (saved == true && context.mounted) {
                  Navigator.pop(context, true);
                }
              },
              icon: const Icon(Icons.note_add_outlined),
              label: const Text('Add note'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryYellow,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
          ],
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ReviewSessionScreen(deckId: deck.id),
                ),
              );
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Study now'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          if (!deck.isFiltered)
            OutlinedButton.icon(
              onPressed: () async {
                final changed = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => DeckDetailScreen(deckId: deck.id),
                  ),
                );
                if (changed == true && context.mounted) {
                  Navigator.pop(context, true);
                }
              },
              icon: const Icon(Icons.list),
              label: const Text('View all cards'),
            ),
          if (!deck.isFiltered) const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CardBrowserScreen(deckId: deck.id),
                ),
              );
            },
            icon: const Icon(Icons.manage_search),
            label: const Text('Browse cards'),
          ),
        ],
      ),
    );
  }
}

String _filterDescription(Map<String, dynamic> filter) {
  final parts = <String>[];
  final q = filter['q']?.toString();
  if (q != null && q.isNotEmpty) parts.add('text "$q"');
  final tag = filter['tag']?.toString();
  if (tag != null && tag.isNotEmpty) parts.add('tag "$tag"');
  final state = filter['state']?.toString();
  if (state != null && state.isNotEmpty) parts.add('state $state');
  if (filter['sourceDeckId'] != null) {
    parts.add('deck #${filter['sourceDeckId']}');
  }
  return parts.isEmpty ? 'All cards' : parts.join(' · ');
}
