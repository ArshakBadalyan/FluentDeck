import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/models/flashcard_model.dart';
import 'package:fluentdeck/screens/learn_screen/card_browser_screen.dart';
import 'package:fluentdeck/screens/learn_screen/card_edit_screen.dart';
import 'package:fluentdeck/screens/learn_screen/review_session_screen.dart';
import 'package:fluentdeck/screens/learn_screen/widgets/deck_edit_sheet.dart';
import 'package:fluentdeck/screens/learn_screen/widgets/filtered_deck_dialog.dart';
import 'package:fluentdeck/services/flashcard_service.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';
import 'package:fluentdeck/ui_elements/app_motion.dart';
import 'package:fluentdeck/widgets/tutor_scene.dart';

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
  late FlashcardDeckModel _deck = widget.deck;
  // True once this screen's counts have diverged from what the caller (the
  // Decks list) was showing when it opened this screen — tells the caller
  // on the way back whether it needs to reload too, same as the explicit
  // `Navigator.pop(context, true)` already used after add/view-all-cards.
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    // The deck counts passed in may already be stale by the time this
    // screen opens (e.g. reviews done elsewhere since the caller last
    // fetched its deck list) — refresh once up front rather than only
    // after this screen's own actions change something.
    _refreshDeck();
  }

  /// Re-fetches this deck from the server so counts reflect reviews/edits
  /// made on a screen pushed from here (study session, card browser) —
  /// those write straight to the server, but this screen was handed a
  /// snapshot at construction time and never saw the update on its own.
  Future<void> _refreshDeck() async {
    try {
      final decks = await FlashcardService.instance.fetchDecks();
      FlashcardDeckModel? match;
      for (final d in decks) {
        if (d.id == _deck.id) {
          match = d;
          break;
        }
      }
      final refreshed = match;
      if (refreshed != null && mounted) {
        if (refreshed.total != _deck.total ||
            refreshed.newCount != _deck.newCount ||
            refreshed.learningCount != _deck.learningCount ||
            refreshed.reviewDueCount != _deck.reviewDueCount) {
          _changed = true;
        }
        setState(() => _deck = refreshed);
      }
    } catch (_) {
      // Offline or request failed — keep showing the last known counts
      // rather than erroring out of the whole screen over a refresh.
    }
  }

  Future<void> _editDeck(BuildContext context) async {
    final saved =
        _deck.isFiltered
            ? await showFilteredDeckDialog(
                  context,
                  decks: widget.allDecks,
                  existing: _deck,
                ) !=
                null
            : await showDeckEditSheet(
              context,
              deck: _deck,
              allDecks: widget.allDecks,
            );
    if (saved == true && context.mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deck = _deck;
    // `deck.total` is every card in the deck (backend `deckStats.total`,
    // never affected by review state); new/learning/review only counts
    // cards actually available for study, so a deck of only
    // suspended/buried cards previously showed "0 cards" / "No cards in
    // this deck yet" here even though the Card browser correctly listed
    // them — summing just the active buckets undercounted it.
    final totalCards = deck.total;

    return AppPageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: AppColors.brandPrimaryDeep,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.35),
          scrolledUnderElevation: 8,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _changed),
          ),
          title: Row(
            children: [
              if (deck.isFiltered) ...[
                Icon(Icons.filter_list, size: 20, color: Colors.white.withValues(alpha: 0.85)),
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
                  _filterDescription(deck.filterQuery!, widget.allDecks),
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
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ReviewSessionScreen(deckId: deck.id),
                        ),
                      );
                      _refreshDeck();
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
                  AppSheetActionTile(
                    icon: Icons.manage_search_rounded,
                    title: 'Browse cards',
                    subtitle: 'Search, filter, and edit cards in a table',
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CardBrowserScreen(deckId: deck.id),
                        ),
                      );
                      _refreshDeck();
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
      color: AppColors.brandPrimaryDeep,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          color: AppColors.brandPrimaryDeep,
        ),
        clipBehavior: Clip.antiAlias,
        child: SceneBackdrop(
          scene: TutorScene.listening,
          color: AppColors.brandPrimaryDeep,
          child: Padding(
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
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Track new, learning, and review progress',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.78),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            if (newCount + learningCount + reviewCount > 0)
              Center(
                child: SizedBox(
                  width: 240,
                  height: 110,
                  child: _DeckCountBarChart(
                    newCount: newCount,
                    learningCount: learningCount,
                    reviewCount: reviewCount,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  totalCards == 0
                      ? 'No cards in this deck yet.'
                      : 'All cards are suspended or buried.',
                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.78)),
                ),
              ),
          ],
        ),
          ),
        ),
      ),
    );
  }
}

/// Rounded-capsule bar chart (fl_chart "pill" style) for the New/Learning/
/// Review split — a background track plus a filled, color-matched bar.
class _DeckCountBarChart extends StatelessWidget {
  const _DeckCountBarChart({
    required this.newCount,
    required this.learningCount,
    required this.reviewCount,
  });

  final int newCount;
  final int learningCount;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    final values = [
      (label: 'New', count: newCount, color: const Color(0xFF4994EC)),
      (label: 'Learning', count: learningCount, color: const Color(0xFFED7249)),
      (label: 'To review', count: reviewCount, color: const Color(0xFF7FFB66)),
    ];
    final maxY =
        values.map((e) => e.count).fold<int>(0, (a, b) => a > b ? a : b).toDouble();
    final chartMaxY = maxY < 1 ? 1.0 : maxY * 1.15;

    return AppChartReveal(
      style: AppChartRevealStyle.up,
      child: BarChart(
      BarChartData(
        maxY: chartMaxY,
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => values[group.x.toInt()].color.withValues(alpha: 0.9),
            getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
              rod.toY.toInt().toString(),
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= values.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    values[i].label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < values.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i].count.toDouble(),
                  color: values[i].color,
                  width: 30,
                  borderRadius: BorderRadius.circular(30),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: chartMaxY,
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
              ],
            ),
        ],
      ),
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
      color: AppColors.brandPrimaryDeep,
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

String _filterDescription(
  Map<String, dynamic> filter,
  List<FlashcardDeckModel> decks,
) {
  final parts = <String>[];
  final q = filter['q']?.toString();
  if (q != null && q.isNotEmpty) parts.add('text "$q"');
  final tag = filter['tag']?.toString();
  if (tag != null && tag.isNotEmpty) parts.add('tag "$tag"');
  // state / flag / cefrLevel may be a list (multi-select) or a single value.
  List<String> values(Object? raw) => [
    for (final v in raw is List ? raw : [if (raw != null) raw])
      if ('$v'.isNotEmpty && '$v' != 'all') '$v',
  ];
  final states = values(filter['state']);
  if (states.isNotEmpty) parts.add('state ${states.join(', ')}');
  final levels = values(filter['cefrLevel']);
  if (levels.isNotEmpty) {
    parts.add('level ${levels.map((l) => l == 'none' ? 'no level' : l).join(', ')}');
  }
  final flags = values(filter['flag']);
  if (flags.isNotEmpty) {
    parts.add(flags.map((f) => f == 'none' ? 'no flag' : 'flag $f').join(', '));
  }
  final many = filter['sourceDeckIds'];
  final ids = [
    if (filter['sourceDeckId'] != null) filter['sourceDeckId'],
    if (many is List) ...many,
  ];
  if (ids.isNotEmpty) {
    final names = [
      for (final id in ids)
        decks.where((d) => '${d.id}' == '$id').firstOrNull?.name ?? '#$id',
    ];
    parts.add('${names.length == 1 ? 'deck' : 'decks'} ${names.join(', ')}');
  }
  return parts.isEmpty ? 'All cards' : parts.join(' · ');
}
