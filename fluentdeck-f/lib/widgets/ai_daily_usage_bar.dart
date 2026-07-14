import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/services/conversation_limit_service.dart';

/// Compact daily AI speaking meter for the conversation screen.
class AiDailyUsageBar extends StatelessWidget {
  const AiDailyUsageBar({super.key, required this.usage});

  final ConversationUsageStatus usage;

  @override
  Widget build(BuildContext context) {
    if (!usage.hasMeter) return const SizedBox.shrink();

    final progress = usage.progress;
    final remaining = usage.remaining;
    final exhausted = !usage.allowed || remaining <= 0;
    final warn = !exhausted && progress >= 0.75;

    final fillColor =
        exhausted
            ? AppColors.redWrong
            : warn
            ? AppColors.orangeHard
            : AppColors.primaryPurple;

    final title =
        usage.isPremium ? 'Premium practice today' : 'Free practice today';
    final subtitle = _subtitle(exhausted: exhausted, remaining: remaining);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryPurple.withValues(alpha: 0.10),
              AppColors.primaryYellow.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryPurple.withValues(alpha: 0.12),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: fillColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      exhausted
                          ? Icons.hourglass_disabled_rounded
                          : Icons.record_voice_over_rounded,
                      size: 16,
                      color: fillColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1C1B1F),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color:
                                exhausted
                                    ? AppColors.redWrong.withValues(alpha: 0.9)
                                    : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${usage.usedToday}/${usage.dailyLimit}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: fillColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 8,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        color: Colors.black.withValues(alpha: 0.06),
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: value,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    fillColor,
                                    Color.lerp(
                                          fillColor,
                                          AppColors.primaryYellow,
                                          exhausted ? 0 : 0.35,
                                        ) ??
                                        fillColor,
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle({required bool exhausted, required int remaining}) {
    if (exhausted) {
      return 'Daily limit reached · resets at midnight';
    }
    if (!usage.isPremium || usage.premiumDailyLimit <= 0) {
      return '$remaining of ${usage.dailyLimit} turns left';
    }

    final freeLeft =
        (usage.freeDailyLimit - usage.freeUsedToday).clamp(0, usage.freeDailyLimit);
    final premiumLeft =
        (usage.premiumDailyLimit - usage.premiumUsedToday)
            .clamp(0, usage.premiumDailyLimit);

    if (usage.phase == 'free' || freeLeft > 0) {
      return 'Free $freeLeft/${usage.freeDailyLimit} first · then ${usage.premiumDailyLimit} premium';
    }
    return 'Premium $premiumLeft/${usage.premiumDailyLimit} left · $remaining of ${usage.dailyLimit} total';
  }
}
