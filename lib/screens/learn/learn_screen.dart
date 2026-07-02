/// Learn Hub Screen
/// Browse, search, and filter lessons/decks
/// Days 8-9 Implementation

import 'package:flutter/material.dart';
import '../../ui_elements/enhanced_design_system.dart';
import '../../ui_elements/design_components.dart';
import 'learn_components.dart';

class LearnScreen extends StatefulWidget {
  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  late TextEditingController _searchController;
  int _selectedLevel = 0;
  String _sortBy = 'recent';

  final List<LessonItem> allLessons = [
    LessonItem(
      title: 'Daily Conversation',
      description: 'Practice real-world dialogue',
      level: 'A1',
      category: 'Speaking',
      cardCount: 24,
      difficulty: 0,
      color: DesignPalette.primary,
    ),
    LessonItem(
      title: 'Grammar Mastery',
      description: 'Master verb tenses',
      level: 'B1',
      category: 'Grammar',
      cardCount: 32,
      difficulty: 1,
      color: DesignPalette.blue,
    ),
    LessonItem(
      title: 'Listening Skills',
      description: 'Understand native speakers',
      level: 'B2',
      category: 'Listening',
      cardCount: 18,
      difficulty: 2,
      color: DesignPalette.warning,
    ),
    LessonItem(
      title: 'Business Spanish',
      description: 'Professional vocabulary',
      level: 'B2',
      category: 'Vocabulary',
      cardCount: 40,
      difficulty: 2,
      color: DesignPalette.success,
    ),
    LessonItem(
      title: 'Idioms & Phrases',
      description: 'Master common expressions',
      level: 'C1',
      category: 'Phrases',
      cardCount: 28,
      difficulty: 3,
      color: DesignPalette.info,
    ),
  ];

  late List<LessonItem> filteredLessons;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filterLessons();
    _searchController.addListener(_filterLessons);
  }

  void _filterLessons() {
    setState(() {
      filteredLessons = allLessons
          .where((lesson) {
            final searchMatch = lesson.title.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ) ||
                lesson.category.toLowerCase().contains(
                      _searchController.text.toLowerCase(),
                    );

            final levelMatch = _selectedLevel == 0 ||
                lesson.difficulty == _selectedLevel - 1;

            return searchMatch && levelMatch;
          })
          .toList();

      // Sort
      if (_sortBy == 'recent') {
        // Keep original order
      } else if (_sortBy == 'difficulty') {
        filteredLessons.sort((a, b) => a.difficulty.compareTo(b.difficulty));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignPalette.bgPrimary,
      body: Column(
        children: [
          // ===== HEADER =====
          SafeArea(
            bottom: false,
            child: Container(
              decoration: BoxDecoration(
                gradient: DesignGradients.primaryGradient,
                boxShadow: DesignShadows.elevation2,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: DesignSpacing.lg,
                vertical: DesignSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Learn',
                    style: DesignTypography.displayMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: DesignSpacing.xs),
                  Text(
                    'Browse lessons by difficulty',
                    style: DesignTypography.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  SizedBox(height: DesignSpacing.md),

                  // ===== SEARCH BAR =====
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search lessons...',
                      prefixIcon: Icon(Icons.search, color: DesignPalette.textSecondary),
                      filled: true,
                      fillColor: DesignPalette.bgTertiary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DesignRadius.md),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: DesignSpacing.md,
                        vertical: DesignSpacing.sm,
                      ),
                    ),
                    style: DesignTypography.bodySmall,
                  ),
                ],
              ),
            ),
          ),

          // ===== FILTER TABS =====
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: DesignSpacing.lg,
              vertical: DesignSpacing.md,
            ),
            child: Row(
              children: [
                PremiumFilterChip(
                  label: 'All Levels',
                  isSelected: _selectedLevel == 0,
                  onSelected: (selected) {
                    setState(() => _selectedLevel = 0);
                    _filterLessons();
                  },
                  icon: Icons.apps,
                ),
                SizedBox(width: DesignSpacing.sm),
                PremiumFilterChip(
                  label: 'A1-A2',
                  isSelected: _selectedLevel == 1,
                  onSelected: (selected) {
                    setState(() => _selectedLevel = 1);
                    _filterLessons();
                  },
                ),
                SizedBox(width: DesignSpacing.sm),
                PremiumFilterChip(
                  label: 'B1-B2',
                  isSelected: _selectedLevel == 2,
                  onSelected: (selected) {
                    setState(() => _selectedLevel = 2);
                    _filterLessons();
                  },
                ),
                SizedBox(width: DesignSpacing.sm),
                PremiumFilterChip(
                  label: 'C1-C2',
                  isSelected: _selectedLevel == 3,
                  onSelected: (selected) {
                    setState(() => _selectedLevel = 3);
                    _filterLessons();
                  },
                ),
              ],
            ),
          ),

          // ===== LESSONS LIST =====
          Expanded(
            child: filteredLessons.isEmpty
                ? EmptyState(
                    title: 'No Lessons Found',
                    description: 'Try adjusting your filters or search',
                    icon: Icons.search_off,
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: DesignSpacing.lg,
                      vertical: DesignSpacing.md,
                    ),
                    itemCount: filteredLessons.length,
                    itemBuilder: (context, index) {
                      final lesson = filteredLessons[index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: DesignSpacing.md),
                        child: _LessonCard(lesson: lesson),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// ============================================================================
// LESSON CARD
// ============================================================================

class _LessonCard extends StatelessWidget {
  final LessonItem lesson;

  const _LessonCard({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return GorgeousCard(
      title: lesson.title,
      subtitle: lesson.description,
      headerColor: lesson.color,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      PremiumBadge(
                        text: lesson.level,
                        backgroundColor: lesson.color,
                        size: 28,
                      ),
                      SizedBox(width: DesignSpacing.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lesson.category,
                            style: DesignTypography.caption,
                          ),
                          Text(
                            '${lesson.cardCount} cards',
                            style: DesignTypography.labelMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Starting ${lesson.title}')),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: lesson.color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignRadius.md),
                  ),
                ),
                child: Icon(Icons.play_arrow, size: 18),
              ),
            ],
          ),
          SizedBox(height: DesignSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignRadius.sm),
            child: LinearProgressIndicator(
              value: 0.0, // Mock data
              minHeight: 4,
              backgroundColor: DesignPalette.bgSecondary,
              valueColor: AlwaysStoppedAnimation(lesson.color),
            ),
          ),
        ],
      ),
    );
  }
}
