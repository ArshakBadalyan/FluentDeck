import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app_colors.dart';
import '../../models/speaking_session_context.dart';
import '../../services/conversation_limit_service.dart';
import '../../ui_elements/app_motion.dart';
import '../../ui_elements/modern_page_widgets.dart';
import '../../utils/practice_time_format.dart';

/// Home of the Today tab: today's speaking goal and one clear way to start.
class SpeakingChatTab extends StatefulWidget {
  const SpeakingChatTab({super.key, required this.onStart});

  final ValueChanged<SpeakingSessionContext> onStart;

  @override
  State<SpeakingChatTab> createState() => _SpeakingChatTabState();
}

class _SpeakingChatTabState extends State<SpeakingChatTab> {
  ConversationUsageStatus? _usage;

  @override
  void initState() {
    super.initState();
    _loadUsage();
  }

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

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppPageColors.textPrimaryOf(context);
    final subtitle = AppPageColors.subtitleOf(context);

    return AppPageBackground(
      child: RefreshIndicator(
        onRefresh: _loadUsage,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppStaggeredFadeIn(
                      index: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting,
                            style: TextStyle(fontSize: 14, color: subtitle),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ready to talk?',
                            style: TextStyle(
                              fontSize: 28,
                              height: 1.15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    AppStaggeredFadeIn(
                      index: 1,
                      child: _TodayCard(
                        usage: _usage,
                        onStart: () => widget.onStart(SpeakingSessionContext.freeChat()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppStaggeredFadeIn(
                      index: 2,
                      child: Text(
                        'Free conversation with Rio, your AI tutor. Speak naturally '
                        'and get gentle grammar feedback as you go.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, height: 1.45, color: subtitle),
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
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppColors.brandPrimary)
                .withValues(alpha: isDark ? 0.35 : 0.12),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: 170,
                child: Image.asset(
                  'assets/tutor/worldview.webp',
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.2),
                  semanticLabel: 'Rio the otter tutor at a desk with books and a laptop',
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

/// Daily goal ring + "X of Y" from the conversation meter.
class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.usage, required this.accent});

  final ConversationUsageStatus? usage;
  final Color accent;

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
      title =
          '${formatPracticeTime(u.usedToday)} of ${formatPracticeTime(u.dailyLimit)}';
      detail = '${formatPracticeTime(u.remaining)} left today';
    }

    return Row(
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: hasMeter ? u.progress : (u == null ? 0 : 1)),
            duration: AppMotion.duration(context, AppMotion.slow),
            curve: AppMotion.decelerateCurve,
            builder: (context, value, _) => CustomPaint(
              painter: _RingPainter(
                progress: value,
                color: exhausted ? AppColors.primaryYellow : accent,
                track: accent.withValues(alpha: 0.14),
              ),
              child: Center(
                child: Icon(
                  exhausted ? Icons.emoji_events_rounded : Icons.record_voice_over_rounded,
                  size: 22,
                  color: exhausted ? AppColors.primaryYellow : accent,
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
    final arcRect = rect.deflate(stroke / 2);
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
                  color: AppColors.voiceDeep,
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
    );
  }
}
