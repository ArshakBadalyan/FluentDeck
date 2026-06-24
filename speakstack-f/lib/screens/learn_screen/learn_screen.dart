import 'package:flutter/material.dart';
import 'package:untitled2/app_colors.dart';
import 'package:untitled2/screens/learn_screen/flashcards_screen.dart';
import 'package:untitled2/screens/learn_screen/notes_screen.dart';
import 'package:untitled2/screens/learn_screen/words_screen.dart';

class LearnComingSoonTab extends StatelessWidget {
  const LearnComingSoonTab({
    super.key,
    required this.title,
    required this.phaseLabel,
    required this.icon,
  });

  final String title;
  final String phaseLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.primaryPurple.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              phaseLabel,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 2);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primaryPurple,
            unselectedLabelColor: const Color(0xFF777481),
            indicatorColor: AppColors.primaryPurple,
            tabs: const [
              Tab(text: 'Words'),
              Tab(text: 'My Notes'),
              Tab(text: 'Decks'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              WordsScreen(),
              NotesScreen(),
              FlashcardsScreen(),
            ],
          ),
        ),
      ],
    );
  }
}
