import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/models/language_levels_snapshot.dart';
import 'package:fluentdeck/services/language_levels_service.dart';
import 'package:fluentdeck/ui_elements/app_skeletons.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';
import 'package:fluentdeck/ui_elements/app_motion.dart';

/// Activity tab: current learning language, AI tutor level, analytics estimate, history.
class LanguageLevelsActivityTab extends StatefulWidget {
  const LanguageLevelsActivityTab({super.key});

  @override
  State<LanguageLevelsActivityTab> createState() =>
      _LanguageLevelsActivityTabState();
}

class _LanguageLevelsActivityTabState extends State<LanguageLevelsActivityTab> {
  bool _loading = true;
  String? _error;
  LanguageLevelsSnapshot? _snapshot;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snapshot = await LanguageLevelsService.instance.fetch(
        forceRefresh: true,
      );
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return AppLoadingSwitcher(
      loading: true,
      child: const ActivityScreenSkeleton(),
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
                Icon(
                  Icons.cloud_off_outlined,
                  size: 48,
                  color: AppPageColors.subtitleOf(context),
                ),
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

    final snapshot = _snapshot!;
    final service = LanguageLevelsService.instance;
    final currentLabel = service.languageLabel(snapshot.practiceLanguage);

    return AppLoadingSwitcher(
      loading: false,
      child: AppPageBackground(
      child: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.brandPrimary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _HeroCard(
              languageLabel: currentLabel,
              estimatedLevel: snapshot.estimatedLevel,
              estimatedLevelStatus: snapshot.estimatedLevelStatus,
              tutorLevel: snapshot.tutorLevel,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    icon: Icons.mic_none_rounded,
                    label: 'Speaking turns',
                    value: '${snapshot.speakingTurns}',
                    color: const Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricTile(
                    icon: Icons.style_outlined,
                    label: 'Deck words',
                    value: '${snapshot.deckWordsReviewed}',
                    color: const Color(0xFFFF9800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _MetricTile(
              icon: Icons.abc_rounded,
              label: 'Unique words spoken',
              value: '${snapshot.uniqueWordsSpoken}',
              color: AppColors.brandPrimary,
              fullWidth: true,
            ),
            const SizedBox(height: 24),
            Builder(
              builder: (context) {
                final current = snapshot.languages.where(
                  (r) => r.languageCode == snapshot.practiceLanguage,
                );
                return _Section(
                  title: 'Language history',
                  icon: Icons.history_rounded,
                  trailing: snapshot.languages.length > 1
                      ? 'All ${snapshot.languages.length}'
                      : null,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LanguageHistoryScreen(snapshot: snapshot),
                    ),
                  ),
                  child: current.isEmpty
                      ? const _EmptyHint(
                          text:
                              'Save notes or practise speaking to build your language history.',
                        )
                      : _LanguageHistoryCard.fromRecord(
                          current.first,
                          languageLabel: service.languageLabel(
                            current.first.languageCode,
                          ),
                          isCurrent: true,
                        ),
                );
              },
            ),
            if (snapshot.levelHistory.isNotEmpty) ...[
              const SizedBox(height: 16),
              _Section(
                title: 'Level timeline (${currentLabel})',
                icon: Icons.timeline_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (snapshot.levelHistory.length >= 2)
                      SizedBox(
                        height: 160,
                        child: _LevelProgressionChart(
                          history: snapshot.levelHistory,
                        ),
                      ),
                    if (snapshot.levelHistory.length >= 2)
                      const SizedBox(height: 14),
                    for (final entry in snapshot.levelHistory.reversed)
                      _TimelineRow(entry: entry),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.languageLabel,
    required this.estimatedLevel,
    required this.estimatedLevelStatus,
    required this.tutorLevel,
  });

  final String languageLabel;

  /// Null when there's no committed AI speaking assessment yet.
  final String? estimatedLevel;
  final String estimatedLevelStatus;
  final String tutorLevel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.heroGradient,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPrimary.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Learning $languageLabel',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            estimatedLevel ?? 'Not enough evidence yet',
            style: TextStyle(
              fontSize: estimatedLevel != null ? 48 : 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            estimatedLevelStatus == 'legacy_unassessed'
                ? 'Keep speaking — your level will be reassessed soon'
                : 'AI-estimated from your speaking practice',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'AI tutor level: $tutorLevel',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.fullWidth = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPageColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPageColors.subtleBorderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppPageColors.subtitleOf(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Every language with real activity (notes, speaking turns, deck reviews).
class LanguageHistoryScreen extends StatelessWidget {
  const LanguageHistoryScreen({super.key, required this.snapshot});

  final LanguageLevelsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final service = LanguageLevelsService.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Language history'),
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: AppPageBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            for (final record in snapshot.languages)
              _LanguageHistoryCard.fromRecord(
                record,
                languageLabel: service.languageLabel(record.languageCode),
                isCurrent: record.languageCode == snapshot.practiceLanguage,
              ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
    this.onTap,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;

  /// Makes the title row open a detail page.
  final VoidCallback? onTap;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final titleRow = Row(
      children: [
        Icon(icon, size: 20, color: AppColors.brandPrimary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.brandPrimary,
            ),
          ),
        if (onTap != null)
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.brandPrimary,
          ),
      ],
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppPageColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPageColors.subtleBorderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onTap == null)
            titleRow
          else
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: titleRow,
              ),
            ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _LanguageHistoryCard extends StatelessWidget {
  _LanguageHistoryCard.fromRecord(
    LanguageLevelRecord record, {
    required this.languageLabel,
    required this.isCurrent,
  }) : tutorLevel = record.tutorLevel,
       estimatedLevel = record.estimatedLevel,
       speakingTurns = record.speakingTurns,
       deckWords = record.deckWordsReviewed,
       noteCount = record.noteCount,
       lastActive = record.lastActiveAt,
       levelHistory = record.levelHistory;

  final String languageLabel;
  final bool isCurrent;
  final String tutorLevel;

  /// Null when there's no committed AI speaking assessment yet.
  final String? estimatedLevel;
  final int speakingTurns;
  final int deckWords;
  final int noteCount;
  final DateTime? lastActive;
  final List<LanguageLevelHistoryEntry> levelHistory;

  @override
  Widget build(BuildContext context) {
    final dateLabel = lastActive != null
        ? DateFormat('MMM d, yyyy').format(lastActive!.toLocal())
        : '—';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppColors.brandPrimary.withValues(alpha: 0.06)
            : AppPageColors.fieldBgOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent
              ? AppColors.brandPrimary.withValues(alpha: 0.2)
              : AppPageColors.subtleBorderOf(context),
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: AppColors.brandPrimary.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                languageLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              if (isCurrent) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Current',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                estimatedLevel ?? 'Not assessed',
                style: TextStyle(
                  fontSize: estimatedLevel != null ? 18 : 12,
                  fontWeight: FontWeight.w800,
                  color: estimatedLevel != null
                      ? null
                      : AppPageColors.subtitleOf(context),
                ),
              ),
            ],
          ),
          if (levelHistory.length >= 2) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 44,
              child: _LevelProgressionChart(
                history: levelHistory,
                compact: true,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'AI tutor $tutorLevel · $noteCount notes · $speakingTurns turns · '
            '$deckWords deck reviews · $dateLabel',
            style: TextStyle(
              fontSize: 12,
              color: AppPageColors.subtitleOf(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.entry});

  final LanguageLevelHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final when = entry.recordedAt != null
        ? DateFormat('MMM d, yyyy').format(entry.recordedAt!.toLocal())
        : '—';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.brandPrimary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            entry.estimatedLevel,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              when,
              style: TextStyle(
                fontSize: 12,
                color: AppPageColors.subtitleOf(context),
              ),
            ),
          ),
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
    return Text(
      text,
      style: TextStyle(
        color: AppPageColors.subtitleOf(context),
        fontSize: 14,
        height: 1.45,
      ),
    );
  }
}

const _cefrLevels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

int _cefrIndex(String level) {
  final i = _cefrLevels.indexOf(level.trim().toUpperCase());
  return i >= 0 ? i : 0;
}

/// CEFR level (A1-C2) over time — a step-like line chart with a gradient
/// area. [compact] hides axes/grid/touch for use inside a small card.
class _LevelProgressionChart extends StatelessWidget {
  const _LevelProgressionChart({required this.history, this.compact = false});

  final List<LanguageLevelHistoryEntry> history;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final points = history.where((e) => e.recordedAt != null).toList();
    if (points.length < 2) return const SizedBox.shrink();

    final spots = points
        .asMap()
        .entries
        .map(
          (e) => FlSpot(
            e.key.toDouble(),
            _cefrIndex(e.value.estimatedLevel).toDouble(),
          ),
        )
        .toList();
    final labelEvery = (points.length / 4).ceil().clamp(1, points.length);

    return AppChartReveal(
      style: AppChartRevealStyle.right,
      child: LineChart(
      LineChartData(
        minX: 0,
        maxX: (points.length - 1).toDouble(),
        minY: 0,
        maxY: (_cefrLevels.length - 1).toDouble(),
        gridData: FlGridData(
          show: !compact,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppPageColors.subtleBorderOf(context), strokeWidth: 1, dashArray: [4, 4]),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: !compact,
              reservedSize: 32,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.round();
                if (i < 0 || i >= _cefrLevels.length) {
                  return const SizedBox.shrink();
                }
                return Text(
                  _cefrLevels[i],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppPageColors.subtitleOf(context),
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: !compact,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.round();
                if (i < 0 || i >= points.length) return const SizedBox.shrink();
                if (i % labelEvery != 0 && i != points.length - 1) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormat('MMM d').format(points[i].recordedAt!.toLocal()),
                    style: TextStyle(fontSize: 10, color: AppPageColors.subtitleOf(context)),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          enabled: !compact,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) =>
                AppColors.brandPrimary.withValues(alpha: 0.95),
            getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
              final i = spot.x.round();
              final level = i >= 0 && i < points.length
                  ? points[i].estimatedLevel
                  : '';
              return LineTooltipItem(
                level,
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: AppColors.brandPrimary,
            barWidth: compact ? 2 : 3,
            dotData: FlDotData(
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: compact ? 2.5 : 4,
                color: AppColors.brandPrimary,
                strokeWidth: 1.5,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.brandPrimary.withValues(alpha: 0.3),
                  AppColors.brandPrimary.withValues(alpha: 0.0),
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
