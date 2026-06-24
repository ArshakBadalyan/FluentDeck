import 'package:flutter/material.dart';
import 'package:untitled2/screens/learn_screen/notes_screen.dart';
import 'package:untitled2/screens/learn_screen/study_hall_screen.dart';
import 'package:untitled2/screens/learn_screen/words_screen.dart';
import 'package:untitled2/screens/lessons_screen/lessons_list_tab.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key, required this.tabController});

  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: tabController,
      children: const [
        WordsScreen(),
        NotesScreen(),
        StudyHallScreen(),
        LessonsListTab(),
      ],
    );
  }
}
