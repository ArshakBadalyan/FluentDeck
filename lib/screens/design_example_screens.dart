/// Example Screens using Design System components
/// Based on SVG structure from task-management template

import 'package:flutter/material.dart';
import '../ui_elements/design_system.dart';

// ============================================================================
// EXAMPLE 1: Home Screen (from home.svg)
// ============================================================================

class DesignHomeScreen extends StatefulWidget {
  @override
  State<DesignHomeScreen> createState() => _DesignHomeScreenState();
}

class _DesignHomeScreenState extends State<DesignHomeScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignColors.bgLight,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 140,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: DesignHeader(
                title: 'Welcome Back',
                subtitle: 'Continue your learning journey',
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Filter Tabs
                DesignFilterTabs(
                  tabs: ['All', 'Recent', 'Completed', 'Favorites'],
                  selectedIndex: _selectedTab,
                  onTabChanged: (index) {
                    setState(() => _selectedTab = index);
                  },
                ),
                SizedBox(height: 16),

                // Featured Card
                DesignCard(
                  title: 'Today\'s Task',
                  subtitle: '3 decks due',
                  headerColor: AppDesignColors.primary,
                  child: Column(
                    children: [
                      DesignProgressBar(value: 0.65),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('65% Complete', style: AppDesignTypography.caption),
                          DesignBadge(text: '+50', size: 28),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                // Section Label
                Text('Your Decks', style: AppDesignTypography.headingMedium),
                SizedBox(height: 12),

                // Deck List Items
                DesignListItem(
                  title: 'Spanish Vocabulary',
                  subtitle: '24 cards • 8 due',
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppDesignColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text('📚', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  trailing: DesignBadge(text: '8', backgroundColor: AppDesignColors.blue),
                  onTap: () {},
                ),
                SizedBox(height: 8),

                DesignListItem(
                  title: 'French Grammar',
                  subtitle: '18 cards • 5 due',
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppDesignColors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text('🎤', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  trailing: DesignBadge(text: '5', backgroundColor: AppDesignColors.blue),
                  onTap: () {},
                ),
                SizedBox(height: 8),

                DesignListItem(
                  title: 'German Phrases',
                  subtitle: '32 cards • 12 due',
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppDesignColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text('📖', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  trailing: DesignBadge(text: '12', backgroundColor: AppDesignColors.blue),
                  onTap: () {},
                ),

                SizedBox(height: 32),

                // Call to Action
                DesignButton(
                  label: 'Start Learning',
                  onPressed: () {},
                ),

                SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 2: Tasks Screen (from today's tasks.svg)
// ============================================================================

class DesignTasksScreen extends StatefulWidget {
  @override
  State<DesignTasksScreen> createState() => _DesignTasksScreenState();
}

class _DesignTasksScreenState extends State<DesignTasksScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignColors.bgLight,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 120,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: DesignHeader(
                title: 'Today\'s Tasks',
                subtitle: 'Keep up with your learning',
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Progress Summary Card
                DesignCard(
                  title: 'Daily Progress',
                  headerColor: AppDesignColors.primary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('5 of 8 completed', style: AppDesignTypography.bodySmall),
                          Text('62%', style: AppDesignTypography.label),
                        ],
                      ),
                      SizedBox(height: 8),
                      DesignProgressBar(value: 0.625),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                // Active Tasks
                Text('Active Tasks', style: AppDesignTypography.headingMedium),
                SizedBox(height: 12),

                DesignListItem(
                  title: 'Spanish Vocabulary Review',
                  subtitle: 'Estimated time: 10 min',
                  leading: DesignBadge(
                    text: '1',
                    backgroundColor: AppDesignColors.primary,
                    size: 36,
                  ),
                  trailing: Icon(Icons.chevron_right, color: AppDesignColors.textSecondary),
                  onTap: () {},
                ),
                SizedBox(height: 8),

                DesignListItem(
                  title: 'Grammar Practice',
                  subtitle: 'Estimated time: 8 min',
                  leading: DesignBadge(
                    text: '2',
                    backgroundColor: AppDesignColors.blue,
                    size: 36,
                  ),
                  trailing: Icon(Icons.chevron_right, color: AppDesignColors.textSecondary),
                  onTap: () {},
                ),
                SizedBox(height: 8),

                DesignListItem(
                  title: 'Speaking Practice',
                  subtitle: 'Estimated time: 5 min',
                  leading: DesignBadge(
                    text: '3',
                    backgroundColor: AppDesignColors.primary,
                    size: 36,
                  ),
                  trailing: Icon(Icons.chevron_right, color: AppDesignColors.textSecondary),
                  onTap: () {},
                ),

                SizedBox(height: 24),

                // Completed Section
                Text('Completed Today', style: AppDesignTypography.headingMedium),
                SizedBox(height: 12),

                DesignListItem(
                  title: 'Listening Exercise',
                  subtitle: 'Completed 2 min ago',
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF46F080),
                    ),
                    child: Icon(Icons.check, color: Colors.white, size: 18),
                  ),
                  backgroundColor: Color(0xFF46F080).withOpacity(0.1),
                ),
                SizedBox(height: 8),

                DesignListItem(
                  title: 'Reading Comprehension',
                  subtitle: 'Completed 15 min ago',
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF46F080),
                    ),
                    child: Icon(Icons.check, color: Colors.white, size: 18),
                  ),
                  backgroundColor: Color(0xFF46F080).withOpacity(0.1),
                ),

                SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 3: Add/Create Screen (from add project.svg)
// ============================================================================

class DesignCreateScreen extends StatefulWidget {
  @override
  State<DesignCreateScreen> createState() => _DesignCreateScreenState();
}

class _DesignCreateScreenState extends State<DesignCreateScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignColors.bgLight,
      appBar: AppBar(
        title: Text('Create New Deck'),
        backgroundColor: AppDesignColors.bgLight,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input Fields
            DesignCard(
              title: 'Deck Information',
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'Deck title',
                      hintStyle: AppDesignTypography.bodySmall,
                      border: InputBorder.none,
                    ),
                  ),
                  Divider(color: AppDesignColors.bgLightPurple),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      hintText: 'Description (optional)',
                      hintStyle: AppDesignTypography.bodySmall,
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Template Selection
            Text('Select Template', style: AppDesignTypography.headingMedium),
            SizedBox(height: 12),

            DesignListItem(
              title: 'Blank Deck',
              subtitle: 'Start from scratch',
              leading: Icon(Icons.note_add, color: AppDesignColors.primary),
              onTap: () {},
            ),
            SizedBox(height: 8),

            DesignListItem(
              title: 'Vocabulary List',
              subtitle: 'Pre-formatted for word pairs',
              leading: Icon(Icons.book, color: AppDesignColors.blue),
              onTap: () {},
            ),
            SizedBox(height: 8),

            DesignListItem(
              title: 'Phrase Builder',
              subtitle: 'Focus on common phrases',
              leading: Icon(Icons.chat_bubble, color: AppDesignColors.primary),
              onTap: () {},
            ),

            Spacer(),

            // Action Buttons
            DesignButton(
              label: 'Create Deck',
              onPressed: () {},
            ),
            SizedBox(height: 12),

            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

// ============================================================================
// DEMO: How to use in your app
// ============================================================================

void main() {
  runApp(
    MaterialApp(
      title: 'FluentDeck Design System',
      theme: designSystemTheme(),
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text('Design Examples'),
            bottom: TabBar(
              tabs: [
                Tab(text: 'Home'),
                Tab(text: 'Tasks'),
                Tab(text: 'Create'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              DesignHomeScreen(),
              DesignTasksScreen(),
              DesignCreateScreen(),
            ],
          ),
        ),
      ),
    ),
  );
}
