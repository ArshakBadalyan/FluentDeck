import 'package:flutter/material.dart';
import 'package:fluentdeck/screens/activity_screen/english_activity_screen.dart';
import 'package:fluentdeck/screens/learn_screen/statistics_screen.dart';
import 'package:fluentdeck/ui_elements/handoff_tab_bar_view.dart';

/// Activity hub: Speaking progress + Deck statistics.
class ActivityShellScreen extends StatelessWidget {
  const ActivityShellScreen({
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
        EnglishActivityScreen(),
        StatisticsScreen(),
      ],
    );
  }
}
