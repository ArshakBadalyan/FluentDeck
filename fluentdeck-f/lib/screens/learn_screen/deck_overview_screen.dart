import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fluentdeck/utils/deck_visuals.dart';
import 'statistics_screen.dart';
import 'package:fluentdeck/models/flashcard_model.dart';
import 'package:fluentdeck/models/flashcard_stats_model.dart';
import 'package:fluentdeck/screens/learn_screen/card_browser_screen.dart';
import 'package:fluentdeck/screens/learn_screen/card_edit_screen.dart';
import 'package:fluentdeck/screens/learn_screen/decks_settings_screen.dart';
import 'package:fluentdeck/screens/learn_screen/review_session_screen.dart';
import 'package:fluentdeck/screens/learn_screen/widgets/deck_edit_sheet.dart';
import 'package:fluentdeck/screens/learn_screen/widgets/filtered_deck_dialog.dart';
import 'package:fluentdeck/services/flashcard_service.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';
import 'package:fluentdeck/ui_elements/app_motion.dart';
import 'package:animations/animations.dart';

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

  /// Cards coming due per day (from the deck's detailed stats); null until
  /// loaded, empty when the request fails.
  List<FlashcardDayCount>? _forecast;
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
    _loadForecast();
  }

  Future<void> _loadForecast() async {
    try {
      final stats = await FlashcardService.instance.fetchDetailedStats(
        deckId: _deck.id,
        range: '1m',
      );
      if (mounted) setState(() => _forecast = stats.futureDueByDay);
    } catch (_) {
      if (mounted) setState(() => _forecast = const []);
    }
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
        // Light header, like the main tabs.
        appBar: AppBar(
          backgroundColor: AppPageColors.pageBgOf(context),
          foregroundColor: AppPageColors.textPrimaryOf(context),
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => Navigator.pop(context, _changed),
          ),
          actions: [
            // One menu, as in the design: review settings and deck options.
            PopupMenuButton<String>(
              tooltip: 'More',
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                if (value == 'settings') {
                  Navigator.of(context).push(
                    AppSharedAxisRoute<void>(
                      transitionType: SharedAxisTransitionType.scaled,
                      page: DecksSettingsScreen(deckId: deck.id),
                    ),
                  ).then((_) => _refreshDeck());
                } else {
                  _editDeck(context);
                }
              },
              itemBuilder: (_) => [
                if (!deck.isFiltered)
                  const PopupMenuItem(value: 'settings', child: Text('Review settings')),
                const PopupMenuItem(value: 'edit', child: Text('Deck options')),
              ],
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            if (deck.isFiltered && deck.filterQuery != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _filterDescription(deck.filterQuery!, widget.allDecks),
                  style: TextStyle(fontSize: 13, color: AppPageColors.subtitleOf(context)),
                ),
              ),
            _DeckHeader(deck: deck, totalCards: totalCards),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _CountBox(
                    count: deck.newCount,
                    label: 'New',
                    tint: AppTint.info,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CountBox(
                    count: deck.learningCount,
                    label: 'Learning',
                    tint: AppTint.danger,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CountBox(
                    count: deck.reviewDueCount,
                    label: 'To review',
                    tint: AppTint.success,
                  ),
                ),
              ],
            ),
            if (totalCards > 0 && deck.reviewDueCount + deck.newCount + deck.learningCount == 0) ...[
              const SizedBox(height: 10),
              Text(
                'All caught up. Come back when cards are due.',
                style: TextStyle(fontSize: 13, color: AppPageColors.subtitleOf(context)),
              ),
            ] else if (totalCards == 0) ...[
              const SizedBox(height: 10),
              Text(
                'No cards in this deck yet.',
                style: TextStyle(fontSize: 13, color: AppPageColors.subtitleOf(context)),
              ),
            ],
            const SizedBox(height: 16),
            AppPressScale(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppPageColors.accentOf(context).withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ReviewSessionScreen(deckId: deck.id),
                      ),
                    );
                    _refreshDeck();
                    _loadForecast();
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    () {
                      final due = deck.reviewDueCount + deck.newCount + deck.learningCount;
                      return due > 0 ? 'Study $due card${due == 1 ? '' : 's'}' : 'Study now';
                    }(),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppPageColors.accentOf(context),
                    foregroundColor: AppPageColors.onAccentOf(context),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                ),
              ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SecondaryDeckAction(
                    icon: Icons.manage_search_rounded,
                    label: 'Browse cards',
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CardBrowserScreen(deckId: deck.id),
                        ),
                      );
                      _refreshDeck();
                    },
                  ),
                ),
                if (!deck.isFiltered) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SecondaryDeckAction(
                      icon: Icons.note_add_outlined,
                      label: 'Add card',
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
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            _ForecastCard(
              forecast: _forecast,
              dueToday: deck.newCount + deck.learningCount + deck.reviewDueCount,
              onStatistics: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const StatisticsPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}




/// One tinted count box (New / Learning / To review).
class _CountBox extends StatelessWidget {
  const _CountBox({required this.count, required this.label, required this.tint});

  final int count;
  final String label;
  final AppTint tint;

  @override
  Widget build(BuildContext context) {
    final colors = AppPageColors.tintOf(context, tint);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCountUpText(
            '$count',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: colors.fg, height: 1.1),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 13, color: colors.fg)),
        ],
      ),
    );
  }
}

/// White secondary action beside its sibling (Browse cards / Add card).
class _SecondaryDeckAction extends StatelessWidget {
  const _SecondaryDeckAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppPressScale(
      child: Material(
        color: AppPageColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppPageColors.subtleBorderOf(context)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppPageColors.textPrimaryOf(context),
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

/// Deck icon, big name and card count (the name lives here, not in the bar).
class _DeckHeader extends StatelessWidget {
  const _DeckHeader({required this.deck, required this.totalCards});

  final FlashcardDeckModel deck;
  final int totalCards;

  @override
  Widget build(BuildContext context) {
    final accent = AppPageColors.accentOf(context);
    final fromSpeaking = deckTint(deck.name) == AppTint.voice;
    final cards = '$totalCards card${totalCards == 1 ? '' : 's'}';
    return Row(
      children: [
        if (deck.isFiltered)
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppPageColors.tintOf(context, AppTint.teal).bg,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.filter_list_rounded, color: accent, size: 26),
          )
        else
          DeckIconTile(name: deck.name, size: 56, iconSize: 26),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                deck.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 26,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: AppPageColors.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                deck.isFiltered
                    ? 'Filtered deck · $cards'
                    : fromSpeaking
                    ? '$cards · made from your conversations'
                    : deck.description.trim().isNotEmpty
                    ? '$cards · ${deck.description.trim()}'
                    : cards,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, color: AppPageColors.subtitleOf(context)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Next 7 days": how many cards come due each day, today in solid teal.
class _ForecastCard extends StatelessWidget {
  const _ForecastCard({required this.forecast, required this.dueToday, required this.onStatistics});

  final List<FlashcardDayCount>? forecast;
  final int dueToday;
  final VoidCallback onStatistics;

  @override
  Widget build(BuildContext context) {
    final accent = AppPageColors.accentOf(context);
    final subtitle = AppPageColors.subtitleOf(context);
    final today = DateTime.now();
    final byDate = {for (final d in forecast ?? const <FlashcardDayCount>[]) d.date: d.count};
    String key(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final days = [for (var i = 0; i < 7; i++) today.add(Duration(days: i))];
    // Today never shows fewer than the cards already due now.
    final counts = <int>[
      for (var i = 0; i < 7; i++)
        i == 0
            ? math.max(byDate[key(days[i])] ?? 0, dueToday)
            : (byDate[key(days[i])] ?? 0),
    ];
    final maxCount = counts.fold<int>(0, (a, b) => a > b ? a : b);
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPageColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppPageColors.subtleBorderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Next 7 days',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppPageColors.textPrimaryOf(context),
                  ),
                ),
              ),
              TextButton(
                onPressed: onStatistics,
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(44, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Statistics', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          if (forecast != null && maxCount == 0)
            Text(
              'Nothing due this week.',
              style: TextStyle(fontSize: 13, color: subtitle),
            ),
          const SizedBox(height: 12),
          Semantics(
            label: [for (var i = 0; i < 7; i++) '${i == 0 ? 'Today' : labels[days[i].weekday - 1]} ${counts[i]}'].join(', '),
            child: SizedBox(
              height: 90,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < 7; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: maxCount == 0 ? 0 : counts[i] / maxCount),
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        builder: (context, v, _) => Container(
                          height: 6 + 84 * v,
                          decoration: BoxDecoration(
                            color: i == 0 ? accent : accent.withValues(alpha: 0.4),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8),
                              bottom: Radius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 7; i++)
                Text(
                  i == 0 ? 'Today' : labels[days[i].weekday - 1],
                  style: TextStyle(fontSize: 12, color: subtitle),
                ),
            ],
          ),
        ],
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
