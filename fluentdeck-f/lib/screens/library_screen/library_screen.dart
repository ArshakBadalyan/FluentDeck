import 'package:flutter/material.dart';
import 'package:fluentdeck/screens/learn_screen/notes_screen.dart';
import 'package:fluentdeck/screens/learn_screen/study_hall_screen.dart';
import 'package:fluentdeck/screens/learn_screen/words_screen.dart';
import 'package:fluentdeck/screens/lessons_screen/lessons_list_tab.dart';
import 'package:fluentdeck/ui_elements/handoff_tab_bar_view.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({
    super.key,
    required this.tabController,
    this.mainTabHandoff = const MainTabHandoff(),
  });

  final TabController tabController;
  final MainTabHandoff mainTabHandoff;

  @override
  Widget build(BuildContext context) {
    return HandoffTabBarView(
      controller: tabController,
      onHandoffPrevious: mainTabHandoff.onPrevious,
      onHandoffNext: mainTabHandoff.onNext,
      children: const [
        WordsScreen(),
        NotesScreen(),
        StudyHallScreen(),
        LessonsListTab(),
      ],
    );
  }
}
