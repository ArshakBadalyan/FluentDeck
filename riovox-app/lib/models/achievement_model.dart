import 'package:flutter/material.dart';

class AchievementDefinition {
  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.metric,
    required this.target,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final AchievementMetric metric;
  final int target;
}

enum AchievementMetric {
  streakDays,
  speakingMinutes,
  uniqueWords,
  perfectSentences,
  reviewStreakDays,
  exercisesCompleted,
  cardsReviewedToday,
}

class AchievementStatus {
  const AchievementStatus({
    required this.definition,
    required this.current,
    required this.unlocked,
  });

  final AchievementDefinition definition;
  final int current;
  final bool unlocked;

  double get progress =>
      definition.target <= 0 ? 1 : (current / definition.target).clamp(0.0, 1.0);
}
