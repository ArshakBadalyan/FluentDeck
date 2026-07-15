import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/models/flashcard_model.dart';
import 'package:fluentdeck/screens/learn_screen/card_browser_screen.dart';
import 'package:fluentdeck/screens/learn_screen/card_edit_screen.dart';
import 'package:fluentdeck/screens/learn_screen/deck_detail_screen.dart';
import 'package:fluentdeck/screens/learn_screen/review_session_screen.dart';
import 'package:fluentdeck/screens/learn_screen/widgets/deck_count_buttons.dart';
import 'package:fluentdeck/screens/learn_screen/widgets/deck_edit_sheet.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';

/// Deck overview — opened by tapping deck name or count buttons.
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
    final totalCards = deck.newCount + deck.learningCount + deck.reviewDueCount;

    return AppPageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Row(
            children: [
              if (deck.isFiltered) ...[
                Icon(Icons.filter_list, size: 20, color: Colors.grey.shade700),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  deck.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Rubik',
                  ),
                ),
              ),
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
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            if (deck.isFiltered && deck.filterQuery != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _filterDescription(deck.filterQuery!),
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ),
            _DeckHeroCard(
              totalCards: totalCards,
              newCount: deck.newCount,
              learningCount: deck.learningCount,
              reviewCount: deck.reviewDueCount,
            ),
            const SizedBox(height: 16),
            AppSectionCard(
              title: 'Study',
              icon: Icons.school_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PrimaryDeckAction(
                    icon: Icons.play_arrow_rounded,
                    title: 'Study now',
                    subtitle: deck.reviewDueCount + deck.newCount + deck.learningCount > 0
                        ? 'Review cards due today'
                        : 'No cards due right now',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ReviewSessionScreen(deckId: deck.id),
                        ),
                      );
                    },
                  ),
                  if (!deck.isFiltered) ...[
                    const SizedBox(height: 8),
                    AppSheetActionTile(
                      icon: Icons.note_add_outlined,
                      title: 'Add card',
                      subtitle: 'Create a new flashcard in this deck',
                      onTap: () async {
                        final saved = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => CardEditScreen(deckId: deck.id),
                          ),
                        );
                        if (saved == true && context.mounted) {
                          Navigator.pop(context, true);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppSectionCard(
              title: 'Browse',
              icon: Icons.grid_view_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!deck.isFiltered)
                    AppSheetActionTile(
                      icon: Icons.list_alt_rounded,
                      title: 'View all cards',
                      subtitle: 'Scroll through every card in this deck',
                      onTap: () async {
                        final changed = await Navigator.of(context).push<bool>(
                          MaterialPageRoute<bool>(
                            builder: (_) => DeckDetailScreen(deckId: deck.id),
                          ),
                        );
                        if (changed == true && context.mounted) {
                          Navigator.pop(context, true);
                        }
                      },
                    ),
                  AppSheetActionTile(
                    icon: Icons.manage_search_rounded,
                    title: 'Browse cards',
                    subtitle: 'Search, filter, and edit cards in a table',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CardBrowserScreen(deckId: deck.id),
                        ),
                      );
                    },
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

class _DeckHeroCard extends StatelessWidget {
  const _DeckHeroCard({
    required this.totalCards,
    required this.newCount,
    required this.learningCount,
    required this.reviewCount,
  });

  final int totalCards;
  final int newCount;
  final int learningCount;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryPurple.withValues(alpha: 0.08),
              Colors.white,
            ],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$totalCards card${totalCards == 1 ? '' : 's'}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                fontFamily: 'Rubik',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Track new, learning, and review progress',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: DeckCountButtons(
                newCount: newCount,
                learningCount: learningCount,
                reviewCount: reviewCount,
                size: DeckCountButtonSize.large,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatLabel('New', const Color(0xFF2196F3)),
                const SizedBox(width: 16),
                _StatLabel('Learning', const Color(0xFFE53935)),
                const SizedBox(width: 16),
                _StatLabel('To review', const Color(0xFF43A047)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatLabel extends StatelessWidget {
  const _StatLabel(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _PrimaryDeckAction extends StatelessWidget {
  const _PrimaryDeckAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryPurple,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 22, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'Rubik',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ],
          ),
        ),
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
