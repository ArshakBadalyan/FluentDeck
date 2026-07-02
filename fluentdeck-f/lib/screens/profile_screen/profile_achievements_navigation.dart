import 'package:flutter/material.dart';
import 'package:fluentdeck/screens/profile_screen/profile_achievements_screen.dart';
import 'package:fluentdeck/ui_elements/app_motion.dart';

/// Opens the full achievements showcase with shared-axis transition.
void openProfileAchievements(BuildContext context) {
  Navigator.of(context).push<void>(
    AppSharedAxisRoute<void>(page: const ProfileAchievementsScreen()),
  );
}
