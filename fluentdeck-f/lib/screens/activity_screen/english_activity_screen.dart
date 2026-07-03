import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/models/speaking_session_record_model.dart';
import 'package:fluentdeck/models/user_note_model.dart';
import 'package:fluentdeck/models/user_progress_model.dart';
import 'package:fluentdeck/localization/app_localizations.dart';
import 'package:fluentdeck/screens/activity_screen/speaking_saved_phrases_screen.dart';
import 'package:fluentdeck/screens/activity_screen/speaking_session_detail_screen.dart';
import 'package:fluentdeck/screens/activity_screen/speaking_session_history_screen.dart';
import 'package:fluentdeck/services/note_service.dart';
import 'package:fluentdeck/services/speaking_session_service.dart';
import 'package:fluentdeck/services/user_progress_service.dart';
import 'package:fluentdeck/ui_elements/app_motion.dart';
import 'package:fluentdeck/ui_elements/app_skeletons.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';
import 'package:fluentdeck/widgets/activity_preview_list.dart';

class EnglishActivityScreen extends StatefulWidget {
  const EnglishActivityScreen({super.key});

  @override
  State<EnglishActivityScreen> createState() => _EnglishActivityScreenState();
}

class _EnglishActivityScreenState extends State<EnglishActivityScreen> {
  bool _loading = true;
  UserProgressModel? _progress;
  List<SpeakingSessionRecord> _history = [];
  List<UserNoteModel> _savedPhrases = [];
  String? _error;

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
      final results = await Future.wait([
        UserProgressService.instance.createIfMissing(),
        SpeakingSessionService.instance.fetchRecent(limit: 50),
        NoteService.instance.fetchNotes(),
      ]);
      final notes = results[2] as List<UserNoteModel>;
      final speakingNotes =
          notes.where((n) => n.source == 'speaking').toList();

      if (!mounted) return;
      setState(() {
        _progress = results[0] as UserProgressModel;
        _history = results[1] as List<SpeakingSessionRecord>;
        _savedPhrases = speakingNotes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = speakingSessionLoadError(context, e);
        _loading = false;
      });
    }
  }

  String _formatSessionTime(DateTime dt) {
    return DateFormat('MMM d, yyyy · h:mm a').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_loading) {
      return const ActivityScreenSkeleton();
    }

    if (_error != null) {
      return AppPageBackground(
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
                FilledButton(
                  onPressed: _load,
                  child: Text(l10n.t('buttons.retry')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final progress = _progress!;
    final topWeak = progress.weakAreas.take(5).toList();
    final topWeakMaxCount = topWeak.isEmpty
        ? 0
        : topWeak.map((e) => e.count).reduce((a, b) => a > b ? a : b);
    final topWeakMaxY = (topWeakMaxCount + 1).toDouble();

    return AppPageBackground(
      child: AppFadeIn(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppColors.primaryPurple,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
            _StreakHero(streakDays: progress.streakDays, l10n: l10n),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    icon: Icons.school_outlined,
                    label: 'Current level',
                    value: progress.currentLevel,
                    color: AppColors.primaryPurple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricTile(
                    icon: Icons.mic_none_rounded,
                    label: 'Speaking time',
                    value: '${progress.totalSpeakingMinutes} min',
                    color: const Color(0xFF2196F3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    icon: Icons.check_circle_outline,
                    label: 'Perfect sentences',
                    value: '${progress.perfectSentencesCount}',
                    color: const Color(0xFF1B9E4B),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricTile(
                    icon: Icons.abc_rounded,
                    label: 'Words used',
                    value: '${progress.uniqueWordsUsed}',
                    color: const Color(0xFFFF9800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _ActivitySection(
              title: l10n.t('speaking-activity.session-history.title'),
              icon: Icons.history_rounded,
              child: _history.isEmpty
                  ? _EmptyHint(
                      text: l10n.t('speaking-activity.session-history.empty'),
                    )
                  : ActivityPreviewList(
                      itemCount: _history.length,
                      itemHeight: 68,
                      itemSpacing: 10,
                      onViewAll: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SpeakingSessionHistoryScreen(),
                          ),
                        );
                      },
                      itemBuilder: (context, index) {
                        final session = _history[index];
                        return _HistoryCard(
                          title: '${session.historyTitle} — ${session.modeLabel}',
                          subtitle: _formatSessionTime(session.completedAt),
                          score: session.score,
                          onTap:
                              () => Navigator.of(context).push(
                                SpeakingSessionDetailScreen.route(session),
                              ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            _ActivitySection(
              title: l10n.t('speaking-activity.saved-phrases.title'),
              icon: Icons.bookmark_outline_rounded,
              child: _savedPhrases.isEmpty
                  ? _EmptyHint(
                      text:
                          'Save corrections from speaking conversations to build your phrase list.',
                    )
                  : ActivityPreviewList(
                      itemCount: _savedPhrases.length,
                      itemHeight: 46,
                      itemSpacing: 8,
                      onViewAll: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SpeakingSavedPhrasesScreen(),
                          ),
                        );
                      },
                      itemBuilder: (context, index) {
                        return _PhraseCard(text: _savedPhrases[index].word);
                      },
                    ),
            ),
            const SizedBox(height: 16),
            _ActivitySection(
              title: 'Top weak areas',
              icon: Icons.insights_outlined,
              child: topWeak.isEmpty
                  ? _EmptyHint(
                      text:
                          'Have a few conversations — your tutor will track patterns here.',
                    )
                  : SizedBox(
                      height: 220,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4, top: 4),
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            minY: 0,
                            maxY: topWeakMaxY,
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 28,
                                  interval: topWeakMaxY <= 5
                                      ? 1
                                      : (topWeakMaxY / 4).ceilToDouble(),
                                  getTitlesWidget: (value, meta) {
                                    if (value < 0 || value > topWeakMaxY) {
                                      return const SizedBox.shrink();
                                    }
                                    if (topWeakMaxY <= 5 &&
                                        value != value.roundToDouble()) {
                                      return const SizedBox.shrink();
                                    }
                                    return Text(
                                      value.toInt().toString(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                      textAlign: TextAlign.right,
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 36,
                                  getTitlesWidget: (value, meta) {
                                    final i = value.toInt();
                                    if (i < 0 || i >= topWeak.length) {
                                      return const SizedBox.shrink();
                                    }
                                    final label = topWeak[i].errorType;
                                    final short = label.length > 10
                                        ? '${label.substring(0, 9)}…'
                                        : label;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        short,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: topWeakMaxY <= 5
                                  ? 1
                                  : (topWeakMaxY / 4).ceilToDouble(),
                              getDrawingHorizontalLine: (_) => FlLine(
                                color: Colors.grey.shade200,
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: [
                              for (var i = 0; i < topWeak.length; i++)
                                BarChartGroupData(
                                  x: i,
                                  barRods: [
                                    BarChartRodData(
                                      toY: topWeak[i].count.toDouble(),
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          AppColors.primaryPurple
                                              .withValues(alpha: 0.75),
                                          AppColors.primaryPurple,
                                        ],
                                      ),
                                      width: 22,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(8),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _StreakHero extends StatelessWidget {
  const _StreakHero({required this.streakDays, required this.l10n});

  final int streakDays;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
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
                  '$streakDays',
                  style: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  streakDays == 1
                      ? l10n.t('speaking-activity.streak.day')
                      : l10n.t('speaking-activity.streak.days'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Keep practicing to grow your streak',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_fire_department_rounded,
              size: 44,
              color: Colors.orange.shade300,
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

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
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

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.title,
    required this.subtitle,
    required this.score,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final int score;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF4FBF6),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.greenCorrect.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.greenCorrect.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.greenCorrect,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.greenCorrect.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$score/10',
              style: const TextStyle(
                color: Color(0xFF1B9E4B),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }
}

class _PhraseCard extends StatelessWidget {
  const _PhraseCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryPurple.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.format_quote_rounded,
            size: 18,
            color: AppColors.primaryPurple.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
