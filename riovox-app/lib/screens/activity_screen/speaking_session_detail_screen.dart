import 'package:flutter/material.dart';
import 'package:riovox/app_colors.dart';
import 'package:riovox/models/grammar_correction.dart';
import 'package:riovox/models/speaking_session_context.dart';
import 'package:intl/intl.dart';
import 'package:riovox/localization/app_localizations.dart';
import 'package:riovox/models/speaking_session_record_model.dart';
import 'package:riovox/routing/app_route_names.dart';
import 'package:riovox/services/conversation_history_service.dart';
import 'package:riovox/services/conversation_service.dart';
import 'package:riovox/services/main_navigation_coordinator.dart';
import 'package:riovox/services/main_tab_config.dart';
import 'package:riovox/ui_elements/app_motion.dart';
import 'package:riovox/ui_elements/modern_page_widgets.dart';
import 'package:riovox/utils/user_facing_api_error.dart';
import 'package:riovox/widgets/rio.dart';

/// Progress · Session result: score ring with the verdict and feedback, the
/// three skills, this chat's corrections, and Practice again.
class SpeakingSessionDetailScreen extends StatelessWidget {
  const SpeakingSessionDetailScreen({
    super.key,
    required this.session,
    this.corrections = const [],
    this.onPracticeAgain,
    this.onDone,
  });

  final SpeakingSessionRecord session;

  /// The corrections from the chat: passed in right after it ends, or found
  /// in this device's chat history when opened from the Sessions list
  /// (the server's session records don't keep them).
  final List<GrammarCorrection> corrections;

  /// Shows "Practice again" (same topic, new chat).
  final VoidCallback? onPracticeAgain;

  /// Shows "Back to Today": leave this result and the chat, to the main menu.
  final VoidCallback? onDone;

  String _whenLabel(BuildContext context) {
    final local = session.completedAt.toLocal();
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(local.year, local.month, local.day))
        .inDays;
    final day = diff == 0
        ? 'Today'
        : diff == 1
        ? 'Yesterday'
        : DateFormat.MMMd(Localizations.localeOf(context).toString()).format(local);
    return session.durationMinutes > 0 ? '$day · ${session.durationMinutes} min' : day;
  }

  @override
  Widget build(BuildContext context) {
    final title = session.title.trim().isNotEmpty ? session.title : session.summary;
    final skills = [
      ('Fluency', session.fluencyScore),
      ('Grammar', session.grammarScore),
      ('Vocabulary', session.vocabularyScore),
    ].where((s) => s.$2 != null).toList();

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
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 20, left: 8),
              child: Text(
                _whenLabel(context),
                style: TextStyle(fontSize: 13, color: AppPageColors.subtitleOf(context)),
              ),
            ),
          ),
        ],
      ),
      body: AppContentWidth(child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          _ScoreHero(score: session.score, feedback: session.feedback),
          if (skills.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                for (var i = 0; i < skills.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  // One after another, each bar filling as it lands.
                  Expanded(
                    child: AppStaggeredFadeIn(
                      index: i + 2,
                      baseDelay: const Duration(milliseconds: 180),
                      child: _SkillBox(
                        label: skills[i].$1,
                        score: skills[i].$2!,
                        delay: Duration(milliseconds: 500 + 180 * i),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
          if (corrections.isNotEmpty) ...[
            const SizedBox(height: 18),
            const _Heading('Corrections'),
            const SizedBox(height: 10),
            for (final (i, c) in corrections.indexed) ...[
              AppStaggeredFadeIn(
                index: i + 4,
                baseDelay: const Duration(milliseconds: 120),
                child: _CorrectionCard(correction: c),
              ),
              const SizedBox(height: 10),
            ],
          ],
          if (session.newWords.isNotEmpty) ...[
            const SizedBox(height: 18),
            const _Heading('New words you used'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (i, word) in session.newWords.indexed)
                  AppStaggeredFadeIn(
                    index: i + 4,
                    baseDelay: const Duration(milliseconds: 120),
                    child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppPageColors.cardBgOf(context),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppPageColors.subtleBorderOf(context)),
                    ),
                    child: Text(
                      word,
                      style: TextStyle(fontSize: 15, color: AppPageColors.textPrimaryOf(context)),
                    ),
                  ),
                  ),
              ],
            ),
          ],
          if (onPracticeAgain != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: onPracticeAgain,
                style: FilledButton.styleFrom(
                  backgroundColor: AppPageColors.accentOf(context),
                  foregroundColor: AppPageColors.onAccentOf(context),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: const Text('Practice again', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
          if (onDone != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: onDone,
                icon: const Icon(Icons.home_rounded),
                label: const Text('Back to Today', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppPageColors.accentOf(context),
                  side: BorderSide(color: AppPageColors.accentOf(context), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
              ),
            ),
          ],
        ],
      )),
    );
  }

  static Route<void> route(SpeakingSessionRecord session) {
    return MaterialPageRoute<void>(
      settings: RouteSettings(
        name: '${AppRouteNames.speakingSessionDetail}/${session.id}',
      ),
      builder: (pageCtx) => FutureBuilder<List<GrammarCorrection>>(
        future: _localCorrections(session),
        builder: (_, snap) => SpeakingSessionDetailScreen(
          session: session,
          corrections: snap.data ?? const [],
          onPracticeAgain: () => _practiceAgain(pageCtx, session),
        ),
      ),
    );
  }

  /// Starts a new chat on the same topic and opens it on Today. Only the
  /// mode, title and topic key are kept with a session, so the tutor gets
  /// the topic by its title.
  static Future<void> _practiceAgain(BuildContext context, SpeakingSessionRecord session) async {
    final ctx = session.mode == SpeakingMode.chat
        ? SpeakingSessionContext.freeChat()
        : SpeakingSessionContext(
            mode: session.mode,
            title: session.title,
            referenceKey: session.referenceKey,
          );
    final service = ConversationService.instance;
    await service.archiveAndStartNew();
    service.startSession(ctx);
    if (!context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    MainNavigationCoordinator.goToTab(MainTabId.speak);
    MainNavigationCoordinator.enterSpeakSession();
  }

  /// The user's corrections from the locally saved chat that ran during
  /// [session] (started between its start, with a few minutes' slack, and its
  /// end). Empty when the chat was on another device or was cleared.
  static Future<List<GrammarCorrection>> _localCorrections(SpeakingSessionRecord session) async {
    try {
      final end = session.completedAt.toLocal();
      final from = end.subtract(Duration(minutes: session.durationMinutes + 5));
      final chats = await ConversationHistoryService.instance.listSessions();
      for (final chat in chats) {
        final started = chat.startedAt.toLocal();
        if (started.isBefore(from) || started.isAfter(end)) continue;
        return [
          for (final turn in chat.transcript)
            if (turn.isUser) ...turn.corrections,
        ];
      }
    } catch (_) {}
    return const [];
  }
}

class _ScoreHero extends StatelessWidget {
  const _ScoreHero({required this.score, required this.feedback});

  final int score;
  final String feedback;

  @override
  Widget build(BuildContext context) {
    final accent = AppPageColors.accentOf(context);
    final value = (score / 10).clamp(0.0, 1.0);
    final verdict = score >= 8
        ? 'Clear and confident'
        : score >= 5
        ? 'Good progress'
        : 'A good start';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppPageColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPageColors.subtleBorderOf(context)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            height: 76,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 1100),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: v,
                    strokeWidth: 9,
                    strokeCap: StrokeCap.round,
                    color: accent,
                    backgroundColor: accent.withValues(alpha: 0.14),
                  ),
                  Center(
                    // Counts up with the ring.
                    child: Text(
                      '${value == 0 ? 0 : (v / value * score).round()}',
                      semanticsLabel: 'Score $score out of 10',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppPageColors.textPrimaryOf(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verdict,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppPageColors.textPrimaryOf(context)),
                ),
                if (feedback.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    feedback.trim(),
                    style: TextStyle(fontSize: 14, height: 1.4, color: AppPageColors.subtitleOf(context)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Rio reacts to the score.
          RioImage(
            score >= 8
                ? RioPose.excited
                : score >= 5
                ? RioPose.happy
                : RioPose.determined,
            height: 72,
            motion: RioMotion.pop,
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppPageColors.textPrimaryOf(context)),
  );
}

/// "I am worry → I am worried" on soft coral, with the why below.
class _CorrectionCard extends StatelessWidget {
  const _CorrectionCard({required this.correction});

  final GrammarCorrection correction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strike = isDark ? const Color(0xFFFF8A80) : const Color(0xFFB42318);
    final better = isDark ? AppColors.greenCorrect : const Color(0xFF0B6B3A);
    final c = correction;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.voice.withValues(alpha: isDark ? 0.10 : 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.voice.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              style: TextStyle(fontSize: 15, height: 1.4, color: AppPageColors.textPrimaryOf(context)),
              children: [
                if (c.originalText.trim().isNotEmpty) ...[
                  TextSpan(
                    text: c.originalText,
                    style: TextStyle(color: strike, decoration: TextDecoration.lineThrough, decorationColor: strike),
                  ),
                  const TextSpan(text: ' → '),
                ],
                TextSpan(text: c.correctedText, style: TextStyle(fontWeight: FontWeight.w700, color: better)),
              ],
            ),
          ),
          if (c.explanation.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(c.explanation, style: TextStyle(fontSize: 13, color: AppPageColors.subtitleOf(context))),
          ],
        ],
      ),
    );
  }
}

String speakingSessionLoadError(BuildContext context, Object error) {
  return AppLocalizations.of(context).t(userFacingErrorLocalizationKey(error));
}

/// One skill (Fluency / Grammar / Vocabulary) as a word plus its 0-10 score:
/// green when strong, orange when it needs work.
class _SkillBox extends StatelessWidget {
  const _SkillBox({required this.label, required this.score, this.delay = Duration.zero});

  final String label;
  final int score;

  /// When the bar starts filling (so the three fill one after another).
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (word, base) = score >= 8
        ? ('Strong', const Color(0xFF2EE66B))
        : score >= 6
        ? ('Good', AppPageColors.accentOf(context))
        : ('Fair', const Color(0xFFFF8F3D));
    final ink = isDark ? base : Color.lerp(base, Colors.black, 0.45)!;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppPageColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPageColors.subtleBorderOf(context)),
      ),
      child: Column(
        children: [
          Text(word, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: ink)),
          const SizedBox(height: 2),
          Text(
            label,
            semanticsLabel: '$label $score out of 10',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppPageColors.subtitleOf(context)),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _fillBar(context, base),
          ),
        ],
      ),
    );
  }

  /// A thin bar that fills to the score after [delay].
  Widget _fillBar(BuildContext context, Color color) {
    final still = MediaQuery.disableAnimationsOf(context);
    const fill = Duration(milliseconds: 700);
    final total = delay + fill;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: (score / 10).clamp(0.0, 1.0)),
      duration: still ? Duration.zero : total,
      curve: still
          ? Curves.linear
          : Interval(delay.inMilliseconds / total.inMilliseconds, 1, curve: Curves.easeOutCubic),
      builder: (context, v, _) => ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(
          value: v,
          minHeight: 5,
          color: color,
          backgroundColor: color.withValues(alpha: 0.15),
        ),
      ),
    );
  }
}
