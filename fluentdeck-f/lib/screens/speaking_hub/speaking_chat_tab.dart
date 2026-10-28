import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app_colors.dart';
import '../../config/brand_config.dart';
import '../../models/conversation_session_model.dart';
import '../../models/flashcard_model.dart';
import '../../models/speaking_session_context.dart';
import '../../models/speaking_topic_model.dart';
import '../../screens/conversation_screen/conversation_history_screen.dart';
import '../../screens/learn_screen/review_session_screen.dart';
import '../../services/auth_service.dart';
import '../../services/conversation_history_service.dart';
import '../../services/conversation_limit_service.dart';
import '../../services/conversation_service.dart';
import '../../services/flashcard_service.dart';
import '../../services/main_navigation_coordinator.dart';
import '../../services/main_tab_config.dart';
import '../../services/notifications_service.dart';
import '../../services/speaking_content_service.dart';
import '../../ui_elements/app_motion.dart';
import '../../ui_elements/modern_page_widgets.dart';
import '../../utils/practice_time_format.dart';
import '../../utils/strapi_response.dart';
import '../../widgets/rio.dart';

/// Home of the Today tab (Riovox App Redesign · Today · Home): greeting with
/// the streak, today's practice card with one clear way to start, then
/// "Pick up where you left off" and "Talk about…".
class SpeakingChatTab extends StatefulWidget {
  const SpeakingChatTab({super.key, required this.onStart});

  final ValueChanged<SpeakingSessionContext> onStart;

  @override
  State<SpeakingChatTab> createState() => _SpeakingChatTabState();
}

class _SpeakingChatTabState extends State<SpeakingChatTab> {
  ConversationUsageStatus? _usage;
  ConversationSessionModel? _lastChat;
  FlashcardStudyStats? _cards;
  List<SpeakingTopicModel> _topics = const [];
  String? _name;
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _loadUsage();
    _loadShortcuts();
    _loadHeader();
  }

  /// Name, and unread notifications for the bell's dot.
  Future<void> _loadHeader() async {
    try {
      final res = await AuthService.getUser();
      final user = res['user'];
      if (mounted && user is Map) {
        final name = user['username']?.toString().trim();
        setState(() => _name = (name == null || name.isEmpty) ? null : name);
      }
    } catch (_) {}
    try {
      final res = await NotificationsService.getNotifications();
      final list = res['data'] as List? ?? [];
      var count = 0;
      for (final n in list) {
        if (n is! Map) continue;
        if (StrapiResponse.field<bool>(Map<String, dynamic>.from(n), 'read') != true) count += 1;
      }
      if (mounted) setState(() => _unread = count);
    } catch (_) {}
  }

  /// "Pick up where you left off" and "Talk about…": each part is optional
  /// and simply hides when its data can't load.
  Future<void> _loadShortcuts() async {
    final results = await Future.wait<Object?>([
      ConversationHistoryService.instance
          .listSessions()
          .then<Object?>((s) => s.isEmpty ? null : s.first, onError: (_) => null),
      FlashcardService.instance
          .fetchStats()
          .then<Object?>((s) => s, onError: (_) => null),
      SpeakingContentService.instance
          .fetchTopicsCatalog()
          .then<Object?>(
            (c) => c.items.where((t) => !t.isPremiumLocked).take(3).toList(),
            onError: (_) => const <SpeakingTopicModel>[],
          ),
    ]);
    if (!mounted) return;
    setState(() {
      _lastChat = results[0] as ConversationSessionModel?;
      _cards = results[1] as FlashcardStudyStats?;
      _topics = results[2] as List<SpeakingTopicModel>;
    });
  }

  Future<void> _continueChat(ConversationSessionModel session) async {
    await ConversationService.instance.loadSession(session);
    MainNavigationCoordinator.enterSpeakSession();
  }

  Future<void> _refresh() => Future.wait([_loadUsage(), _loadShortcuts(), _loadHeader()]);

  Future<void> _loadUsage() async {
    try {
      final usage = await ConversationLimitService.instance.getStatus();
      if (mounted) setState(() => _usage = usage);
    } catch (_) {
      // The card still works without the meter; the session screen shows it.
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  void _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ConversationHistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final cards = _cards;
    final due = cards?.dueNow ?? 0;
    final showLast = _lastChat != null;
    final showCards = cards != null;

    return AppPageBackground(
      child: RefreshIndicator(
        onRefresh: _refresh,
        edgeOffset: top,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, top + 12, 20, 24),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppStaggeredFadeIn(
                      index: 0,
                      child: _Header(
                        greeting: _greeting,
                        name: _name,
                        streak: cards?.reviewStreakDays,
                        unread: _unread,
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppStaggeredFadeIn(index: 1, child: _Title(name: _name)),
                    const SizedBox(height: 20),
                    AppStaggeredFadeIn(
                      index: 2,
                      child: _TodayCard(
                        usage: _usage,
                        onStart: () => widget.onStart(SpeakingSessionContext.freeChat()),
                      ),
                    ),
                    if (showLast || showCards) ...[
                      const SizedBox(height: 20),
                      AppStaggeredFadeIn(
                        index: 3,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            const Expanded(child: _SectionTitle('Pick up where you left off')),
                            _TextLink(label: 'See all', onTap: _openHistory),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      AppStaggeredFadeIn(
                        index: 4,
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (showLast)
                                Expanded(
                                  child: _ShortcutCard(
                                    icon: Icons.forum_outlined,
                                    tint: AppTint.voice,
                                    title: 'Last conversation',
                                    subtitle: _lastChatPreview(_lastChat!),
                                    onTap: () => _continueChat(_lastChat!),
                                  ),
                                ),
                              if (showLast && showCards) const SizedBox(width: 12),
                              if (showCards)
                                Expanded(
                                  child: _ShortcutCard(
                                    icon: Icons.filter_none_rounded,
                                    tint: AppTint.teal,
                                    title: due == 0
                                        ? 'No cards due'
                                        : '$due card${due == 1 ? '' : 's'} due',
                                    subtitle: due == 0
                                        ? 'Browse your decks'
                                        : 'About ${math.max(1, (due * 20 / 60).ceil())} minute${(due * 20 / 60).ceil() <= 1 ? '' : 's'}',
                                    // Share of today's cards already reviewed.
                                    progress: cards.todayReviews + due == 0
                                        ? 1
                                        : cards.todayReviews / (cards.todayReviews + due),
                                    progressColor: AppPageColors.accentOf(context),
                                    onTap: () => due == 0
                                        ? MainNavigationCoordinator.goToTab(MainTabId.decks)
                                        : Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (_) => const ReviewSessionScreen(),
                                            ),
                                          ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    AppStaggeredFadeIn(index: 5, child: const _SectionTitle('Talk about…')),
                    const SizedBox(height: 20),
                    AppStaggeredFadeIn(
                      index: 6,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final topic in _topics)
                            _TopicChip(
                              label: topic.title,
                              onTap: () => widget.onStart(
                                SpeakingContentService.instance.topicSessionFrom(topic),
                              ),
                            ),
                          _TopicChip(
                            label: '+ Your own',
                            highlighted: true,
                            onTap: () => MainNavigationCoordinator.goToSpeakSubTab('topics'),
                          ),
                        ],
                      ),
                    ),
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

/// Rio, the greeting and name, the streak pill and the bell.
class _Header extends StatelessWidget {
  const _Header({
    required this.greeting,
    required this.name,
    required this.streak,
    required this.unread,
  });

  final String greeting;
  final String? name;
  final int? streak;
  final int unread;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final reward = AppPageColors.tintOf(context, AppTint.reward);
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dark ? AppPageColors.tintOf(context, AppTint.teal).bg : BrandConfig.tealTintStrong,
          ),
          child: Image.asset(RioPose.happy.asset, fit: BoxFit.cover, semanticLabel: 'Rio, your tutor'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: TextStyle(fontSize: 13, color: AppPageColors.subtitleOf(context))),
              if (name != null)
                Text(
                  name!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppPageColors.textPrimaryOf(context),
                  ),
                ),
            ],
          ),
        ),
        if (streak != null) ...[
          Semantics(
            button: true,
            label: '$streak-day streak',
            excludeSemantics: true,
            child: Material(
              color: reward.bg,
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () => MainNavigationCoordinator.goToTab(MainTabId.activity),
                child: SizedBox(
                  height: 44,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department_rounded, size: 18, color: AppColors.primaryYellow),
                        const SizedBox(width: 6),
                        Text(
                          '$streak',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: reward.fg),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Material(
          color: AppPageColors.cardBgOf(context),
          shape: CircleBorder(side: BorderSide(color: AppPageColors.subtleBorderOf(context))),
          child: IconButton(
            tooltip: 'Notifications',
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            padding: EdgeInsets.zero,
            icon: Badge(
              isLabelVisible: unread > 0,
              smallSize: 8,
              child: Icon(Icons.notifications_none_rounded, size: 20, color: AppPageColors.textPrimaryOf(context)),
            ),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
          ),
        ),
      ],
    );
  }
}

/// "Ready to talk," with the name in a teal italic serif under it.
class _Title extends StatelessWidget {
  const _Title({required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontSize: 30,
      height: 1.12,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.6,
      color: AppPageColors.textPrimaryOf(context),
    );
    if (name == null) return Text('Ready to talk?', style: base);
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          const TextSpan(text: 'Ready to talk,\n'),
          TextSpan(
            text: '$name?',
            style: TextStyle(
              fontFamily: 'Instrument Serif',
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w400,
              fontSize: 36,
              letterSpacing: 0,
              color: AppPageColors.accentOf(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.usage, required this.onStart});

  final ConversationUsageStatus? usage;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AppPageColors.accentOf(context);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppPageColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(28),
        border: isDark ? Border.all(color: AppPageColors.subtleBorderOf(context)) : null,
        boxShadow: isDark
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 32, offset: const Offset(0, 12))]
            : [
                BoxShadow(color: BrandConfig.textPrimary.withValues(alpha: 0.06), blurRadius: 2, offset: const Offset(0, 1)),
                BoxShadow(color: AppColors.brandPrimary.withValues(alpha: 0.12), blurRadius: 32, offset: const Offset(0, 12)),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: 150,
                child: Image.asset(
                  'assets/tutor/scene-exploring.webp',
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, 0.2),
                  semanticLabel: 'Rio setting out on a mountain path at sunset',
                ),
              ),
              Positioned(
                left: 14,
                top: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    "Today's practice",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brandPrimaryDeep,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _GoalRow(usage: usage, accent: accent),
                const SizedBox(height: 16),
                _StartButton(onPressed: onStart),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Daily goal ring + "X of Y minutes" from the conversation meter.
class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.usage, required this.accent});

  final ConversationUsageStatus? usage;
  final Color accent;

  /// "3 of 5 minutes" when both are whole minutes; else "45 sec of 5 min".
  static String _ofLabel(int usedSec, int limitSec) {
    if (limitSec % 60 == 0 && limitSec < 3600) {
      final limit = limitSec ~/ 60;
      return '${usedSec ~/ 60} of $limit minute${limit == 1 ? '' : 's'}';
    }
    return '${formatPracticeTime(usedSec)} of ${formatPracticeTime(limitSec)}';
  }

  @override
  Widget build(BuildContext context) {
    final u = usage;
    final hasMeter = u != null && u.hasMeter;
    final exhausted = hasMeter && (!u.allowed || u.remaining <= 0);

    final String title;
    final String detail;
    if (u == null) {
      title = 'Your daily practice';
      detail = 'A few minutes a day builds real fluency';
    } else if (!hasMeter) {
      title = 'Unlimited practice';
      detail = 'Talk as long as you like today';
    } else if (exhausted) {
      title = "Today's time is used";
      detail = 'Great work — it resets at midnight';
    } else {
      title = _ofLabel(u.usedToday, u.dailyLimit);
      detail = '${formatPracticeTime(u.remaining)} left today';
    }

    final track = AppPageColors.tintOf(context, AppTint.teal).bg;
    return Row(
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: Semantics(
            label: title,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: hasMeter ? u.progress : (u == null ? 0 : 1)),
              duration: AppMotion.duration(context, AppMotion.slow),
              curve: AppMotion.decelerateCurve,
              builder: (context, value, _) => CustomPaint(
                painter: _RingPainter(
                  progress: value,
                  color: exhausted ? AppColors.primaryYellow : accent,
                  track: track,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppPageColors.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: TextStyle(fontSize: 14, color: AppPageColors.subtitleOf(context)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color, required this.track});

  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 7.0;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2 + 1.5);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawArc(arcRect, 0, math.pi * 2, false, base);
    if (progress <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2 * progress, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}

/// Teal "Start speaking" button with the coral mic badge (voice = coral).
class _StartButton extends StatelessWidget {
  const _StartButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final accent = AppPageColors.accentOf(context);
    final onAccent = AppPageColors.onAccentOf(context);
    return AppPressScale(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: onAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.voice,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic_rounded, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Start speaking',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _lastChatPreview(ConversationSessionModel session) {
  final userTurns = session.transcript.where((t) => t.isUser).toList();
  final text = (userTurns.isNotEmpty ? userTurns.last : session.transcript.lastOrNull)?.text.trim();
  return (text == null || text.isEmpty) ? 'Continue the chat' : '“$text”';
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppPageColors.textPrimaryOf(context),
      ),
    );
  }
}

class _TextLink extends StatelessWidget {
  const _TextLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: AppPageColors.accentOf(context),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        minimumSize: const Size(44, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }
}

/// White card: tinted icon tile, title, detail and an optional thin bar.
class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.progress,
    this.progressColor,
  });

  final IconData icon;
  final AppTint tint;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final double? progress;
  final Color? progressColor;

  @override
  Widget build(BuildContext context) {
    final colors = AppPageColors.tintOf(context, tint);
    return AppPressScale(
      child: Material(
        color: AppPageColors.cardBgOf(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: AppPageColors.subtleBorderOf(context)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.bg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 20, color: tint == AppTint.voice ? AppColors.voiceDeep : colors.fg),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                    color: AppPageColors.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: AppPageColors.subtitleOf(context)),
                ),
                if (progress != null) ...[
                  const Spacer(),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress!.clamp(0, 1),
                      minHeight: 6,
                      color: progressColor,
                      backgroundColor: AppPageColors.tintOf(context, AppTint.teal).bg,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A "Talk about…" pill; the last one ("+ Your own") is teal.
class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.label, required this.onTap, this.highlighted = false});

  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final tint = AppPageColors.tintOf(context, AppTint.teal);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: highlighted ? tint.bg : AppPageColors.cardBgOf(context),
      shape: StadiumBorder(
        side: BorderSide(
          color: highlighted
              ? (dark ? tint.fg.withValues(alpha: 0.3) : BrandConfig.tealTintStrong)
              : AppPageColors.subtleBorderOf(context),
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: SizedBox(
          height: 40,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              widthFactor: 1,
              child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: highlighted ? FontWeight.w600 : FontWeight.w500,
              color: highlighted ? tint.fg : AppPageColors.textPrimaryOf(context),
            ),
          ),
            ),
          ),
        ),
      ),
    );
  }
}
