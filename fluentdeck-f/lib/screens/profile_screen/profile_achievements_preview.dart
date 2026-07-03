import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/models/achievement_model.dart';
import 'package:fluentdeck/services/achievement_service.dart';
import 'package:fluentdeck/ui_elements/app_motion.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';

/// Compact achievements row for Profile → Settings (Phase 3).
class ProfileAchievementsPreview extends StatefulWidget {
  const ProfileAchievementsPreview({super.key, required this.onViewAll});

  final VoidCallback onViewAll;

  @override
  State<ProfileAchievementsPreview> createState() =>
      _ProfileAchievementsPreviewState();
}

class _ProfileAchievementsPreviewState extends State<ProfileAchievementsPreview> {
  AchievementSnapshot? _snapshot;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final snapshot = await AchievementService.instance.load();
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }

    final snapshot = _snapshot;
    if (snapshot == null) {
      return Text(
        'Could not load achievements. Pull to refresh later.',
        style: TextStyle(fontSize: 13, color: AppPageColors.subtitleOf(context)),
      );
    }

    final unlocked = snapshot.unlockedCount;
    final total = snapshot.achievements.length;
    final preview = snapshot.achievements.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$unlocked of $total badges unlocked',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            AppScaleTap(
              onTap: widget.onViewAll,
              semanticLabel: 'View all achievements',
              child: const Text(
                'View all',
                style: TextStyle(
                  color: AppColors.primaryPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : unlocked / total,
            minHeight: 6,
            backgroundColor: AppColors.primaryPurple.withValues(alpha: 0.12),
            color: AppColors.primaryPurple,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < preview.length; i++)
              AppStaggeredFadeIn(
                index: i,
                child: _BadgeChip(status: preview[i]),
              ),
          ],
        ),
      ],
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.status});

  final AchievementStatus status;

  @override
  Widget build(BuildContext context) {
    final def = status.definition;
    final unlocked = status.unlocked;

    return Semantics(
      label: '${def.title}, ${unlocked ? "unlocked" : "locked"}',
      child: Container(
        width: 148,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppPageColors.fieldBgOf(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                unlocked
                    ? AppColors.primaryPurple.withValues(alpha: 0.35)
                    : AppPageColors.subtleBorderOf(context),
          ),
        ),
        child: Row(
          children: [
            Icon(
              def.icon,
              size: 20,
              color: unlocked ? AppColors.primaryPurple : Colors.grey.shade400,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                def.title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: unlocked ? null : Colors.grey.shade600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
