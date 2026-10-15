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
    this.savedWordsValue,
  });

  final AchievementSnapshot snapshot;
  final String displayName;
  final VoidCallback? onViewAchievements;

  /// "12" or "12/50" (free tier limit); hides the tile when null.
  final String? savedWordsValue;

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

    return Column(
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
          LayoutBuilder(
            builder: (context, constraints) {
              final tiles = <Widget>[
                AppMetricTile(
                  icon: Icons.mic_none_rounded,
                  label: 'Speaking',
                  value: '${minutes}m',
                  color: AppColors.brandPrimary,
                ),
                AppMetricTile(
                  icon: Icons.menu_book_outlined,
                  label: 'Unique words',
                  value: '$words',
                  color: const Color(0xFF2196F3),
                ),
                if (savedWordsValue != null)
                  AppMetricTile(
                    icon: Icons.bookmark_outline_rounded,
                    label: 'Saved words',
                    value: savedWordsValue!,
                    color: const Color(0xFFFF9800),
                  ),
                AppMetricTile(
                  icon: Icons.emoji_events_outlined,
                  label: 'Badges',
                  value: '$unlocked/$total',
                  color: AppColors.primaryYellow,
                ),
              ];
              // Four tiles get cramped on phones: use a 2×2 grid there.
              final perRow =
                  tiles.length == 4 && constraints.maxWidth < 520 ? 2 : tiles.length;
              final rows = <Widget>[];
              for (var i = 0; i < tiles.length; i += perRow) {
                final rowTiles = tiles.sublist(i, (i + perRow).clamp(0, tiles.length));
                if (rows.isNotEmpty) rows.add(const SizedBox(height: 10));
                rows.add(
                  Row(
                    children: [
                      for (var j = 0; j < rowTiles.length; j++) ...[
                        if (j > 0) const SizedBox(width: 10),
                        Expanded(child: rowTiles[j]),
                      ],
                    ],
                  ),
                );
              }
              return Column(children: rows);
            },
          ),
      ],
    );
  }
}
