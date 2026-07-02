/// Home Dashboard Screen
/// Phase 2: Day 6-7 Implementation
/// Main learning hub with personalized greeting, streaks, daily goals, and deck carousel

import 'package:flutter/material.dart';
import '../../ui_elements/enhanced_design_system.dart';
import '../../ui_elements/design_components.dart';
import 'home_components.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Mock data
  int streakCount = 15;
  double dailyProgress = 0.65;
  int xpToday = 50;

  final List<DeckItem> decks = [
    DeckItem(
      title: 'Spanish Vocabulary',
      cardCount: 24,
      dueCards: 8,
      progress: 0.75,
      category: 'Vocabulary',
      color: DesignPalette.primary,
    ),
    DeckItem(
      title: 'French Grammar',
      cardCount: 18,
      dueCards: 5,
      progress: 0.50,
      category: 'Grammar',
      color: DesignPalette.blue,
    ),
    DeckItem(
      title: 'German Phrases',
      cardCount: 32,
      dueCards: 12,
      progress: 0.25,
      category: 'Phrases',
      color: DesignPalette.warning,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignPalette.bgPrimary,
      body: CustomScrollView(
        slivers: [
          // ===== HEADER WITH GRADIENT =====
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
                          'Welcome Back, Alex 👋',
                          style: DesignTypography.displayMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: DesignSpacing.xs),
                        Text(
                          'Keep your momentum going',
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
                // ===== TODAY'S GOAL CARD =====
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        DesignPalette.warning.withOpacity(0.1),
                        DesignPalette.warning.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(DesignRadius.md),
                    border: Border.all(
                      color: DesignPalette.bgSecondary,
                      width: 1,
                    ),
                  ),
                  padding: EdgeInsets.all(DesignSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Today's Learning Goal",
                                style: DesignTypography.labelLarge,
                              ),
                              SizedBox(height: DesignSpacing.xs),
                              Text(
                                '5 cards due • ~10 min',
                                style: DesignTypography.bodySmall,
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: DesignSpacing.md,
                              vertical: DesignSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              gradient: DesignGradients.warningGradient,
                              borderRadius: BorderRadius.circular(DesignRadius.full),
                            ),
                            child: Text(
                              '+$xpToday XP',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: DesignSpacing.md),
                      PremiumProgressBar(
                        value: dailyProgress,
                        label: 'Daily Progress',
                        color: DesignPalette.primary,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: DesignSpacing.xl),

                // ===== STATS ROW =====
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: '🔥',
                        title: 'Streak',
                        value: '$streakCount Days',
                        color: DesignPalette.warning,
                      ),
                    ),
                    SizedBox(width: DesignSpacing.md),
                    Expanded(
                      child: _StatCard(
                        icon: '⭐',
                        title: 'This Week',
                        value: '350 XP',
                        color: DesignPalette.blue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: DesignSpacing.xl),

                // ===== YOUR DECKS SECTION =====
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Decks',
                      style: DesignTypography.headingMedium,
                    ),
                    GestureDetector(
                      onTap: () => _showSnackBar('See all decks'),
                      child: Text(
                        'See all',
                        style: TextStyle(
                          color: DesignPalette.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: DesignSpacing.md),

                // ===== DECK CAROUSEL =====
                ...[for (var deck in decks) _DeckCarouselItem(deck: deck)],

                SizedBox(height: DesignSpacing.xl),

                // ===== QUICK ACTIONS =====
                Text(
                  'Quick Actions',
                  style: DesignTypography.headingMedium,
                ),
                SizedBox(height: DesignSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: PremiumButton(
                        label: 'Start Review',
                        icon: Icons.play_arrow,
                        onPressed: () => _showSnackBar('Starting review...'),
                      ),
                    ),
                    SizedBox(width: DesignSpacing.md),
                    Expanded(
                      child: PremiumButton(
                        label: 'Browse',
                        icon: Icons.search,
                        onPressed: () => _showSnackBar('Opening browser...'),
                        isOutlined: true,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: DesignSpacing.xxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(milliseconds: 1000),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ============================================================================
// STAT CARD COMPONENT
// ============================================================================

class _StatCard extends StatelessWidget {
  final String icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(DesignSpacing.lg),
      decoration: BoxDecoration(
        color: DesignPalette.bgTertiary,
        borderRadius: BorderRadius.circular(DesignRadius.md),
        border: Border.all(
          color: DesignPalette.bgSecondary,
          width: 1,
        ),
        boxShadow: DesignShadows.elevation1,
      ),
      child: Column(
        children: [
          Text(icon, style: TextStyle(fontSize: 28)),
          SizedBox(height: DesignSpacing.sm),
          Text(
            title,
            style: DesignTypography.caption,
          ),
          SizedBox(height: DesignSpacing.xs),
          Text(
            value,
            style: DesignTypography.labelLarge,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DECK CAROUSEL ITEM
// ============================================================================

class _DeckCarouselItem extends StatelessWidget {
  final DeckItem deck;

  const _DeckCarouselItem({required this.deck});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignSpacing.md),
      child: GorgeousCard(
        title: deck.title,
        subtitle: '${deck.cardCount} cards • ${deck.dueCards} due',
        headerColor: deck.color,
        child: Column(
          children: [
            PremiumProgressBar(
              value: deck.progress,
              label: 'Progress',
              color: deck.color,
            ),
            SizedBox(height: DesignSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deck.category,
                      style: DesignTypography.caption,
                    ),
                    Text(
                      '${(deck.progress * 100).toStringAsFixed(0)}% Complete',
                      style: DesignTypography.labelMedium,
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Starting ${deck.title}')),
                  ),
                  icon: Icon(Icons.play_arrow, size: 16),
                  label: Text('Study'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: deck.color,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: DesignSpacing.md,
                      vertical: DesignSpacing.sm,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
