import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/models/achievement_model.dart';
import 'package:fluentdeck/services/achievement_service.dart';
import 'package:fluentdeck/ui_elements/app_motion.dart';
import 'package:fluentdeck/ui_elements/loading_overlay.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';
import 'package:fluentdeck/ui_elements/responsive_layout.dart';

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
        title: const Text('Achievements'),
        centerTitle: false,
      ),
      body:
          _loading
              ? const Center(child: LoadingOverlay())
              : RefreshIndicator(
                onRefresh: _load,
                color: AppColors.primaryPurple,
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
    final pct = total == 0 ? 0.0 : unlocked / total;

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
          Text(
            '$unlocked of $total unlocked',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Practice speaking, review cards, and complete lessons to earn badges.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.35),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: AppColors.primaryPurple.withValues(alpha: 0.12),
              color: AppColors.primaryPurple,
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              unlocked
                  ? AppColors.primaryPurple.withValues(alpha: 0.35)
                  : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          if (unlocked)
            BoxShadow(
              color: AppColors.primaryPurple.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
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
                  color:
                      unlocked
                          ? AppColors.primaryPurple.withValues(alpha: 0.12)
                          : Colors.grey.shade100,
                ),
                child: Icon(
                  def.icon,
                  color: unlocked ? AppColors.primaryPurple : Colors.grey.shade400,
                  size: 22,
                ),
              ),
              const Spacer(),
              if (unlocked)
                const Icon(Icons.check_circle, size: 18, color: AppColors.greenCorrect)
              else
                Icon(Icons.lock_outline, size: 16, color: Colors.grey.shade400),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            def.title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: unlocked ? Colors.black87 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              def.description,
              style: TextStyle(
                fontSize: 12,
                height: 1.3,
                color: Colors.grey.shade600,
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
              backgroundColor: Colors.grey.shade200,
              color: unlocked ? AppColors.primaryYellow : AppColors.primaryPurple,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            progressLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
      ),
    );
  }
}
