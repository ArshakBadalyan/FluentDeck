/// Activity & Statistics Screen
/// Track progress, achievements, and learning stats
/// Day 14 Implementation

import 'package:flutter/material.dart';
import '../../ui_elements/enhanced_design_system.dart';
import '../../ui_elements/design_components.dart';

class ActivityScreen extends StatefulWidget {
  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignPalette.bgPrimary,
      body: CustomScrollView(
        slivers: [
          // ===== HEADER =====
          SliverAppBar(
            expandedHeight: 140,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: DesignGradients.primaryGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: DesignSpacing.lg,
                      vertical: DesignSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Your Progress',
                          style: DesignTypography.displayMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: DesignSpacing.xs),
                        Text(
                          'Week 23 of 2026',
                          style: DesignTypography.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ===== CONTENT =====
          SliverPadding(
            padding: EdgeInsets.all(DesignSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ===== WEEKLY STATS =====
                Row(
                  children: [
                    Expanded(
                      child: GorgeousCard(
                        title: 'This Week',
                        subtitle: 'XP Earned',
                        headerColor: DesignPalette.primary,
                        child: Column(
                          children: [
                            Center(
                              child: AnimatedProgressRing(
                                value: 0.65,
                                size: 80,
                                label: 'of 500 XP',
                                color: DesignPalette.primary,
                              ),
                            ),
                            SizedBox(height: DesignSpacing.md),
                            Text(
                              'Good progress!',
                              style: DesignTypography.caption,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: DesignSpacing.md),
                    Expanded(
                      child: GorgeousCard(
                        title: 'Monthly',
                        subtitle: 'Best Week',
                        headerColor: DesignPalette.success,
                        child: Column(
                          children: [
                            Center(
                              child: Text(
                                '2,450',
                                style: DesignTypography.headingLarge,
                              ),
                            ),
                            SizedBox(height: DesignSpacing.sm),
                            Text(
                              'XP in Week 20',
                              style: DesignTypography.caption,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: DesignSpacing.xl),

                // ===== STREAK & ACHIEVEMENTS =====
                Text(
                  'Achievements',
                  style: DesignTypography.headingMedium,
                ),
                SizedBox(height: DesignSpacing.md),

                GorgeousCard(
                  title: 'Current Achievements',
                  headerColor: DesignPalette.warning,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          StreakBadge(
                            count: 15,
                            isAnimating: false,
                          ),
                          SizedBox(height: DesignSpacing.sm),
                          Text(
                            '15-Day Streak',
                            style: DesignTypography.caption,
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          PremiumBadge(
                            text: '🏆',
                            backgroundColor: DesignPalette.info,
                            size: 56,
                          ),
                          SizedBox(height: DesignSpacing.sm),
                          Text(
                            'Language\nMaster',
                            style: DesignTypography.caption,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          PremiumBadge(
                            text: '⭐',
                            backgroundColor: DesignPalette.success,
                            size: 56,
                          ),
                          SizedBox(height: DesignSpacing.sm),
                          Text(
                            'Quick\nLearner',
                            style: DesignTypography.caption,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: DesignSpacing.xl),

                // ===== LEARNING STATS =====
                Text(
                  'Learning Statistics',
                  style: DesignTypography.headingMedium,
                ),
                SizedBox(height: DesignSpacing.md),

                PremiumListItem(
                  title: 'Total Cards Studied',
                  subtitle: '1,247 cards',
                  leading: Icon(Icons.school, color: DesignPalette.primary),
                  trailing: Text('📊'),
                ),
                SizedBox(height: DesignSpacing.md),

                PremiumListItem(
                  title: 'Average Accuracy',
                  subtitle: '82% correct responses',
                  leading: Icon(Icons.check_circle, color: DesignPalette.success),
                  trailing: Text('✨'),
                ),
                SizedBox(height: DesignSpacing.md),

                PremiumListItem(
                  title: 'Total Study Time',
                  subtitle: '34 hours 22 minutes',
                  leading: Icon(Icons.timer, color: DesignPalette.warning),
                  trailing: Text('⏱️'),
                ),
                SizedBox(height: DesignSpacing.md),

                PremiumListItem(
                  title: 'Decks Completed',
                  subtitle: '12 decks mastered',
                  leading: Icon(Icons.library_books, color: DesignPalette.blue),
                  trailing: Text('📚'),
                ),

                SizedBox(height: DesignSpacing.xxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
