/// Profile Screen
/// User account, settings, and achievements
/// Phase 3 Implementation

import 'package:flutter/material.dart';
import '../../ui_elements/enhanced_design_system.dart';
import '../../ui_elements/design_components.dart';

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignPalette.bgPrimary,
      body: CustomScrollView(
        slivers: [
          // ===== HEADER WITH PROFILE =====
          SliverAppBar(
            expandedHeight: 200,
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '👤',
                              style: TextStyle(fontSize: 40),
                            ),
                          ),
                        ),
                        SizedBox(height: DesignSpacing.md),
                        Text(
                          'Alex Johnson',
                          style: DesignTypography.headingLarge.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: DesignSpacing.xs),
                        Text(
                          'Intermediate Spanish Learner',
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
                // ===== STATS =====
                Row(
                  children: [
                    Expanded(
                      child: GorgeousCard(
                        title: 'Total XP',
                        headerColor: DesignPalette.primary,
                        child: Text(
                          '12,450',
                          style: DesignTypography.displayMedium,
                        ),
                      ),
                    ),
                    SizedBox(width: DesignSpacing.md),
                    Expanded(
                      child: GorgeousCard(
                        title: 'Decks',
                        headerColor: DesignPalette.blue,
                        child: Text(
                          '12',
                          style: DesignTypography.displayMedium,
                        ),
                      ),
                    ),
                    SizedBox(width: DesignSpacing.md),
                    Expanded(
                      child: GorgeousCard(
                        title: 'Streak',
                        headerColor: DesignPalette.warning,
                        child: Text(
                          '15 🔥',
                          style: DesignTypography.displayMedium,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: DesignSpacing.xl),

                // ===== ACHIEVEMENTS =====
                Text(
                  'Achievements',
                  style: DesignTypography.headingMedium,
                ),
                SizedBox(height: DesignSpacing.md),

                Wrap(
                  spacing: DesignSpacing.md,
                  runSpacing: DesignSpacing.md,
                  children: [
                    Column(
                      children: [
                        PremiumBadge(
                          text: '🏆',
                          backgroundColor: DesignPalette.primary,
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
                    Column(
                      children: [
                        PremiumBadge(
                          text: '🔥',
                          backgroundColor: DesignPalette.warning,
                          size: 56,
                        ),
                        SizedBox(height: DesignSpacing.sm),
                        Text(
                          'Streak\nPro',
                          style: DesignTypography.caption,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: DesignPalette.bgSecondary,
                          ),
                          child: Center(
                            child: Text('?', style: TextStyle(fontSize: 28)),
                          ),
                        ),
                        SizedBox(height: DesignSpacing.sm),
                        Text(
                          'Locked',
                          style: DesignTypography.caption,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: DesignSpacing.xl),

                // ===== SETTINGS =====
                Text(
                  'Settings',
                  style: DesignTypography.headingMedium,
                ),
                SizedBox(height: DesignSpacing.md),

                PremiumListItem(
                  title: 'Dark Mode',
                  subtitle: 'Coming soon',
                  trailing: Icon(Icons.brightness_4),
                ),
                SizedBox(height: DesignSpacing.md),

                PremiumListItem(
                  title: 'Notifications',
                  subtitle: 'Daily reminders enabled',
                  trailing: Icon(Icons.notifications),
                ),
                SizedBox(height: DesignSpacing.md),

                PremiumListItem(
                  title: 'Language',
                  subtitle: 'English',
                  trailing: Icon(Icons.language),
                ),
                SizedBox(height: DesignSpacing.md),

                PremiumListItem(
                  title: 'About',
                  subtitle: 'Version 2.0.0',
                  trailing: Icon(Icons.info),
                ),
                SizedBox(height: DesignSpacing.md),

                PremiumButton(
                  label: 'Sign Out',
                  onPressed: () => _showSignOutDialog(),
                  isOutlined: true,
                ),

                SizedBox(height: DesignSpacing.xxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignRadius.lg),
        ),
        child: Padding(
          padding: EdgeInsets.all(DesignSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Sign Out?', style: DesignTypography.headingMedium),
              SizedBox(height: DesignSpacing.md),
              Text(
                'Are you sure you want to sign out?',
                style: DesignTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: DesignSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: DesignSpacing.md),
                  Expanded(
                    child: PremiumButton(
                      label: 'Sign Out',
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Signed out')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
