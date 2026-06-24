import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:speakstack/app_colors.dart';
import 'package:speakstack/data/decks_help_content.dart';
import 'package:speakstack/models/flashcard_model.dart';
import 'package:speakstack/models/flashcard_stats_model.dart';
import 'package:speakstack/services/flashcard_service.dart';
import 'package:speakstack/services/flashcard_stats_export_service.dart';
import 'package:speakstack/screens/learn_screen/review_log_screen.dart';
import 'package:speakstack/screens/learn_screen/widgets/decks_contextual_help.dart';
import 'package:speakstack/services/decks_help_hints_store.dart';
import 'package:speakstack/utils/statistics_labels.dart';
import 'package:speakstack/widgets/activity_preview_list.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _loading = true;
  String? _error;
  FlashcardDetailedStats? _stats;
  List<FlashcardReviewLogEntry> _log = const [];
  List<FlashcardDeckModel> _decks = const [];

  int? _deckFilter;
  String _range = '12m';

  static const _pageBg = Color(0xFFF7F5FB);

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      DecksContextualHelpButton.maybeShowFirstVisitHint(
        context,
        hintKey: DecksHelpHintsStore.statisticsKey,
        message: statisticsContextualHint,
        helpSectionId: 'statistics',
      );
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        FlashcardService.instance.fetchDetailedStats(deckId: _deckFilter, range: _range),
        FlashcardService.instance.fetchReviewLog(deckId: _deckFilter, limit: 30),
        FlashcardService.instance.fetchDecks(),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = results[0] as FlashcardDetailedStats;
        _log = results[1] as List<FlashcardReviewLogEntry>;
        _decks = results[2] as List<FlashcardDeckModel>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _exportPdf() async {
    final stats = _stats;
    if (stats == null) return;
    try {
      await FlashcardStatsExportService.instance.exportPdf(
        stats,
        decks: _decks,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ColoredBox(
        color: _pageBg,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return ColoredBox(
        color: _pageBg,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey.shade500),
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    final stats = _stats ?? const FlashcardDetailedStats();
    final scopeLabel = StatisticsLabels.summary(
      deckFilter: _deckFilter,
      range: _range,
      decks: _decks,
    );
    final matureRetention = stats.retention.mature;

    return ColoredBox(
      color: _pageBg,
      child: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primaryPurple,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _DeckStatsHero(
              reviewStreak: stats.reviewStreakDays,
              todayReviews: stats.today.reviews,
              todayDuration: stats.today.durationLabel,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _QuickMetricTile(
                    icon: Icons.style_outlined,
                    label: 'Total cards',
                    value: '${stats.totalCards}',
                    color: AppColors.primaryPurple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickMetricTile(
                    icon: Icons.replay_rounded,
                    label: 'Reviews',
                    value: '${stats.totalReviewsInRange}',
                    color: const Color(0xFF2196F3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickMetricTile(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Mature retention',
                    value: matureRetention == null ? '—' : '$matureRetention%',
                    color: AppColors.greenCorrect,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickMetricTile(
                    icon: Icons.fiber_new_rounded,
                    label: 'New cards',
                    value: '${stats.cardCounts.newCount}',
                    color: const Color(0xFFFF9800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _FilterCard(
              scopeLabel: scopeLabel,
              scopeDropdown: _scopeDropdown,
              rangeDropdown: _rangeDropdown,
              onExport: _exportPdf,
            ),
            const SizedBox(height: 16),
            _StatsSection(
              title: 'Today',
              icon: Icons.today_outlined,
              subtitle: stats.today.reviews > 0
                  ? '${(stats.today.avgDurationMs / 1000).toStringAsFixed(1)}s average per card'
                  : null,
              child: Text(
                stats.today.reviews == 0
                    ? 'No cards studied yet today — start a review session to build momentum.'
                    : 'Studied ${stats.today.reviews} card${stats.today.reviews == 1 ? '' : 's'} in ${stats.today.durationLabel} today.',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _StatsSection(
              title: 'Activity calendar',
              icon: Icons.calendar_month_outlined,
              subtitle: 'Reviews per day',
              child: _CalendarHeatmap(calendar: stats.calendar),
            ),
            const SizedBox(height: 16),
            _StatsSection(
              title: 'Daily reviews',
              icon: Icons.bar_chart_rounded,
              subtitle: 'Questions answered per day',
              child: SizedBox(
                height: 160,
                child: _BarChartSeries(
                  series: stats.reviewsByDay,
                  barColor: const Color(0xFF2196F3),
                  useGradient: true,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _StatsSection(
              title: 'Card breakdown',
              icon: Icons.pie_chart_outline_rounded,
              subtitle: '${stats.totalCards} cards in scope',
              child: SizedBox(
                height: 180,
                child: _CardCountsPie(counts: stats.cardCounts),
              ),
            ),
            const SizedBox(height: 16),
            _StatsSection(
              title: 'Answer buttons',
              icon: Icons.touch_app_outlined,
              subtitle: '${stats.buttonCounts.total} answers in range',
              child: SizedBox(
                height: 160,
                child: _ButtonCountsChart(counts: stats.buttonCounts),
              ),
            ),
            const SizedBox(height: 16),
            _StatsSection(
              title: 'Retention',
              icon: Icons.trending_up_rounded,
              subtitle: 'Young vs mature pass rate',
              child: _RetentionCards(retention: stats.retention),
            ),
            const SizedBox(height: 16),
            _StatsSection(
              title: 'Future due',
              icon: Icons.schedule_outlined,
              subtitle: 'Reviews scheduled in the next 30 days',
              child: SizedBox(
                height: 160,
                child: _BarChartSeries(
                  series: stats.futureDueByDay,
                  barColor: AppColors.primaryPurple,
                  useGradient: true,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _StatsSection(
              title: 'Card ease',
              icon: Icons.speed_outlined,
              subtitle: 'Ease factor distribution',
              child: SizedBox(
                height: 160,
                child: _EaseHistogram(buckets: stats.easeBuckets),
              ),
            ),
            const SizedBox(height: 16),
            _StatsSection(
              title: 'Hourly breakdown',
              icon: Icons.access_time_rounded,
              subtitle: 'When you study most',
              child: SizedBox(
                height: 160,
                child: _HourlyChart(hourly: stats.hourly),
              ),
            ),
            const SizedBox(height: 16),
            _StatsSection(
              title: 'New cards added',
              icon: Icons.add_circle_outline_rounded,
              subtitle: 'New cards studied per day',
              child: SizedBox(
                height: 160,
                child: _BarChartSeries(
                  series: stats.addedByDay,
                  barColor: AppColors.greenCorrect,
                  useGradient: true,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _StatsSection(
              title: 'Review intervals',
              icon: Icons.timelapse_outlined,
              subtitle: 'Days until next review',
              child: SizedBox(
                height: 160,
                child: _IntervalBucketsChart(buckets: stats.intervalBuckets),
              ),
            ),
            const SizedBox(height: 16),
            _StatsSection(
              title: 'Review log',
              icon: Icons.history_rounded,
              subtitle: 'Recent answers',
              child:
                  _log.isEmpty
                      ? const _EmptyHint(text: 'No review log entries yet.')
                      : ActivityPreviewList(
                        itemCount: _log.length,
                        itemHeight: 58,
                        itemSpacing: 8,
                        onViewAll: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder:
                                  (_) => ReviewLogScreen(deckId: _deckFilter),
                            ),
                          );
                        },
                        itemBuilder: (context, index) {
                          return ReviewLogEntryTile(entry: _log[index]);
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _statsFilterDecoration(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      filled: true,
      fillColor: _pageBg,
      labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primaryPurple.withValues(alpha: 0.5)),
      ),
    );
  }

  String _scopeDisplayLabel(int? deckId, {required bool compact}) {
    if (deckId == null) {
      return compact ? 'All' : StatisticsLabels.collectionScope;
    }
    for (final deck in _decks) {
      if (deck.id == deckId) {
        final name = deck.name;
        if (!compact || name.length <= 10) return name;
        return '${name.substring(0, 9)}…';
      }
    }
    return compact ? '#$deckId' : 'Deck #$deckId';
  }

  String _rangeDisplayLabel(String range, {required bool compact}) {
    if (range == 'all') {
      return compact ? 'All' : StatisticsLabels.rangeAllHistory;
    }
    return compact ? '12 mo' : StatisticsLabels.range12Months;
  }

  Widget _scopeDropdown({required bool compact}) {
    return DropdownButtonFormField<int?>(
      key: ValueKey(_deckFilter),
      isExpanded: true,
      initialValue: _deckFilter,
      style: TextStyle(fontSize: compact ? 13 : 14, color: Colors.black87),
      decoration: _statsFilterDecoration('Scope'),
      selectedItemBuilder:
          (_) => [
            DropdownMenuItem(
              value: null,
              child: Text(
                _scopeDisplayLabel(null, compact: compact),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ..._decks.map(
              (d) => DropdownMenuItem(
                value: d.id,
                child: Text(
                  _scopeDisplayLabel(d.id, compact: compact),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text(StatisticsLabels.collectionScope, overflow: TextOverflow.ellipsis),
        ),
        ..._decks.map(
          (d) => DropdownMenuItem(
            value: d.id,
            child: Text('Deck: ${d.name}', overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: (v) {
        setState(() => _deckFilter = v);
        _load();
      },
    );
  }

  Widget _rangeDropdown({required bool compact}) {
    return DropdownButtonFormField<String>(
      key: ValueKey(_range),
      isExpanded: true,
      initialValue: _range,
      style: TextStyle(fontSize: compact ? 13 : 14, color: Colors.black87),
      decoration: _statsFilterDecoration('Range'),
      selectedItemBuilder:
          (_) => [
            DropdownMenuItem(
              value: '12m',
              child: Text(
                _rangeDisplayLabel('12m', compact: compact),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DropdownMenuItem(
              value: 'all',
              child: Text(
                _rangeDisplayLabel('all', compact: compact),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
      items: const [
        DropdownMenuItem(value: '12m', child: Text(StatisticsLabels.range12Months)),
        DropdownMenuItem(value: 'all', child: Text(StatisticsLabels.rangeAllHistory)),
      ],
      onChanged: (v) {
        if (v == null) return;
        setState(() => _range = v);
        _load();
      },
    );
  }
}

class _DeckStatsHero extends StatelessWidget {
  const _DeckStatsHero({
    required this.reviewStreak,
    required this.todayReviews,
    required this.todayDuration,
  });

  final int reviewStreak;
  final int todayReviews;
  final String todayDuration;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9B3DFF), Color(0xFF7A24E4)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$todayReviews',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  todayReviews == 1 ? 'card today' : 'cards today',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  todayReviews > 0
                      ? '$todayDuration spent reviewing'
                      : 'Start reviewing to track your progress',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
                if (reviewStreak > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          size: 16,
                          color: Colors.orange.shade200,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$reviewStreak day review streak',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.collections_bookmark_outlined,
              size: 40,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickMetricTile extends StatelessWidget {
  const _QuickMetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.scopeLabel,
    required this.scopeDropdown,
    required this.rangeDropdown,
    required this.onExport,
  });

  final String scopeLabel;
  final Widget Function({required bool compact}) scopeDropdown;
  final Widget Function({required bool compact}) rangeDropdown;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, size: 18, color: AppColors.primaryPurple),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Filters',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Export PDF',
                visualDensity: VisualDensity.compact,
                onPressed: onExport,
                icon: Icon(Icons.picture_as_pdf_outlined, color: Colors.grey.shade700),
              ),
              const DecksContextualHelpButton(
                helpSectionId: 'statistics',
                iconSize: 20,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            scopeLabel,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 400;
              if (compact) {
                return Column(
                  children: [
                    scopeDropdown(compact: true),
                    const SizedBox(height: 10),
                    rangeDropdown(compact: true),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: scopeDropdown(compact: false)),
                  const SizedBox(width: 10),
                  Expanded(child: rangeDropdown(compact: false)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primaryPurple),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 14,
          height: 1.45,
        ),
      ),
    );
  }
}

class _CardCountsPie extends StatelessWidget {
  const _CardCountsPie({required this.counts});

  final FlashcardCardCounts counts;

  @override
  Widget build(BuildContext context) {
    final total = counts.total;
    if (total == 0) {
      return const _EmptyHint(text: 'No cards yet — create a deck to get started.');
    }

    final legend = <({String label, int value, Color color})>[
      (label: 'New', value: counts.newCount, color: const Color(0xFF2196F3)),
      (label: 'Learning', value: counts.learning, color: const Color(0xFFFF9800)),
      (label: 'Mature', value: counts.review, color: AppColors.greenCorrect),
      (label: 'Suspended', value: counts.suspended, color: Colors.grey),
      (label: 'Buried', value: counts.buried, color: Colors.blueGrey),
    ].where((e) => e.value > 0).toList();

    final sections =
        legend
            .map(
              (e) => PieChartSectionData(
                value: e.value.toDouble(),
                title: '${e.value}',
                color: e.color,
                radius: 44,
                titleStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            )
            .toList();

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 32,
              sections: sections,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                legend
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: e.color,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                            Text(
                              '${e.value}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
      ],
    );
  }
}

class _BarChartSeries extends StatelessWidget {
  const _BarChartSeries({
    required this.series,
    required this.barColor,
    this.useGradient = false,
  });

  final List<FlashcardDayCount> series;
  final Color barColor;
  final bool useGradient;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return const _EmptyHint(text: 'No data yet — reviews will appear here over time.');
    }

    final maxY = series.map((e) => e.count).fold<int>(0, (a, b) => a > b ? a : b).toDouble();

    return BarChart(
      BarChartData(
        maxY: maxY < 1 ? 1 : maxY * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY <= 5 ? 1 : (maxY / 4).ceilToDouble(),
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups:
            series.asMap().entries.map((e) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value.count.toDouble(),
                    color: useGradient ? null : barColor,
                    gradient: useGradient
                        ? LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              barColor.withValues(alpha: 0.65),
                              barColor,
                            ],
                          )
                        : null,
                    width: 7,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }
}

class _ButtonCountsChart extends StatelessWidget {
  const _ButtonCountsChart({required this.counts});

  final FlashcardButtonCounts counts;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Again', counts.again, AppColors.redWrong),
      ('Hard', counts.hard, const Color(0xFFFF9800)),
      ('Good', counts.good, AppColors.primaryYellow),
      ('Easy', counts.easy, AppColors.greenCorrect),
    ];
    final max = items.map((e) => e.$2).fold<int>(0, (a, b) => a > b ? a : b);

    if (max == 0) {
      return const _EmptyHint(text: 'No reviews logged yet.');
    }

    return BarChart(
      BarChartData(
        maxY: max * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= items.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    items[i].$1,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups:
            items.asMap().entries.map((e) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value.$2.toDouble(),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        e.value.$3.withValues(alpha: 0.7),
                        e.value.$3,
                      ],
                    ),
                    width: 32,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }
}

class _CalendarHeatmap extends StatelessWidget {
  const _CalendarHeatmap({required this.calendar});

  final Map<String, int> calendar;

  @override
  Widget build(BuildContext context) {
    if (calendar.isEmpty) {
      return const _EmptyHint(text: 'No activity yet — your study calendar will fill in as you review.');
    }

    final keys = calendar.keys.toList()..sort();
    final last = keys.length > 84 ? keys.sublist(keys.length - 84) : keys;
    final max = calendar.values.fold<int>(0, (a, b) => a > b ? a : b);

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children:
          last.map((key) {
            final count = calendar[key] ?? 0;
            final intensity = max > 0 ? count / max : 0.0;
            return Tooltip(
              message: '$key: $count review${count == 1 ? '' : 's'}',
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withValues(alpha: 0.12 + intensity * 0.88),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }).toList(),
    );
  }
}

class _EaseHistogram extends StatelessWidget {
  const _EaseHistogram({required this.buckets});

  final FlashcardEaseBuckets buckets;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('< 2.0', buckets.low, AppColors.redWrong),
      ('2.0–2.5', buckets.mid, const Color(0xFFFF9800)),
      ('≥ 2.5', buckets.high, AppColors.greenCorrect),
    ];
    final max = items.map((e) => e.$2).fold<int>(0, (a, b) => a > b ? a : b);
    if (max == 0) {
      return const _EmptyHint(text: 'No ease data yet.');
    }

    return BarChart(
      BarChartData(
        maxY: max * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= items.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    items[i].$1,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups:
            items.asMap().entries.map((e) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value.$2.toDouble(),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        e.value.$3.withValues(alpha: 0.7),
                        e.value.$3,
                      ],
                    ),
                    width: 32,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }
}

class _RetentionCards extends StatelessWidget {
  const _RetentionCards({required this.retention});

  final FlashcardRetentionStats retention;

  @override
  Widget build(BuildContext context) {
    String pct(int? value) => value == null ? '—' : '$value%';

    return Row(
      children: [
        Expanded(
          child: _RetentionTile(
            label: 'Young',
            sublabel: '< 21 days',
            retention: pct(retention.young),
            reviews: retention.youngReviews,
            color: const Color(0xFF2196F3),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RetentionTile(
            label: 'Mature',
            sublabel: '≥ 21 days',
            retention: pct(retention.mature),
            reviews: retention.matureReviews,
            color: AppColors.greenCorrect,
          ),
        ),
      ],
    );
  }
}

class _RetentionTile extends StatelessWidget {
  const _RetentionTile({
    required this.label,
    required this.sublabel,
    required this.retention,
    required this.reviews,
    required this.color,
  });

  final String label;
  final String sublabel;
  final String retention;
  final int reviews;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.9),
            ),
          ),
          Text(
            sublabel,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 10),
          Text(
            retention,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: color.withValues(alpha: 0.95),
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$reviews reviews',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _HourlyChart extends StatelessWidget {
  const _HourlyChart({required this.hourly});

  final List<FlashcardHourlyCount> hourly;

  @override
  Widget build(BuildContext context) {
    if (hourly.isEmpty) {
      return const _EmptyHint(text: 'No hourly data yet.');
    }

    final max = hourly.map((e) => e.count).fold<int>(0, (a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        maxY: max < 1 ? 1 : max * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups:
            hourly.asMap().entries.map((e) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value.count.toDouble(),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppColors.primaryPurple.withValues(alpha: 0.55),
                        AppColors.primaryPurple,
                      ],
                    ),
                    width: 5,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }
}

class _IntervalBucketsChart extends StatelessWidget {
  const _IntervalBucketsChart({required this.buckets});

  final FlashcardIntervalBuckets buckets;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('≤ 1d', buckets.day1, const Color(0xFF2196F3)),
      ('≤ 7d', buckets.week1, const Color(0xFFFF9800)),
      ('≤ 30d', buckets.month1, AppColors.primaryYellow),
      ('30d+', buckets.beyond, AppColors.greenCorrect),
    ];
    final max = items.map((e) => e.$2).fold<int>(0, (a, b) => a > b ? a : b);
    if (max == 0) {
      return const _EmptyHint(text: 'No interval data yet.');
    }

    return BarChart(
      BarChartData(
        maxY: max * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= items.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    items[i].$1,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups:
            items.asMap().entries.map((e) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value.$2.toDouble(),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        e.value.$3.withValues(alpha: 0.7),
                        e.value.$3,
                      ],
                    ),
                    width: 32,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }
}
