import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';

/// Shimmer skeleton for the Decks tab while decks load.
class DecksListSkeleton extends StatelessWidget {
  const DecksListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: AppPageBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          children: [
            Container(
              height: 148,
              decoration: BoxDecoration(
                color: AppColors.brandPrimary,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.all(24),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Bone.text(words: 1, fontSize: 44),
                  SizedBox(height: 8),
                  Bone.text(words: 2, fontSize: 16),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Bone.text(words: 1, fontSize: 17),
            const SizedBox(height: 12),
            for (var i = 0; i < 6; i++) ...[
              Container(
                height: 56,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppPageColors.cardBgOf(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppPageColors.subtleBorderOf(context)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: const Row(
                  children: [
                    Expanded(child: Bone.text(words: 2)),
                    Bone(width: 72, height: 24),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shimmer skeleton for the card browser table/list.
class CardBrowserSkeleton extends StatelessWidget {
  const CardBrowserSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: 10,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Bone.circle(size: 20),
                SizedBox(width: 12),
                Expanded(child: Bone.text(words: 4)),
                SizedBox(width: 12),
                Bone(width: 48, height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Shimmer skeleton for the lessons library tab.
class LessonsListSkeleton extends StatelessWidget {
  const LessonsListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Bone.text(words: 1, fontSize: 14),
                SizedBox(width: 12),
                Bone(width: 56, height: 32),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppPageColors.cardBgOf(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppPageColors.subtleBorderOf(context)),
                  ),
                  child: const Row(
                    children: [
                      Bone.circle(size: 40),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Bone.text(words: 3, fontSize: 16),
                            SizedBox(height: 6),
                            Bone.text(words: 4, fontSize: 13),
                          ],
                        ),
                      ),
                      Bone(width: 24, height: 24),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer skeleton for the Activity tab.
class ActivityScreenSkeleton extends StatelessWidget {
  const ActivityScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: ColoredBox(
        color: AppPageColors.pageBgOf(context),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Container(
              height: 132,
              decoration: BoxDecoration(
                color: AppColors.brandPrimary,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(child: _MetricSkeleton()),
                SizedBox(width: 12),
                Expanded(child: _MetricSkeleton()),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(child: _MetricSkeleton()),
                SizedBox(width: 12),
                Expanded(child: _MetricSkeleton()),
              ],
            ),
            const SizedBox(height: 24),
            const Bone.text(words: 2, fontSize: 17),
            const SizedBox(height: 12),
            for (var i = 0; i < 3; i++) ...[
              Container(
                height: 68,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppPageColors.cardBgOf(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppPageColors.subtleBorderOf(context)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricSkeleton extends StatelessWidget {
  const _MetricSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPageColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPageColors.subtleBorderOf(context)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Bone(width: 28, height: 28),
          SizedBox(height: 10),
          Bone.text(words: 1, fontSize: 20),
          SizedBox(height: 4),
          Bone.text(words: 2, fontSize: 13),
        ],
      ),
    );
  }
}

/// Shell skeleton shown at cold start, before login/route state is known —
/// replaces the branded spinner mark with an outline of the app chrome
/// (top bar, a couple of content blocks, bottom nav) so the launch doesn't
/// read as a dead stop.
class AppLaunchSkeleton extends StatelessWidget {
  const AppLaunchSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  const Bone.circle(size: 32),
                  const SizedBox(width: 12),
                  Expanded(child: const Bone.text(words: 1, fontSize: 18)),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < 3; i++) ...[
                  Container(
                    height: 64,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppPageColors.cardBgOf(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppPageColors.subtleBorderOf(context)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var i = 0; i < 4; i++)
                    const Column(
                      children: [
                        Bone.circle(size: 22),
                        SizedBox(height: 4),
                        Bone(width: 32, height: 8),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer skeleton for Profile → Account while the profile loads.
class ProfileAccountSkeleton extends StatelessWidget {
  const ProfileAccountSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: AppPageBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            Container(
              height: 190,
              decoration: BoxDecoration(
                color: AppColors.brandPrimary,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const SizedBox(height: 16),
            _SectionCardSkeleton(rows: 1),
            const SizedBox(height: 16),
            _SectionCardSkeleton(rows: 4),
            const SizedBox(height: 20),
            const Bone(width: double.infinity, height: 48),
          ],
        ),
      ),
    );
  }
}

/// Shimmer skeleton for a settings-style card (toggle/slider rows), used by
/// Sound settings and similar single-card Profile sub-pages.
///
/// Wraps its content in its own `ListView`, so it needs a bounded-height
/// ancestor (e.g. a `Scaffold` body) — don't use this inside another
/// scrollable. For that case use [AppSectionCardSkeleton] instead.
class ProfileSettingsCardSkeleton extends StatelessWidget {
  const ProfileSettingsCardSkeleton({super.key, this.rows = 2});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: AppPageBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [_SectionCardSkeleton(rows: rows)],
        ),
      ),
    );
  }
}

/// Shrink-wrapped skeleton for a single settings-style card — safe to embed
/// as an item inside another scrollable (e.g. a section within a parent
/// `ListView`), unlike [ProfileSettingsCardSkeleton] which owns its own
/// `ListView` and needs a bounded-height ancestor instead.
class AppSectionCardSkeleton extends StatelessWidget {
  const AppSectionCardSkeleton({super.key, this.rows = 2});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(child: _SectionCardSkeleton(rows: rows));
  }
}

class _SectionCardSkeleton extends StatelessWidget {
  const _SectionCardSkeleton({required this.rows});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppPageColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPageColors.subtleBorderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Bone.circle(size: 20),
              SizedBox(width: 10),
              Bone.text(words: 2, fontSize: 15),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < rows; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            const Bone(width: double.infinity, height: 44),
          ],
        ],
      ),
    );
  }
}

/// Shimmer skeleton for the full achievements grid screen.
class AchievementsScreenSkeleton extends StatelessWidget {
  const AchievementsScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: GridView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.88,
        ),
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppPageColors.cardBgOf(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppPageColors.subtleBorderOf(context)),
            ),
          ),
          for (var i = 0; i < 7; i++)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppPageColors.cardBgOf(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppPageColors.subtleBorderOf(context)),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Bone.circle(size: 44),
                  SizedBox(height: 10),
                  Bone.text(words: 2, fontSize: 13),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Generic shimmer skeleton for a simple row list (icon + title + subtitle) —
/// drop-in replacement for a bare loading spinner on list-style screens that
/// don't warrant a bespoke skeleton of their own.
class AppListSkeleton extends StatelessWidget {
  const AppListSkeleton({
    super.key,
    this.count = 6,
    this.itemHeight = 64,
    this.padding = const EdgeInsets.all(16),
    this.scrollable = true,
  });

  final int count;
  final double itemHeight;
  final EdgeInsetsGeometry padding;

  /// Set to false when embedding this as an item inside another scrollable
  /// (e.g. a parent `ListView`) — renders a shrink-wrapped `Column` instead
  /// of a `ListView`, which would otherwise be given unbounded height.
  final bool scrollable;

  Widget _item(BuildContext context) {
    return Container(
      height: itemHeight,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppPageColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPageColors.subtleBorderOf(context)),
      ),
      child: const Row(
        children: [
          Bone.circle(size: 36),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Bone.text(words: 3, fontSize: 15),
                SizedBox(height: 6),
                Bone.text(words: 2, fontSize: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!scrollable) {
      return Skeletonizer(
        child: Padding(
          padding: padding,
          child: Column(
            children: [
              for (var i = 0; i < count; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                _item(context),
              ],
            ],
          ),
        ),
      );
    }

    return Skeletonizer(
      child: ListView.separated(
        padding: padding,
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _item(context),
      ),
    );
  }
}

/// Generic shimmer skeleton for a tile grid — drop-in for grid-style screens
/// (games, decks) that don't warrant a bespoke skeleton of their own.
class AppGridSkeleton extends StatelessWidget {
  const AppGridSkeleton({
    super.key,
    this.count = 8,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.0,
  });

  final int count;
  final int crossAxisCount;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: GridView(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: childAspectRatio,
        ),
        children: [
          for (var i = 0; i < count; i++)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppPageColors.cardBgOf(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppPageColors.subtleBorderOf(context)),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Bone.circle(size: 36),
                  SizedBox(height: 10),
                  Bone.text(words: 2, fontSize: 13),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Shimmer skeleton for the release notes list.
class ReleaseNotesSkeleton extends StatelessWidget {
  const ReleaseNotesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (var i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Bone.text(words: 2, fontSize: 16),
                  SizedBox(height: 6),
                  Bone.text(words: 1, fontSize: 12),
                  SizedBox(height: 8),
                  Bone.text(words: 5, fontSize: 14),
                  SizedBox(height: 4),
                  Bone.text(words: 4, fontSize: 14),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
