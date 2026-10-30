import 'package:fluentdeck/ui_elements/app_toast.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fluentdeck/config/brand_config.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/data/decks_help_content.dart';
import 'package:fluentdeck/models/flashcard_model.dart';
import 'package:fluentdeck/models/flashcard_stats_model.dart';
import 'package:fluentdeck/services/flashcard_service.dart';
import 'package:fluentdeck/services/flashcard_stats_export_service.dart';
import 'package:fluentdeck/screens/learn_screen/review_log_screen.dart';
import 'package:fluentdeck/screens/learn_screen/widgets/decks_contextual_help.dart';
import 'package:fluentdeck/services/decks_help_hints_store.dart';
import 'package:fluentdeck/ui_elements/app_skeletons.dart';
import 'package:fluentdeck/utils/statistics_labels.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';
import 'package:fluentdeck/widgets/activity_preview_list.dart';
import 'package:fluentdeck/ui_elements/app_motion.dart';

/// Statistics as its own page (Deck overview → Statistics), with a back arrow.
class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Statistics', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
      ),
      body: const StatisticsScreen(),
    );
  }
}

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
  String _range = '30d';

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
      AppToast.showSnackBar(context, SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return AppLoadingSwitcher(
      loading: true,
      child: const AppPageBackground(
        child: AppListSkeleton(count: 4, itemHeight: 160),
      ),
    );
    }

    if (_error != null) {
      return AppPageBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_outlined, size: 48, color: AppPageColors.subtitleOf(context)),
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

    return AppLoadingSwitcher(
      loading: false,
      child: AppPageBackground(
      child: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.brandPrimary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            _ScopeRangeRow(
              scope: StatisticsLabels.scopeLabelForFilter(_deckFilter, _decks),
              range: StatisticsLabels.rangeShort(_range),
              onScope: _pickScope,
              onRange: _pickRange,
            ),
            const SizedBox(height: 12),
            _SummaryCards(stats: stats, range: _range),
            const SizedBox(height: 12),
            _ReviewsPerDayCard(series: stats.reviewsByDay),
            const SizedBox(height: 12),
            _CardStatesCard(counts: stats.cardCounts),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: _exportPdf,
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppPageColors.cardBgOf(context),
                  foregroundColor: AppPageColors.textPrimaryOf(context),
                  side: BorderSide(color: AppPageColors.subtleBorderOf(context)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                child: const Text('Export as PDF'),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'More statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppPageColors.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: 12),
            _StatsSection(
              title: 'Activity calendar',
              icon: Icons.calendar_month_outlined,
              subtitle: 'Reviews per day',
              child: _CalendarHeatmap(calendar: stats.calendar),
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
                child: _LineChartSeries(
                  series: stats.futureDueByDay,
                  lineColor: AppColors.brandPrimary,
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
                child: _LineChartSeries(
                  series: stats.addedByDay,
                  lineColor: AppColors.greenCorrect,
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
    ),
    );
  }

  Future<void> _pickScope() async {
    final picked = await showAppSelectSheet<int?>(
      context: context,
      title: 'Statistics for',
      selected: _deckFilter,
      options: [
        const AppSelectOption<int?>(value: null, label: 'All decks'),
        for (final d in _decks) AppSelectOption<int?>(value: d.id, label: d.name),
      ],
    );
    if (picked == null || !mounted) return;
    setState(() => _deckFilter = picked.value);
    _load();
  }

  Future<void> _pickRange() async {
    final picked = await showAppSelectSheet<String>(
      context: context,
      title: 'Range',
      selected: _range,
      options: [
        for (final r in const ['30d', '90d', '12m', 'all'])
          AppSelectOption(value: r, label: StatisticsLabels.rangeLabel(r)),
      ],
    );
    if (picked == null || !mounted) return;
    setState(() => _range = picked.value);
    _load();
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
        color: AppPageColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPageColors.subtleBorderOf(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.03,
            ),
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
              Icon(icon, size: 20, color: AppColors.brandPrimary),
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
              style: TextStyle(fontSize: 13, color: AppPageColors.subtitleOf(context)),
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
          color: AppPageColors.subtitleOf(context),
          fontSize: 14,
          height: 1.45,
        ),
      ),
    );
  }
}

class _LineChartSeries extends StatelessWidget {
  const _LineChartSeries({
    required this.series,
    required this.lineColor,
  });

  final List<FlashcardDayCount> series;
  final Color lineColor;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return const _EmptyHint(text: 'No data yet — reviews will appear here over time.');
    }

    final maxY = series.map((e) => e.count).fold<int>(0, (a, b) => a > b ? a : b).toDouble();
    final yInterval = maxY <= 5 ? 1.0 : (maxY / 4).ceilToDouble();
    // Showing every date would overlap on a 30-point series — thin them out
    // to roughly 5-6 labels across the chart.
    final labelEvery = (series.length / 5).ceil().clamp(1, series.length);
    final spots = series.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.count.toDouble()))
        .toList();

    return AppChartReveal(
      style: AppChartRevealStyle.right,
      child: LineChart(
      LineChartData(
        minX: 0,
        maxX: (series.length - 1).toDouble(),
        minY: 0,
        maxY: maxY < 1 ? 1 : maxY * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppPageColors.subtleBorderOf(context),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: yInterval,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: TextStyle(fontSize: 10, color: AppPageColors.subtitleOf(context)),
              ),
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.round();
                if (i < 0 || i >= series.length) return const SizedBox.shrink();
                if (i % labelEvery != 0 && i != series.length - 1) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _shortDayLabel(series[i].date),
                    style: TextStyle(fontSize: 10, color: AppPageColors.subtitleOf(context)),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => lineColor.withValues(alpha: 0.9),
            getTooltipItems: (touchedSpots) => touchedSpots
                .map(
                  (spot) => LineTooltipItem(
                    spot.y.toInt().toString(),
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                )
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            preventCurveOverShooting: true,
            color: lineColor,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  lineColor.withValues(alpha: 0.32),
                  lineColor.withValues(alpha: 0.0),
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

/// "2026-10-15" -> "Oct 15"; falls back to the raw string if it doesn't parse.
String _shortDayLabel(String isoDate) {
  final date = DateTime.tryParse(isoDate);
  if (date == null) return isoDate;
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
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

    return AppChartReveal(
      style: AppChartRevealStyle.up,
      child: BarChart(
      BarChartData(
        maxY: max * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => items[group.x.toInt()].$3.withValues(alpha: 0.9),
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
                      color: AppPageColors.subtitleOf(context),
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
                  color: AppColors.brandPrimary.withValues(alpha: 0.12 + intensity * 0.88),
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

    return AppChartReveal(
      style: AppChartRevealStyle.up,
      child: BarChart(
      BarChartData(
        maxY: max * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => items[group.x.toInt()].$3.withValues(alpha: 0.9),
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
                      color: AppPageColors.subtitleOf(context),
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
            style: TextStyle(fontSize: 11, color: AppPageColors.subtitleOf(context)),
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
            style: TextStyle(fontSize: 12, color: AppPageColors.subtitleOf(context)),
          ),
        ],
      ),
    );
  }
}

String _hourAxisLabel(int hour) {
  final period = hour < 12 ? 'a' : 'p';
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;
  return '$displayHour$period';
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

    return AppChartReveal(
      style: AppChartRevealStyle.up,
      child: BarChart(
      BarChartData(
        maxY: max < 1 ? 1 : max * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: AppPageColors.subtleBorderOf(context), strokeWidth: 1, dashArray: [4, 4]),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.brandPrimary.withValues(alpha: 0.9),
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
              reservedSize: 18,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index < 0 || index >= hourly.length) return const SizedBox.shrink();
                final hour = hourly[index].hour;
                // Every 3 hours keeps the axis legible instead of cramming
                // a label under all 24 bars.
                if (hour % 3 != 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _hourAxisLabel(hour),
                    style: TextStyle(
                      fontSize: 9,
                      color: AppPageColors.subtitleOf(context),
                    ),
                  ),
                );
              },
            ),
          ),
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
                        AppColors.brandPrimary.withValues(alpha: 0.55),
                        AppColors.brandPrimary,
                      ],
                    ),
                    width: 5,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                  ),
                ],
              );
            }).toList(),
      ),
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

    return AppChartReveal(
      style: AppChartRevealStyle.up,
      child: BarChart(
      BarChartData(
        maxY: max * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => items[group.x.toInt()].$3.withValues(alpha: 0.9),
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
                      color: AppPageColors.subtitleOf(context),
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
    ),
    );
  }
}

/// Scope ("All decks" or one deck) and range ("30 days") as two pills.
class _ScopeRangeRow extends StatelessWidget {
  const _ScopeRangeRow({
    required this.scope,
    required this.range,
    required this.onScope,
    required this.onRange,
  });

  final String scope;
  final String range;
  final VoidCallback onScope;
  final VoidCallback onRange;

  @override
  Widget build(BuildContext context) {
    Widget pill(String label, VoidCallback onTap, {bool flexible = false}) {
      final text = Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppPageColors.textPrimaryOf(context)),
      );
      return Material(
        color: AppPageColors.cardBgOf(context),
        shape: StadiumBorder(side: BorderSide(color: AppPageColors.subtleBorderOf(context))),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Container(
            height: 36,
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                flexible ? Flexible(child: text) : text,
                Icon(Icons.expand_more_rounded, size: 18, color: AppPageColors.mutedOf(context)),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Flexible(child: pill(scope == StatisticsLabels.collectionScope ? 'All decks' : scope.replaceFirst('Deck: ', ''), onScope, flexible: true)),
        const SizedBox(width: 8),
        pill(range, onRange),
      ],
    );
  }
}

class _StatCardFrame extends StatelessWidget {
  const _StatCardFrame({required this.child, this.radius = 22});

  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPageColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppPageColors.subtleBorderOf(context)),
      ),
      child: child,
    );
  }
}

/// Reviews (with the change vs the period before) and share answered right.
class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.stats, required this.range});

  final FlashcardDetailedStats stats;
  final String range;

  @override
  Widget build(BuildContext context) {
    final b = stats.buttonCounts;
    final answered = b.again + b.hard + b.good + b.easy;
    final correct = answered == 0 ? null : ((answered - b.again) / answered * 100).round();
    final prev = stats.previousReviewsInRange;
    final period = switch (range) {
      '30d' => 'last month',
      '90d' => 'the 90 days before',
      '12m' => 'the year before',
      _ => '',
    };
    String? delta;
    var up = true;
    if (prev != null && prev > 0 && period.isNotEmpty) {
      final pct = ((stats.totalReviewsInRange - prev) / prev * 100).round();
      up = pct >= 0;
      delta = '${up ? '+' : ''}$pct% vs $period';
    } else if (prev == 0 && stats.totalReviewsInRange > 0 && period.isNotEmpty) {
      delta = 'New vs $period';
    }
    final mature = stats.retention.mature;

    Widget card(String label, String value, String? note, {Color? noteColor, FontWeight? noteWeight}) => Expanded(
      child: _StatCardFrame(
        radius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 13, color: AppPageColors.subtitleOf(context))),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppPageColors.textPrimaryOf(context)),
            ),
            if (note != null) ...[
              const SizedBox(height: 2),
              Text(
                note,
                style: TextStyle(fontSize: 12, fontWeight: noteWeight, color: noteColor ?? AppPageColors.subtitleOf(context)),
              ),
            ],
          ],
        ),
      ),
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          card(
            'Reviews',
            '${stats.totalReviewsInRange}',
            delta,
            noteColor: AppPageColors.tintOf(context, up ? AppTint.success : AppTint.danger).fg,
            noteWeight: FontWeight.w600,
          ),
          const SizedBox(width: 10),
          card(
            'Correct',
            correct == null ? '—' : '$correct%',
            mature == null ? null : 'Mature cards $mature%',
          ),
        ],
      ),
    );
  }
}

/// The last 14 days as bars; today in solid teal.
class _ReviewsPerDayCard extends StatelessWidget {
  const _ReviewsPerDayCard({required this.series});

  final List<FlashcardDayCount> series;

  @override
  Widget build(BuildContext context) {
    final accent = AppPageColors.accentOf(context);
    final byDate = {for (final d in series) d.date: d.count};
    final now = DateTime.now();
    String key(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final counts = [for (var i = 13; i >= 0; i--) byDate[key(now.subtract(Duration(days: i)))] ?? 0];
    final maxCount = counts.fold<int>(0, (a, b) => a > b ? a : b);
    return _StatCardFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Reviews per day',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppPageColors.textPrimaryOf(context)),
          ),
          const SizedBox(height: 12),
          Semantics(
            label: 'Reviews per day, last 14 days: ${counts.join(', ')}',
            child: SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < counts.length; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        height: maxCount == 0 ? 2 : 2 + 118 * counts[i] / maxCount,
                        decoration: BoxDecoration(
                          color: i >= counts.length - 2 ? accent : accent.withValues(alpha: 0.4),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6), bottom: Radius.circular(3)),
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
              Text('2 weeks ago', style: TextStyle(fontSize: 12, color: AppPageColors.subtitleOf(context))),
              Text('Today', style: TextStyle(fontSize: 12, color: AppPageColors.subtitleOf(context))),
            ],
          ),
        ],
      ),
    );
  }
}

/// New · Learning · Young · Mature as one stacked bar with a legend.
class _CardStatesCard extends StatelessWidget {
  const _CardStatesCard({required this.counts});

  final FlashcardCardCounts counts;

  @override
  Widget build(BuildContext context) {
    final young = counts.young;
    final mature = counts.mature;
    final split = young != null && mature != null;
    final parts = <(String, int, Color)>[
      ('New', counts.newCount, BrandConfig.newCards),
      ('Learning', counts.learning, AppColors.orangeHard),
      if (split) ...[
        ('Young', young, AppPageColors.accentOf(context)),
        ('Mature', mature, AppPageColors.tintOf(context, AppTint.success).fg),
      ] else
        ('Review', counts.review, AppPageColors.accentOf(context)),
    ];
    final total = parts.fold<int>(0, (a, p) => a + p.$2);
    return _StatCardFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Card states',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppPageColors.textPrimaryOf(context)),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: SizedBox(
              height: 14,
              child: total == 0
                  ? ColoredBox(color: AppPageColors.subtleBorderOf(context))
                  : Row(
                      // Stretch: an empty ColoredBox is otherwise 0 dp tall.
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final p in parts)
                          if (p.$2 > 0) Expanded(flex: p.$2, child: ColoredBox(color: p.$3)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            runSpacing: 8,
            children: [
              for (final p in parts)
                FractionallySizedBox(
                  widthFactor: 0.5,
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: p.$3, borderRadius: BorderRadius.circular(3)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${p.$1} · ${p.$2}',
                        style: TextStyle(fontSize: 13, color: AppPageColors.textPrimaryOf(context)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
