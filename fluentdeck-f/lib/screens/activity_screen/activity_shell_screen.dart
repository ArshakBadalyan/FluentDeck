import 'package:flutter/material.dart';
import 'package:fluentdeck/screens/activity_screen/english_activity_screen.dart';
import 'package:fluentdeck/screens/learn_screen/statistics_screen.dart';

/// Activity hub: Speaking progress + Deck statistics.
class ActivityShellScreen extends StatelessWidget {
  const ActivityShellScreen({super.key, required this.tabController});

  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: tabController,
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        EnglishActivityScreen(),
        StatisticsScreen(),
      ],
    );
  }
}
