import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/models/language_levels_snapshot.dart';
import 'package:fluentdeck/models/speaking_preferences.dart';
import 'package:fluentdeck/models/speaking_session_context.dart';
import 'package:fluentdeck/models/speaking_session_record_model.dart';
import 'package:fluentdeck/models/user_note_model.dart';
import 'package:fluentdeck/models/user_progress_model.dart';
import 'package:fluentdeck/localization/app_localizations.dart';
import 'package:fluentdeck/screens/activity_screen/speaking_saved_phrases_screen.dart';
import 'package:fluentdeck/screens/activity_screen/speaking_session_detail_screen.dart';
import 'package:fluentdeck/screens/activity_screen/speaking_session_history_screen.dart';
import 'package:fluentdeck/services/conversation_service.dart';
import 'package:fluentdeck/services/language_levels_service.dart';
import 'package:fluentdeck/services/note_service.dart';
import 'package:fluentdeck/services/speaking_preferences_service.dart';
import 'package:fluentdeck/services/speaking_session_service.dart';
import 'package:fluentdeck/services/user_progress_service.dart';
import 'package:fluentdeck/ui_elements/app_skeletons.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';
import 'package:fluentdeck/widgets/activity_preview_list.dart';
import 'package:fluentdeck/ui_elements/app_motion.dart';
import 'package:fluentdeck/widgets/tutor_scene.dart';

class EnglishActivityScreen extends StatefulWidget {
  const EnglishActivityScreen({super.key});

  @override
  State<EnglishActivityScreen> createState() => _EnglishActivityScreenState();
}

class _EnglishActivityScreenState extends State<EnglishActivityScreen> {
  bool _loading = true;
  UserProgressModel? _progress;
  LanguageLevelsSnapshot? _languageLevels;
  List<SpeakingSessionRecord> _history = [];
  List<UserNoteModel> _savedPhrases = [];
  SpeakingPreferences _speakingPrefs = const SpeakingPreferences();
  String? _error;
  Timer? _goalSaveDebounce;
  int? _pendingGoal;

  @override
  void initState() {
    super.initState();
    SpeakingPreferencesService.instance.addListener(_onPrefsChanged);
    _load();
  }

  @override
  void dispose() {
    SpeakingPreferencesService.instance.removeListener(_onPrefsChanged);
    if (_goalSaveDebounce?.isActive ?? false) {
      _goalSaveDebounce!.cancel();
      final goal = _pendingGoal;
      final toSave = goal == null
          ? _speakingPrefs
          : SpeakingPreferencesService.instance.current.copyWith(
              correctSentenceGoal: goal,
            );
      SpeakingPreferencesService.instance.saveWithDetails(toSave);
    }
    super.dispose();
  }

  // Lets this screen pick up goal changes made on Profile → Settings'
  // Daily goal slider (and vice versa) while both are mounted.
  void _onPrefsChanged() {
    if (!mounted) return;
    setState(() => _speakingPrefs = SpeakingPreferencesService.instance.current);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        UserProgressService.instance.createIfMissing(),
        LanguageLevelsService.instance.fetch(forceRefresh: true),
        SpeakingSessionService.instance.fetchRecent(limit: 50),
        NoteService.instance.fetchNotes(),
        SpeakingPreferencesService.instance.load(forceRefresh: true),
      ]);
      final notes = results[3] as List<UserNoteModel>;
      final speakingNotes =
          notes.where((n) => n.source == 'speaking').toList();

      if (!mounted) return;
      setState(() {
        _progress = results[0] as UserProgressModel;
        _languageLevels = results[1] as LanguageLevelsSnapshot;
        _history = results[2] as List<SpeakingSessionRecord>;
        _savedPhrases = speakingNotes;
        _speakingPrefs = results[4] as SpeakingPreferences;
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

  // Goal changes come from dragging the gauge ring, which fires on every
  // pointer move — update locally for an instant, responsive drag, but only
  // send the PUT request 2 seconds after the user settles on a value.
  void _onGoalChanged(int goal) {
    // Base the update on the service's latest cached value, not this
    // screen's possibly-stale local copy — see the matching comment in
    // ProfileSettingsSpeakingSection._onGoalSliderChanged.
    final next = SpeakingPreferencesService.instance.current.copyWith(
      correctSentenceGoal: goal,
    );
    setState(() => _speakingPrefs = next);
    SpeakingPreferencesService.instance.updateLocal(next);
    _pendingGoal = goal;
    _goalSaveDebounce?.cancel();
    // Re-read the cache (not `_speakingPrefs`) when the timer fires — see
    // the matching comment in ProfileSettingsSpeakingSection.
    _goalSaveDebounce = Timer(const Duration(seconds: 2), () async {
      _pendingGoal = null;
      final toSave = SpeakingPreferencesService.instance.current.copyWith(
        correctSentenceGoal: goal,
      );
      await SpeakingPreferencesService.instance.saveWithDetails(toSave);
      await ConversationService.instance.refreshSpeakingSettings();
    });
  }

  String _formatSessionTime(DateTime dt) {
    return DateFormat('MMM d, yyyy · h:mm a').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
                Icon(Icons.cloud_off_outlined, size: 48, color: AppPageColors.subtitleOf(context)),
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
    final tutorLevel = _languageLevels?.tutorLevel ?? progress.currentLevel;
    final topWeak = progress.weakAreas.take(5).toList();
    final topWeakMaxCount = topWeak.isEmpty
        ? 0
        : topWeak.map((e) => e.count).reduce((a, b) => a > b ? a : b);
    final topWeakMaxY = (topWeakMaxCount + 1).toDouble();

    return AppLoadingSwitcher(
      loading: false,
      child: AppPageBackground(
      child: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.brandPrimary,
        child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
            _StreakHero(
              streakDays: progress.streakDays,
              l10n: l10n,
              goal: _speakingPrefs.correctSentenceGoal,
              today: _speakingPrefs.correctSentencesToday,
              onGoalChanged: _onGoalChanged,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    icon: Icons.school_outlined,
                    label: 'AI tutor level',
                    value: tutorLevel,
                    color: AppColors.brandPrimary,
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
              title: 'Score trend',
              icon: Icons.show_chart_rounded,
              child: _history.isEmpty
                  ? const _EmptyHint(
                      text: 'Scores from your speaking sessions will chart here.',
                    )
                  : SizedBox(
                      height: 160,
                      child: _ScoreTrendChart(sessions: _history),
                    ),
            ),
            const SizedBox(height: 16),
            _ActivitySection(
              title: 'Daily speaking activity',
              icon: Icons.calendar_today_outlined,
              child: _history.isEmpty
                  ? const _EmptyHint(
                      text: 'Sessions per day will chart here once you start practicing.',
                    )
                  : SizedBox(
                      height: 160,
                      child: _DailyActivityChart(sessions: _history),
                    ),
            ),
            const SizedBox(height: 16),
            _ActivitySection(
              title: 'Practice mix',
              icon: Icons.donut_small_outlined,
              child: _history.isEmpty
                  ? const _EmptyHint(
                      text: 'How you practice (chat, role-play, games…) will chart here.',
                    )
                  : SizedBox(
                      height: 180,
                      child: _PracticeMixDonut(sessions: _history),
                    ),
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
                  ? const _EmptyHint(
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
                  ? const _EmptyHint(
                      text:
                          'Have a few conversations — your tutor will track patterns here.',
                    )
                  : SizedBox(
                      height: 220,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4, top: 4),
                        child: AppChartReveal(
      style: AppChartRevealStyle.up,
      child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            minY: 0,
                            maxY: topWeakMaxY,
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (_) =>
                                    AppColors.brandPrimary.withValues(alpha: 0.9),
                                getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                                    BarTooltipItem(
                                  '${_humanizeErrorType(topWeak[group.x.toInt()].errorType)}\n${rod.toY.toInt()}',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
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
                                        color: AppPageColors.subtitleOf(context),
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
                                    final label =
                                        _humanizeErrorType(topWeak[i].errorType);
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        label,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppPageColors.subtitleOf(context),
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
                                color: AppPageColors.subtleBorderOf(context),
                                strokeWidth: 1,
                                dashArray: [4, 4],
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
                                          AppColors.brandPrimary
                                              .withValues(alpha: 0.75),
                                          AppColors.brandPrimary,
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
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _StreakHero extends StatelessWidget {
  const _StreakHero({
    required this.streakDays,
    required this.l10n,
    required this.goal,
    required this.today,
    required this.onGoalChanged,
  });

  final int streakDays;
  final AppLocalizations l10n;
  final int goal;
  final int today;
  final ValueChanged<int> onGoalChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
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
      child: SceneBackdrop(
        scene: TutorScene.encouraging,
        color: AppColors.heroGradient.last,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
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
          _StreakGaugeIcon(goal: goal, today: today, onGoalChanged: onGoalChanged),
        ],
      ),
        ),
      ),
    );
  }
}

const double _goalGaugeSize = 76;
const int _goalGaugeMin = 1;
const int _goalGaugeMax = 50;

/// Flame icon ringed by a single circular progress bar for the daily
/// correct-sentence goal. The ring fills white as today's correct-sentence
/// count accumulates toward the goal, turning orange/fire once the goal is
/// reached. Press-and-drag anywhere on the ring to set a new goal (synced to
/// the same value shown on Profile → Settings → Daily goal).
class _StreakGaugeIcon extends StatefulWidget {
  const _StreakGaugeIcon({
    required this.goal,
    required this.today,
    required this.onGoalChanged,
  });

  final int goal;
  final int today;
  final ValueChanged<int> onGoalChanged;

  @override
  State<_StreakGaugeIcon> createState() => _StreakGaugeIconState();
}

class _StreakGaugeIconState extends State<_StreakGaugeIcon>
    with SingleTickerProviderStateMixin {
  /// Swell-and-settle when the ring is touched and released.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  /// While true the centre shows the goal being set instead of the flame.
  bool _adjusting = false;

  /// A tap jumps the goal, so the arc sweeps there with a little spring;
  /// dragging updates constantly, so the arc follows the finger closely.
  bool _dragging = false;
  Timer? _settleTimer;

  @override
  void dispose() {
    _settleTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _startPulse() {
    if (MediaQuery.disableAnimationsOf(context)) return;
    _pulse.forward(from: 0);
  }

  void _onDown(Offset localPosition) {
    _settleTimer?.cancel();
    setState(() {
      _adjusting = true;
      _dragging = false;
    });
    _startPulse();
    _handleDrag(localPosition);
  }

  void _onMove(Offset localPosition) {
    if (!_dragging) setState(() => _dragging = true);
    _handleDrag(localPosition);
  }

  void _onUp() {
    _startPulse();
    _settleTimer?.cancel();
    // Show the chosen number for a moment, then fade back to the flame.
    _settleTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _adjusting = false);
    });
  }

  void _handleDrag(Offset localPosition) {
    const center = Offset(_goalGaugeSize / 2, _goalGaugeSize / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    var theta = atan2(dy, dx) + pi / 2;
    if (theta < 0) theta += 2 * pi;
    final fraction = theta / (2 * pi);
    final goal = (fraction * _goalGaugeMax)
        .round()
        .clamp(_goalGaugeMin, _goalGaugeMax);
    if (goal != widget.goal) widget.onGoalChanged(goal);
  }

  @override
  Widget build(BuildContext context) {
    final safeGoal = widget.goal <= 0 ? 1 : widget.goal;
    final reached = widget.today >= safeGoal;
    final targetFraction = (safeGoal / _goalGaugeMax).clamp(0.0, 1.0);
    final progressFraction = (widget.today / _goalGaugeMax).clamp(0.0, 1.0);
    final flameColor = reached ? AppColors.greenCorrect : Colors.orange;

    // A plain GestureDetector's pan recognizer competes with the ancestor
    // ListView's vertical-scroll recognizer in the same gesture arena —
    // dragging around a circle is mostly vertical motion, so the list kept
    // winning that arena and swallowing the drag instead of the ring. A
    // Listener bypasses the arena entirely (raw pointer events always reach
    // it), which is what actually makes dragging reliable here.
    return Listener(
      onPointerDown: (event) => _onDown(event.localPosition),
      onPointerMove: (event) => _onMove(event.localPosition),
      onPointerUp: (_) => _onUp(),
      onPointerCancel: (_) => _onUp(),
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          // 0 → 1 → 0 hump: the ring swells 8% and settles back.
          final swell = sin(pi * _pulse.value);
          return Transform.scale(scale: 1 + 0.08 * swell, child: child);
        },
        child: DualArcProgressRing(
          targetFraction: targetFraction,
          progressFraction: progressFraction,
          size: _goalGaugeSize,
          strokeWidth: 14,
          trackColor: Colors.white.withValues(alpha: 0.15),
          targetColor: const Color(0xFF2196F3),
          progressColor: reached ? AppColors.greenCorrect : Colors.orange.shade300,
          animationDuration: _dragging
              ? const Duration(milliseconds: 120)
              : const Duration(milliseconds: 600),
          animationCurve: _dragging ? AppMotion.decelerateCurve : Curves.easeOutBack,
          center: Padding(
            padding: const EdgeInsets.all(13),
            child: AppFadeThroughSwitcher(
              child: _adjusting
                  ? FittedBox(
                      key: const ValueKey('goal'),
                      child: Text(
                        '$safeGoal',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : AnimatedBuilder(
                      key: const ValueKey('flame'),
                      animation: _pulse,
                      builder: (context, child) => Transform.scale(
                        scale: 1 + 0.25 * sin(pi * _pulse.value),
                        child: child,
                      ),
                      child: TweenAnimationBuilder<Color?>(
                        tween: ColorTween(end: flameColor),
                        duration: AppMotion.duration(context, AppMotion.slow),
                        builder: (context, color, _) => Icon(
                          Icons.local_fire_department_rounded,
                          size: 34,
                          color: color,
                        ),
                      ),
                    ),
            ),
          ),
        ),
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
        color: AppPageColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPageColors.subtleBorderOf(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.04,
            ),
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
              color: AppPageColors.subtitleOf(context),
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
              Icon(icon, size: 20, color: AppPageColors.accentOf(context)),
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
          color: AppPageColors.subtitleOf(context),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark
          ? AppColors.greenCorrect.withValues(alpha: 0.12)
          : const Color(0xFFF4FBF6),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.greenCorrect.withValues(alpha: isDark ? 0.28 : 0.25),
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
                    color: AppPageColors.subtitleOf(context),
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
        color: AppColors.brandPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.brandPrimary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.format_quote_rounded,
            size: 18,
            color: AppColors.brandPrimary.withValues(alpha: 0.6),
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

/// Turns a raw snake_case error-type key (e.g. "article_usage", as stored
/// by the backend) into a readable label (e.g. "Article usage") for the
/// "Top weak areas" chart.
String _humanizeErrorType(String raw) {
  final spaced = raw.replaceAll('_', ' ').trim();
  if (spaced.isEmpty) return spaced;
  return spaced[0].toUpperCase() + spaced.substring(1);
}

String _modeLabel(SpeakingMode mode) {
  switch (mode) {
    case SpeakingMode.chat:
      return 'Chat';
    case SpeakingMode.rolePlay:
      return 'Role-Play';
    case SpeakingMode.topic:
      return 'Topics';
    case SpeakingMode.game:
      return 'Games';
    case SpeakingMode.lesson:
      return 'Lesson';
  }
}

Color _modeColor(SpeakingMode mode) {
  switch (mode) {
    case SpeakingMode.chat:
      return const Color(0xFF4994EC);
    case SpeakingMode.rolePlay:
      return const Color(0xFF7FFB66);
    case SpeakingMode.topic:
      return const Color(0xFFED7249);
    case SpeakingMode.game:
      return const Color(0xFFD52E57);
    case SpeakingMode.lesson:
      return const Color(0xFFF6C543);
  }
}

/// Smooth gradient-area line chart of session scores (0-10) over time.
class _ScoreTrendChart extends StatelessWidget {
  const _ScoreTrendChart({required this.sessions});

  final List<SpeakingSessionRecord> sessions;

  @override
  Widget build(BuildContext context) {
    final ordered = sessions.reversed.toList(); // oldest -> newest
    final recent =
        ordered.length > 20 ? ordered.sublist(ordered.length - 20) : ordered;
    final spots = recent
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.score.toDouble()))
        .toList();
    final labelEvery = (recent.length / 5).ceil().clamp(1, recent.length);

    return AppChartReveal(
      style: AppChartRevealStyle.right,
      child: LineChart(
      LineChartData(
        minX: 0,
        maxX: (recent.length - 1).toDouble(),
        minY: 0,
        maxY: 10,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppPageColors.subtleBorderOf(context), strokeWidth: 1, dashArray: [4, 4]),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: 2,
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
                if (i < 0 || i >= recent.length) return const SizedBox.shrink();
                if (i % labelEvery != 0 && i != recent.length - 1) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormat('MMM d').format(recent[i].completedAt.toLocal()),
                    style: TextStyle(fontSize: 10, color: AppPageColors.subtitleOf(context)),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.greenCorrect.withValues(alpha: 0.9),
            getTooltipItems: (touchedSpots) => touchedSpots
                .map(
                  (spot) => LineTooltipItem(
                    '${spot.y.toInt()}/10',
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
            color: AppColors.greenCorrect,
            barWidth: 3,
            dotData: FlDotData(
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 3,
                color: AppColors.greenCorrect,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.greenCorrect.withValues(alpha: 0.28),
                  AppColors.greenCorrect.withValues(alpha: 0.0),
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

/// Smooth gradient-area line chart of sessions-per-day.
class _DailyActivityChart extends StatelessWidget {
  const _DailyActivityChart({required this.sessions});

  final List<SpeakingSessionRecord> sessions;

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final s in sessions) {
      final key = DateFormat('yyyy-MM-dd').format(s.completedAt.toLocal());
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final days = counts.keys.toList()..sort();
    final series = [
      for (final d in days) (date: DateTime.parse(d), count: counts[d]!),
    ];
    final maxY =
        series.map((e) => e.count).fold<int>(0, (a, b) => a > b ? a : b).toDouble();
    final yInterval = maxY <= 5 ? 1.0 : (maxY / 4).ceilToDouble();
    final labelEvery = (series.length / 5).ceil().clamp(1, series.length);
    final spots = series
        .asMap()
        .entries
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
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppPageColors.subtleBorderOf(context), strokeWidth: 1, dashArray: [4, 4]),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
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
                    DateFormat('MMM d').format(series[i].date),
                    style: TextStyle(fontSize: 10, color: AppPageColors.subtitleOf(context)),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF2196F3).withValues(alpha: 0.9),
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
            color: const Color(0xFF2196F3),
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF2196F3).withValues(alpha: 0.28),
                  const Color(0xFF2196F3).withValues(alpha: 0.0),
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

/// Donut of sessions by practice mode (chat/role-play/topics/games/lesson).
class _PracticeMixDonut extends StatelessWidget {
  const _PracticeMixDonut({required this.sessions});

  final List<SpeakingSessionRecord> sessions;

  @override
  Widget build(BuildContext context) {
    final counts = <SpeakingMode, int>{};
    for (final s in sessions) {
      counts[s.mode] = (counts[s.mode] ?? 0) + 1;
    }
    final total = sessions.length;
    final entries = [
      for (final m in SpeakingMode.values)
        if ((counts[m] ?? 0) > 0) (mode: m, count: counts[m]!),
    ];

    final sections = entries
        .map(
          (e) => PieChartSectionData(
            value: e.count.toDouble(),
            title: '${e.count}',
            color: _modeColor(e.mode),
            radius: 40,
            titlePositionPercentageOffset: 0.62,
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
          child: Stack(
            alignment: Alignment.center,
            children: [
              AppChartReveal(
      style: AppChartRevealStyle.grow,
      child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 36,
                  sections: sections,
                ),
              ),
    ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$total',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    total == 1 ? 'session' : 'sessions',
                    style: TextStyle(fontSize: 11, color: AppPageColors.subtitleOf(context)),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entries
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _modeColor(e.mode),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _modeLabel(e.mode),
                            style: TextStyle(fontSize: 12, color: AppPageColors.subtitleOf(context)),
                          ),
                        ),
                        Text(
                          '${e.count}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
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
