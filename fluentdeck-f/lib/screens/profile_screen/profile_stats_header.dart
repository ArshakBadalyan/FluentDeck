import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/services/achievement_service.dart';
import 'package:fluentdeck/ui_elements/app_motion.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';

/// Progress summary shown at the top of the Account tab (Phase 3).
class ProfileStatsHeader extends StatelessWidget {
  const ProfileStatsHeader({
    super.key,
    required this.snapshot,
    required this.displayName,
    this.onViewAchievements,
  });

  final AchievementSnapshot snapshot;
  final String displayName;
  final VoidCallback? onViewAchievements;

  String get _nameLabel {
    final trimmed = displayName.trim();
    return trimmed.isEmpty ? 'Your progress' : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final progress = snapshot.progress;
    final streak = progress?.streakDays ?? 0;
    final minutes = progress?.totalSpeakingMinutes ?? 0;
    final words = progress?.uniqueWordsUsed ?? 0;
    final unlocked = snapshot.unlockedCount;
    final total = snapshot.achievements.length;

    return AppFadeIn(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppHeroCard(
            value: '$streak',
            label: _nameLabel,
            subtitle:
                streak > 0
                    ? 'Day practice streak — keep it going'
                    : 'Start speaking or reviewing to build a streak',
            icon: Icons.local_fire_department_rounded,
            badge:
                unlocked > 0
                    ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryYellow.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$unlocked of $total achievements',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    )
                    : null,
            action:
                onViewAchievements == null
                    ? null
                    : AppScaleTap(
                      onTap: onViewAchievements,
                      semanticLabel: 'View achievements',
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'View achievements',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppMetricTile(
                  icon: Icons.mic_none_rounded,
                  label: 'Speaking',
                  value: '${minutes}m',
                  color: AppColors.primaryPurple,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppMetricTile(
                  icon: Icons.menu_book_outlined,
                  label: 'Unique words',
                  value: '$words',
                  color: const Color(0xFF2196F3),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppMetricTile(
                  icon: Icons.emoji_events_outlined,
                  label: 'Badges',
                  value: '$unlocked/$total',
                  color: AppColors.primaryYellow,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
