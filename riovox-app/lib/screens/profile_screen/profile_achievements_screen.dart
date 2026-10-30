import 'package:flutter/material.dart';
import 'package:riovox/app_colors.dart';
import 'package:riovox/models/achievement_model.dart';
import 'package:riovox/services/achievement_service.dart';
import 'package:riovox/ui_elements/app_motion.dart';
import 'package:riovox/ui_elements/app_skeletons.dart';
import 'package:riovox/ui_elements/modern_page_widgets.dart';
import 'package:riovox/ui_elements/responsive_layout.dart';

/// Full achievement grid with progress (Phase 3).
class ProfileAchievementsScreen extends StatefulWidget {
  const ProfileAchievementsScreen({super.key});

  @override
  State<ProfileAchievementsScreen> createState() =>
      _ProfileAchievementsScreenState();
}

class _ProfileAchievementsScreenState extends State<ProfileAchievementsScreen> {
  AchievementSnapshot? _snapshot;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final snapshot = await AchievementService.instance.load();
    if (!mounted) return;
    setState(() {
      _snapshot = snapshot;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPageColors.pageBgOf(context),
      appBar: AppBar(
        // Light header on the page background, like the main tabs.
        backgroundColor: AppPageColors.pageBgOf(context),
        foregroundColor: AppPageColors.textPrimaryOf(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Achievements'),
        centerTitle: false,
      ),
      body:
          _loading
              ? const AchievementsScreenSkeleton()
              : RefreshIndicator(
                onRefresh: _load,
                color: AppColors.brandPrimary,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      sliver: SliverMainAxisGroup(
                        slivers: [
                          if (_snapshot != null)
                            SliverToBoxAdapter(
                              child: AppFadeIn(
                                child: _SummaryBanner(snapshot: _snapshot!),
                              ),
                            ),
                          SliverPadding(
                            padding: const EdgeInsets.only(top: 16),
                            sliver: SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: ResponsiveContent.gridCrossAxisCount(
                                      context,
                                    ),
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 0.88,
                                  ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final status = _snapshot!.achievements[index];
                                  return AppStaggeredFadeIn(
                                    index: index,
                                    child: _AchievementTile(status: status),
                                  );
                                },
                                childCount: _snapshot?.achievements.length ?? 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({required this.snapshot});

  final AchievementSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final unlocked = snapshot.unlockedCount;
    final total = snapshot.achievements.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // The closest badge still locked is the one to chase next.
    final locked = snapshot.achievements.where((a) => !a.unlocked).toList()
      ..sort((a, b) => b.progress.compareTo(a.progress));
    final next = locked.isEmpty ? null : locked.first;
    final ink = isDark ? AppColors.primaryYellow : const Color(0xFF6B5300);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryYellow.withValues(alpha: isDark ? 0.14 : 0.18),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.primaryYellow,
              shape: BoxShape.circle,
            ),
            child: Icon(
              next?.definition.icon ?? Icons.emoji_events_rounded,
              color: const Color(0xFF1A1400),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  next == null ? 'All $total badges earned' : 'Next: ${next.definition.title}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppPageColors.textPrimaryOf(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  next == null
                      ? 'Amazing work.'
                      : '${next.current} of ${next.definition.target} · $unlocked of $total unlocked',
                  style: TextStyle(fontSize: 13, color: ink),
                ),
                if (next != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: next.progress,
                      minHeight: 6,
                      backgroundColor: AppColors.primaryYellow.withValues(alpha: 0.3),
                      color: AppColors.primaryYellow,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.status});

  final AchievementStatus status;

  @override
  Widget build(BuildContext context) {
    final def = status.definition;
    final unlocked = status.unlocked;
    final progressLabel = '${status.current}/${def.target}';

    return Semantics(
      label: '${def.title}, ${unlocked ? "unlocked" : "locked"}, $progressLabel',
      child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPageColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPageColors.subtleBorderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // Earned badges are gold medals (yellow = rewards only).
                  color:
                      unlocked
                          ? AppColors.primaryYellow
                          : AppPageColors.fieldBgOf(context),
                ),
                child: Icon(
                  def.icon,
                  color: unlocked ? const Color(0xFF1A1400) : AppPageColors.subtitleOf(context),
                  size: 22,
                ),
              ),
              const Spacer(),
              if (unlocked)
                const Icon(Icons.check_circle, size: 18, color: AppColors.greenCorrect)
              else
                Icon(Icons.lock_outline, size: 16, color: AppPageColors.subtitleOf(context)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            def.title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: unlocked ? AppPageColors.textPrimaryOf(context) : AppPageColors.subtitleOf(context),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              def.description,
              style: TextStyle(
                fontSize: 12,
                height: 1.3,
                color: AppPageColors.subtitleOf(context),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: status.progress,
              minHeight: 5,
              backgroundColor: AppPageColors.subtleBorderOf(context),
              color: unlocked ? AppColors.primaryYellow : AppColors.brandPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            progressLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppPageColors.subtitleOf(context),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
