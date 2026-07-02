/// Phase 1 Showcase - All Beautiful Components
/// Run this to see all components in action

import 'package:flutter/material.dart';
import '../ui_elements/enhanced_design_system.dart';
import '../ui_elements/design_components.dart';

class Phase1Showcase extends StatefulWidget {
  @override
  State<Phase1Showcase> createState() => _Phase1ShowcaseState();
}

class _Phase1ShowcaseState extends State<Phase1Showcase> {
  int _selectedFilter = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FluentDeck - Phase 1 Design Showcase',
      theme: buildDesignTheme(),
      darkTheme: buildDesignTheme(isDark: true),
      themeMode: ThemeMode.light,
      home: Scaffold(
        backgroundColor: DesignPalette.bgPrimary,
        appBar: AppBar(
          title: Text('Phase 1: Design System'),
          subtitle: Text('12 Beautiful Components'),
          elevation: 0,
          backgroundColor: DesignPalette.bgPrimary,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(DesignSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ========== COMPONENT 1: Premium Button ==========
              _SectionHeader('1. Premium Button'),
              SizedBox(height: DesignSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  PremiumButton(
                    label: 'Regular',
                    onPressed: () => _showSnackBar('Button Tapped!'),
                  ),
                  PremiumButton(
                    label: 'Disabled',
                    onPressed: () {},
                    isDisabled: true,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  PremiumButton(
                    label: 'Outlined',
                    onPressed: () {},
                    isOutlined: true,
                  ),
                  PremiumButton(
                    label: 'With Icon',
                    icon: Icons.arrow_forward,
                    onPressed: () {},
                  ),
                ],
              ),
              SizedBox(height: DesignSpacing.xl),

              // ========== COMPONENT 2: Gorgeous Card ==========
              _SectionHeader('2. Gorgeous Card'),
              SizedBox(height: DesignSpacing.md),
              GorgeousCard(
                title: 'Spanish Vocabulary',
                subtitle: '24 cards • 8 due',
                headerColor: DesignPalette.primary,
                child: Column(
                  children: [
                    PremiumProgressBar(value: 0.75, label: 'Progress'),
                    SizedBox(height: DesignSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('75% Complete', style: DesignTypography.bodySmall),
                        PremiumBadge(text: '+50', size: 28),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: DesignSpacing.xl),

              // ========== COMPONENT 3: Animated Progress Ring ==========
              _SectionHeader('3. Animated Progress Ring'),
              SizedBox(height: DesignSpacing.md),
              Center(
                child: AnimatedProgressRing(
                  value: 0.65,
                  size: 120,
                  label: 'Weekly Goal',
                  color: DesignPalette.blue,
                ),
              ),
              SizedBox(height: DesignSpacing.xl),

              // ========== COMPONENT 4: Streak Badge ==========
              _SectionHeader('4. Streak Badge'),
              SizedBox(height: DesignSpacing.md),
              Center(
                child: StreakBadge(
                  count: 15,
                  isAnimating: true,
                  onTap: () => _showSnackBar('Streak Tapped!'),
                ),
              ),
              SizedBox(height: DesignSpacing.xl),

              // ========== COMPONENT 5: XP Display ==========
              _SectionHeader('5. XP Display (Tap Card)'),
              SizedBox(height: DesignSpacing.md),
              GestureDetector(
                onTap: () => _showXPAnimation(context),
                child: GorgeousCard(
                  title: 'Tap to Show XP Animation',
                  child: Center(
                    child: Text(
                      'Tap this card to see XP animation',
                      style: DesignTypography.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              SizedBox(height: DesignSpacing.xl),

              // ========== COMPONENT 6: Premium List Item ==========
              _SectionHeader('6. Premium List Item'),
              SizedBox(height: DesignSpacing.md),
              PremiumListItem(
                title: 'French Grammar',
                subtitle: '18 cards • 5 due',
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: DesignPalette.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(DesignRadius.md),
                  ),
                  child: Icon(Icons.school, color: DesignPalette.blue),
                ),
                trailing: PremiumBadge(text: '5', backgroundColor: DesignPalette.blue),
                onTap: () => _showSnackBar('List Item Tapped!'),
              ),
              SizedBox(height: DesignSpacing.md),
              PremiumListItem(
                title: 'German Phrases',
                subtitle: '32 cards • 12 due',
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: DesignPalette.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(DesignRadius.md),
                  ),
                  child: Icon(Icons.language, color: DesignPalette.success),
                ),
                trailing: PremiumBadge(text: '12', backgroundColor: DesignPalette.success),
                onTap: () => _showSnackBar('List Item Tapped!'),
              ),
              SizedBox(height: DesignSpacing.xl),

              // ========== COMPONENT 7: Filter Chips ==========
              _SectionHeader('7. Premium Filter Chips'),
              SizedBox(height: DesignSpacing.md),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    PremiumFilterChip(
                      label: 'All',
                      icon: Icons.grid_view,
                      isSelected: _selectedFilter == 0,
                      onSelected: (selected) {
                        setState(() => _selectedFilter = 0);
                      },
                    ),
                    SizedBox(width: DesignSpacing.sm),
                    PremiumFilterChip(
                      label: 'Beginner',
                      icon: Icons.star_outline,
                      isSelected: _selectedFilter == 1,
                      onSelected: (selected) {
                        setState(() => _selectedFilter = 1);
                      },
                    ),
                    SizedBox(width: DesignSpacing.sm),
                    PremiumFilterChip(
                      label: 'Advanced',
                      icon: Icons.star,
                      isSelected: _selectedFilter == 2,
                      onSelected: (selected) {
                        setState(() => _selectedFilter = 2);
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: DesignSpacing.xl),

              // ========== COMPONENT 8: Loading Skeleton ==========
              _SectionHeader('8. Loading Skeleton'),
              SizedBox(height: DesignSpacing.md),
              GorgeousCard(
                title: 'Skeletons Loading...',
                child: Column(
                  children: [
                    SkeletonLoader(width: double.infinity, height: 40),
                    SizedBox(height: DesignSpacing.md),
                    SkeletonLoader(width: double.infinity, height: 40),
                    SizedBox(height: DesignSpacing.md),
                    SkeletonLoader(width: double.infinity, height: 40),
                  ],
                ),
              ),
              SizedBox(height: DesignSpacing.xl),

              // ========== COMPONENT 9: Empty State ==========
              _SectionHeader('9. Empty State'),
              SizedBox(height: DesignSpacing.md),
              GorgeousCard(
                title: 'Empty State Example',
                child: EmptyState(
                  title: 'No Decks Yet',
                  description: 'Create your first deck to start learning',
                  icon: Icons.folder_open,
                  buttonLabel: 'Create Deck',
                  onButtonTap: () => _showSnackBar('Create Deck!'),
                ),
              ),
              SizedBox(height: DesignSpacing.xl),

              // ========== COMPONENT 10: Premium Badge ==========
              _SectionHeader('10. Premium Badge'),
              SizedBox(height: DesignSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      PremiumBadge(text: '8', size: 48),
                      SizedBox(height: DesignSpacing.sm),
                      Text('Default', style: DesignTypography.caption),
                    ],
                  ),
                  Column(
                    children: [
                      PremiumBadge(
                        text: '★',
                        backgroundColor: DesignPalette.warning,
                        size: 48,
                      ),
                      SizedBox(height: DesignSpacing.sm),
                      Text('With Icon', style: DesignTypography.caption),
                    ],
                  ),
                  Column(
                    children: [
                      PremiumBadge(
                        text: '12',
                        backgroundColor: DesignPalette.success,
                        size: 48,
                      ),
                      SizedBox(height: DesignSpacing.sm),
                      Text('Custom Color', style: DesignTypography.caption),
                    ],
                  ),
                ],
              ),
              SizedBox(height: DesignSpacing.xl),

              // ========== COMPONENT 11: Premium Progress Bar ==========
              _SectionHeader('11. Premium Progress Bar'),
              SizedBox(height: DesignSpacing.md),
              PremiumProgressBar(
                value: 0.35,
                label: 'Daily Goal',
                color: DesignPalette.blue,
              ),
              SizedBox(height: DesignSpacing.lg),
              PremiumProgressBar(
                value: 0.85,
                label: 'Weekly Target',
                color: DesignPalette.success,
              ),
              SizedBox(height: DesignSpacing.xl),

              // ========== TYPOGRAPHY SHOWCASE ==========
              _SectionHeader('Typography Showcase'),
              SizedBox(height: DesignSpacing.md),
              Text('Display Large (32px)', style: DesignTypography.displayLarge),
              SizedBox(height: DesignSpacing.md),
              Text('Heading Medium (20px)', style: DesignTypography.headingMedium),
              SizedBox(height: DesignSpacing.md),
              Text('Body Large (16px)', style: DesignTypography.bodyLarge),
              SizedBox(height: DesignSpacing.md),
              Text('Caption (12px)', style: DesignTypography.caption),
              SizedBox(height: DesignSpacing.xxl),

              _SectionHeader('Phase 1 Complete! ✅'),
              SizedBox(height: DesignSpacing.md),
              GorgeousCard(
                title: 'Next: Phase 2',
                subtitle: 'Ready for full screens',
                child: Text(
                  'All 12 components are now ready to use in full screens. Next phase will build complete screens using these components.',
                  style: DesignTypography.bodySmall,
                ),
              ),
              SizedBox(height: DesignSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _SectionHeader(String title) {
    return Text(title, style: DesignTypography.headingMedium);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: Duration(milliseconds: 500)),
    );
  }

  void _showXPAnimation(BuildContext context) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 200,
        left: MediaQuery.of(context).size.width / 2 - 50,
        child: XPDisplay(
          xpAmount: 50,
          onComplete: () {},
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(Duration(milliseconds: 1300), () => entry.remove());
  }
}

void main() => runApp(Phase1Showcase());
