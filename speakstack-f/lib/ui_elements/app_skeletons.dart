import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:speakstack/app_colors.dart';
import 'package:speakstack/ui_elements/modern_page_widgets.dart';

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
                color: AppColors.primaryPurple,
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
                  color: AppPageColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black12),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black12),
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
        color: AppPageColors.pageBg,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Container(
              height: 132,
              decoration: BoxDecoration(
                color: AppColors.primaryPurple,
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black12),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
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
