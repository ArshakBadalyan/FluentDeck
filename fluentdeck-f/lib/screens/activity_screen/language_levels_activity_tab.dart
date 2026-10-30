import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/models/language_levels_snapshot.dart';
import 'package:fluentdeck/models/speaking_preferences.dart';
import 'package:fluentdeck/models/speaking_session_record_model.dart';
import 'package:fluentdeck/services/conversation_service.dart';
import 'package:fluentdeck/services/language_levels_service.dart';
import 'package:fluentdeck/services/milestone_tracker.dart';
import 'package:fluentdeck/services/speaking_preferences_service.dart';
import 'package:fluentdeck/services/speaking_session_service.dart';
import 'package:fluentdeck/ui_elements/app_skeletons.dart';
import 'package:fluentdeck/ui_elements/app_toast.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';
import 'package:fluentdeck/ui_elements/app_motion.dart';
import 'package:fluentdeck/widgets/tutor_scene.dart';

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

  /// Recent speaking sessions, for the week strip; empty if they can't load.
  List<SpeakingSessionRecord> _sessions = const [];

  /// The speaking level just went up: confetti on the hero card, once.
  bool _levelUp = false;

  @override
  void initState() {
    super.initState();
    SpeakingSessionService.instance.savedCount.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    SpeakingSessionService.instance.savedCount.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sessionsFuture = SpeakingSessionService.instance
          .fetchRecent(limit: 50)
          .then<List<SpeakingSessionRecord>>(
            (s) => s,
            onError: (_) => const [],
          );
      final snapshot = await LanguageLevelsService.instance.fetch(
        forceRefresh: true,
      );
      final sessions = await sessionsFuture;
      final levelUp =
          snapshot.hasAssessedLevel &&
          await MilestoneTracker.instance.isLevelUp(
            snapshot.practiceLanguage,
            snapshot.estimatedLevel,
          );
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _sessions = sessions;
        _loading = false;
        _levelUp = levelUp;
      });
      if (levelUp) {
        AppToast.showSnackBar(
          context,
          SnackBar(
            content: Text('Level up! You reached ${snapshot.estimatedLevel}.'),
          ),
        );
      }
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
    final hero = _HeroCard(
      languageLabel: currentLabel,
      estimatedLevel: snapshot.estimatedLevel,
      estimatedLevelStatus: snapshot.estimatedLevelStatus,
      tutorLevel: snapshot.tutorLevel,
    );

    return AppLoadingSwitcher(
      loading: false,
      child: AppPageBackground(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppColors.brandPrimary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              if (_levelUp)
                AppConfettiBurst(
                  colors: const [
                    AppColors.primaryYellow,
                    AppColors.greenCorrect,
                    Colors.white,
                  ],
                  child: hero,
                )
              else
                hero,
              const SizedBox(height: 16),
              _WeekStrip(sessions: _sessions),
              const SizedBox(height: 12),
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
              _JourneySection(snapshot: snapshot),
              const SizedBox(height: 24),
              Builder(
                builder: (context) {
                  final current = snapshot.languages.where(
                    (r) => r.languageCode == snapshot.practiceLanguage,
                  );
                  // Opens Progress · Your languages (switch or add a language).
                  return _Section(
                    title: 'Your languages',
                    icon: Icons.translate_rounded,
                    trailing: 'See all',
                    onTap: () => Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (_) =>
                                LanguageHistoryScreen(snapshot: snapshot),
                          ),
                        )
                        .then((_) => _load()),
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
                  title: 'Level timeline ($currentLabel)',
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
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.heroGradient,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPrimary.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SceneBackdrop(
        // Close-up, centred Rio cheering "you can do it" — reads well in the
        // narrow strip this tall card leaves for the picture.
        scene: TutorScene.encouraging,
        color: AppColors.heroGradient.last,
        widthFactor: 0.5,
        // The text keeps clear of the picture on the right, so it stays
        // readable on narrow phones.
        child: LayoutBuilder(
          builder: (context, c) => Padding(
            padding: EdgeInsets.fromLTRB(
              22,
              22,
              (c.maxWidth * 0.34).clamp(22.0, 220.0),
              22,
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
                  estimatedLevel ?? 'Level coming soon',
                  style: TextStyle(
                    fontSize: estimatedLevel != null ? 48 : 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  estimatedLevel == null
                      ? 'Have a few conversations and Rio will estimate it'
                      : estimatedLevelStatus == 'legacy_unassessed'
                      ? 'Keep speaking — your level will be reassessed soon'
                      : 'AI-estimated from your speaking practice',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
                const SizedBox(height: 14),
                // Kept on the text side so the scene on the right stays clear.
                _CefrBar(level: estimatedLevel ?? tutorLevel),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPageColors.subtleBorderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          AppCountUpText(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppPageColors.subtitleOf(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// Your languages (Progress · Your languages): every language with real
/// activity, the one being learned first with its A1–C2 bar, a way to switch
/// to another, and "+ Add a language".
class LanguageHistoryScreen extends StatefulWidget {
  const LanguageHistoryScreen({super.key, required this.snapshot});

  final LanguageLevelsSnapshot snapshot;

  @override
  State<LanguageHistoryScreen> createState() => _LanguageHistoryScreenState();
}

class _LanguageHistoryScreenState extends State<LanguageHistoryScreen> {
  late String _current = widget.snapshot.practiceLanguage;
  bool _switching = false;

  Future<void> _switchTo(String code) async {
    if (_switching || code == _current) return;
    setState(() => _switching = true);
    final prefs = SpeakingPreferencesService.instance.current;
    // The tutor follows the learning language, as in Settings → Speaking.
    final tutorLanguage =
        SpeakingPreferences.responseLanguageOptions.containsKey(code)
        ? code
        : prefs.responseLanguage;
    final result = await SpeakingPreferencesService.instance.saveWithDetails(
      prefs.copyWith(practiceLanguage: code, responseLanguage: tutorLanguage),
    );
    if (result.ok) await ConversationService.instance.refreshSpeakingSettings();
    if (!mounted) return;
    setState(() {
      _switching = false;
      if (result.ok) _current = code;
    });
    if (!result.ok) {
      AppToast.showSnackBar(
        context,
        SnackBar(
          content: Text(result.errorMessage ?? 'Could not switch language'),
        ),
      );
    }
  }

  Future<void> _addLanguage() async {
    final have = widget.snapshot.languages.map((r) => r.languageCode).toSet();
    final picked = await showAppSelectSheet<String>(
      context: context,
      title: 'Add a language',
      selected: _current,
      options: [
        for (final e in SpeakingPreferences.practiceLanguageOptions.entries)
          if (!have.contains(e.key))
            AppSelectOption(value: e.key, label: e.value),
      ],
    );
    if (picked != null) await _switchTo(picked.value);
  }

  @override
  Widget build(BuildContext context) {
    final service = LanguageLevelsService.instance;
    final records = [...widget.snapshot.languages]
      ..sort(
        (a, b) =>
            (a.languageCode == _current ? 0 : 1) -
            (b.languageCode == _current ? 0 : 1),
      );
    final hasCurrent = records.any((r) => r.languageCode == _current);
    return Scaffold(
      backgroundColor: AppPageColors.pageBgOf(context),
      appBar: AppBar(
        backgroundColor: AppPageColors.pageBgOf(context),
        foregroundColor: AppPageColors.textPrimaryOf(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Your languages',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          if (!hasCurrent)
            _LanguageCard(
              languageLabel: service.languageLabel(_current),
              isCurrent: true,
              level: null,
              tutorLevel: SpeakingPreferencesService.instance.current.englishLevel ?? 'A1',
              speakingSessions: 0,
              deckReviews: 0,
            ),
          for (final record in records)
            _LanguageCard(
              languageLabel: service.languageLabel(record.languageCode),
              isCurrent: record.languageCode == _current,
              level: record.estimatedLevel,
              tutorLevel: record.tutorLevel,
              speakingSessions: record.speakingTurns,
              deckReviews: record.deckWordsReviewed,
              onSwitch: _switching
                  ? null
                  : () => _switchTo(record.languageCode),
            ),
          AppPressScale(
            child: CustomPaint(
              painter: _DashedBorderPainter(
                color: AppPageColors.accentOf(context).withValues(alpha: 0.4),
              ),
              child: Material(
                color: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _switching ? null : _addLanguage,
                  child: SizedBox(
                    height: 56,
                    child: Center(
                      child: Text(
                        '+ Add a language',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppPageColors.accentOf(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded rectangle outline drawn in short dashes.
class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(1),
          const Radius.circular(16),
        ),
      );
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 10) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}

/// One language: name, "Learning now" or a Switch button, then the A1–C2
/// bar once a level is estimated.
class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.languageLabel,
    required this.isCurrent,
    required this.level,
    required this.tutorLevel,
    required this.speakingSessions,
    required this.deckReviews,
    this.onSwitch,
  });

  final String languageLabel;
  final bool isCurrent;

  /// Null when there's no committed AI speaking assessment yet.
  final String? level;

  /// The level Rio talks at; shown on the bar until there's an estimate.
  final String tutorLevel;
  final int speakingSessions;
  final int deckReviews;
  final VoidCallback? onSwitch;

  @override
  Widget build(BuildContext context) {
    final teal = AppPageColors.tintOf(context, AppTint.teal);
    final accent = AppPageColors.accentOf(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      decoration: BoxDecoration(
        color: AppPageColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isCurrent ? accent : AppPageColors.subtleBorderOf(context),
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  languageLabel,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppPageColors.textPrimaryOf(context),
                  ),
                ),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: teal.bg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Learning now',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: teal.fg,
                    ),
                  ),
                )
              else if (level == null)
                Text(
                  'Not assessed yet',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppPageColors.subtitleOf(context),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (level != null) ...[
            _CefrBar(level: level!, onLight: true),
            const SizedBox(height: 12),
            Text(
              'Estimated from $speakingSessions speaking turns · $deckReviews deck reviews',
              style: TextStyle(
                fontSize: 13,
                color: AppPageColors.subtitleOf(context),
              ),
            ),
          ] else if (isCurrent) ...[
            _CefrBar(level: tutorLevel, onLight: true),
            const SizedBox(height: 12),
            Text(
              'Rio talks at $tutorLevel for now · 3 short conversations and Rio will estimate your level',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppPageColors.subtitleOf(context),
              ),
            ),
          ] else
            Text(
              'Have 3 short conversations and Rio will estimate your level.',
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: AppPageColors.subtitleOf(context),
              ),
            ),
          if (!isCurrent) ...[
            const SizedBox(height: 14),
            TextButton(
              onPressed: onSwitch,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                backgroundColor: teal.bg,
                foregroundColor: teal.fg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text('Switch to $languageLabel'),
            ),
          ],
        ],
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
                  if (i < 0 || i >= points.length)
                    return const SizedBox.shrink();
                  if (i % labelEvery != 0 && i != points.length - 1) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateFormat(
                        'MMM d',
                      ).format(points[i].recordedAt!.toLocal()),
                      style: TextStyle(
                        fontSize: 10,
                        color: AppPageColors.subtitleOf(context),
                      ),
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
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
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

/// A1–C2 as six segments, filled up to [level] (on the dark hero card).
class _CefrBar extends StatelessWidget {
  const _CefrBar({required this.level, this.onLight = false});

  final String level;

  /// Teal on a white card instead of white on the dark hero.
  final bool onLight;

  static const _levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

  @override
  Widget build(BuildContext context) {
    final reached = _levels.indexOf(level.trim().toUpperCase());
    final done = onLight ? AppPageColors.accentOf(context) : Colors.white;
    final rest = onLight
        ? AppPageColors.subtleBorderOf(context)
        : Colors.white.withValues(alpha: 0.2);
    final label = onLight
        ? AppPageColors.subtitleOf(context)
        : Colors.white.withValues(alpha: 0.7);
    final labelNow = onLight
        ? AppPageColors.tintOf(context, AppTint.teal).fg
        : Colors.white;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < _levels.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: i < reached
                        ? done
                        : i == reached
                        ? AppColors.brandPrimaryOnDark
                        : rest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < _levels.length; i++)
              Expanded(
                child: Text(
                  _levels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: onLight ? 13 : 11,
                    fontWeight: i == reached
                        ? FontWeight.w800
                        : FontWeight.w500,
                    color: i == reached ? labelNow : label,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// "Rio's journey": milestones from the learner's real activity — done ones
/// ticked, the next one with its progress, the rest locked.
class _JourneySection extends StatelessWidget {
  const _JourneySection({required this.snapshot});

  final LanguageLevelsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final milestones = <(String, int, int, IconData)>[
      ('First conversation', snapshot.speakingTurns, 1, Icons.mic_rounded),
      (
        'Use 50 different words',
        snapshot.uniqueWordsSpoken,
        50,
        Icons.abc_rounded,
      ),
      (
        'Review 20 deck words',
        snapshot.deckWordsReviewed,
        20,
        Icons.style_outlined,
      ),
      (
        '100 speaking turns',
        snapshot.speakingTurns,
        100,
        Icons.record_voice_over_rounded,
      ),
      (
        'Use 300 different words',
        snapshot.uniqueWordsSpoken,
        300,
        Icons.auto_awesome_rounded,
      ),
    ];
    final nextIndex = milestones.indexWhere((m) => m.$2 < m.$3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Rio's journey",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppPageColors.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppPageColors.cardBgOf(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppPageColors.subtleBorderOf(context)),
          ),
          child: Column(
            children: [
              for (var i = 0; i < milestones.length; i++)
                _JourneyRow(
                  title: milestones[i].$1,
                  value: milestones[i].$2,
                  target: milestones[i].$3,
                  icon: milestones[i].$4,
                  state: milestones[i].$2 >= milestones[i].$3
                      ? _JourneyState.done
                      : i == nextIndex
                      ? _JourneyState.current
                      : _JourneyState.locked,
                  showDivider: i < milestones.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _JourneyState { done, current, locked }

class _JourneyRow extends StatelessWidget {
  const _JourneyRow({
    required this.title,
    required this.value,
    required this.target,
    required this.icon,
    required this.state,
    required this.showDivider,
  });

  final String title;
  final int value;
  final int target;
  final IconData icon;
  final _JourneyState state;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final accent = AppPageColors.accentOf(context);
    final subtitle = AppPageColors.subtitleOf(context);
    final Widget badge = switch (state) {
      _JourneyState.done => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.greenCorrect.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          size: 20,
          color: Color(0xFF0B6B3A),
        ),
      ),
      _JourneyState.current => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: accent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: accent.withValues(alpha: 0.18), spreadRadius: 5),
          ],
        ),
        child: Icon(icon, size: 18, color: AppPageColors.onAccentOf(context)),
      ),
      _JourneyState.locked => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppPageColors.subtleBorderOf(context),
            width: 1.5,
          ),
        ),
        child: Icon(Icons.lock_outline_rounded, size: 16, color: subtitle),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: AppPageColors.subtleBorderOf(context),
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          badge,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: state == _JourneyState.locked
                        ? FontWeight.w500
                        : FontWeight.w600,
                    color: state == _JourneyState.locked
                        ? subtitle
                        : AppPageColors.textPrimaryOf(context),
                  ),
                ),
                if (state == _JourneyState.current) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: (value / target).clamp(0.0, 1.0),
                      minHeight: 6,
                      color: accent,
                      backgroundColor: accent.withValues(alpha: 0.14),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (state == _JourneyState.current) ...[
            const SizedBox(width: 12),
            Text(
              '$value / $target',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The "This week" card's data: which local days had a session, this
/// week's Monday, and the streak of consecutive practiced days ending today
/// (or yesterday, if today is still open).
@visibleForTesting
({Set<DateTime> practiced, DateTime today, DateTime monday, int streak})
    speakingWeek(List<SpeakingSessionRecord> sessions, DateTime now) {
  DateTime day(DateTime t) => DateTime(t.year, t.month, t.day);
  final practiced = {for (final s in sessions) day(s.completedAt.toLocal())};
  final today = day(now);
  // Calendar-day steps (not 24 h) so DST changes can't skip a day.
  final monday = DateTime(today.year, today.month, today.day - (today.weekday - 1));
  var streak = 0;
  var cursor = practiced.contains(today)
      ? today
      : DateTime(today.year, today.month, today.day - 1);
  while (practiced.contains(cursor)) {
    streak++;
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
  }
  return (practiced: practiced, today: today, monday: monday, streak: streak);
}

/// This week (Mon–Sun) with a tick on each day that had a speaking session,
/// plus the speaking streak worked out from those same days.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.sessions});

  final List<SpeakingSessionRecord> sessions;

  @override
  Widget build(BuildContext context) {
    final (:practiced, :today, :monday, :streak) =
        speakingWeek(sessions, DateTime.now());

    final accent = AppPageColors.accentOf(context);
    final subtitle = AppPageColors.subtitleOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

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
                  'This week',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppPageColors.textPrimaryOf(context),
                  ),
                ),
              ),
              if (streak > 0) ...[
                const Icon(
                  Icons.local_fire_department_rounded,
                  size: 18,
                  color: AppColors.primaryYellow,
                ),
                const SizedBox(width: 4),
                Text(
                  '$streak-day speaking streak',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.primaryYellow
                        : const Color(0xFF9A6B00),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final day = DateTime(monday.year, monday.month, monday.day + i);
                      final done = practiced.contains(day);
                      final isToday = day == today;
                      final future = day.isAfter(today);
                      return Semantics(
                        label:
                            '${DateFormat.EEEE().format(day)}: ${done
                                ? 'practiced'
                                : future
                                ? 'upcoming'
                                : 'no practice'}',
                        excludeSemantics: true,
                        child: Column(
                          children: [
                            Text(
                              letters[i],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isToday
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                color: isToday
                                    ? AppPageColors.textPrimaryOf(context)
                                    : subtitle,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: done
                                    ? accent
                                    : isToday
                                    ? accent.withValues(alpha: 0.12)
                                    : AppPageColors.subtleBorderOf(context),
                                borderRadius: BorderRadius.circular(12),
                                border: isToday && !done
                                    ? Border.all(color: accent, width: 1.5)
                                    : null,
                              ),
                              child: done
                                  ? Icon(
                                      Icons.check_rounded,
                                      size: 18,
                                      color: AppPageColors.onAccentOf(context),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
