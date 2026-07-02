import 'package:flutter/material.dart';
import 'package:fluentdeck/models/achievement_model.dart';
import 'package:fluentdeck/models/flashcard_model.dart';
import 'package:fluentdeck/models/user_progress_model.dart';
import 'package:fluentdeck/services/flashcard_service.dart';
import 'package:fluentdeck/services/user_progress_service.dart';
import 'package:fluentdeck/services/vocabulary_service.dart';

class AchievementSnapshot {
  const AchievementSnapshot({
    required this.progress,
    required this.flashcardStats,
    required this.hasPlacement,
    required this.achievements,
  });

  final UserProgressModel? progress;
  final FlashcardStudyStats? flashcardStats;
  final bool hasPlacement;
  final List<AchievementStatus> achievements;

  int get unlockedCount => achievements.where((a) => a.unlocked).length;
}

class AchievementService {
  AchievementService._();
  static final AchievementService instance = AchievementService._();

  static const definitions = [
    AchievementDefinition(
      id: 'first_speak',
      title: 'First words',
      description: 'Practice speaking for at least 1 minute.',
      icon: Icons.mic_outlined,
      metric: AchievementMetric.speakingMinutes,
      target: 1,
    ),
    AchievementDefinition(
      id: 'streak_3',
      title: 'On a roll',
      description: 'Keep a 3-day practice streak.',
      icon: Icons.local_fire_department_outlined,
      metric: AchievementMetric.streakDays,
      target: 3,
    ),
    AchievementDefinition(
      id: 'streak_7',
      title: 'Week warrior',
      description: 'Reach a 7-day practice streak.',
      icon: Icons.whatshot_outlined,
      metric: AchievementMetric.streakDays,
      target: 7,
    ),
    AchievementDefinition(
      id: 'speak_60',
      title: 'Conversationalist',
      description: 'Log 60 minutes of speaking practice.',
      icon: Icons.forum_outlined,
      metric: AchievementMetric.speakingMinutes,
      target: 60,
    ),
    AchievementDefinition(
      id: 'words_50',
      title: 'Word collector',
      description: 'Use 50 unique words in conversation.',
      icon: Icons.menu_book_outlined,
      metric: AchievementMetric.uniqueWords,
      target: 50,
    ),
    AchievementDefinition(
      id: 'perfect_10',
      title: 'Clean speaker',
      description: 'Speak 10 perfect sentences without corrections.',
      icon: Icons.check_circle_outline,
      metric: AchievementMetric.perfectSentences,
      target: 10,
    ),
    AchievementDefinition(
      id: 'review_streak',
      title: 'Daily reviewer',
      description: 'Maintain a 3-day flashcard review streak.',
      icon: Icons.style_outlined,
      metric: AchievementMetric.reviewStreakDays,
      target: 3,
    ),
    AchievementDefinition(
      id: 'cards_today',
      title: 'Warm-up',
      description: 'Review at least 10 cards in one day.',
      icon: Icons.layers_outlined,
      metric: AchievementMetric.cardsReviewedToday,
      target: 10,
    ),
    AchievementDefinition(
      id: 'exercises_5',
      title: 'Lesson learner',
      description: 'Complete 5 lesson exercises.',
      icon: Icons.school_outlined,
      metric: AchievementMetric.exercisesCompleted,
      target: 5,
    ),
  ];

  Future<AchievementSnapshot> load() async {
    UserProgressModel? progress;
    FlashcardStudyStats? stats;
    var hasPlacement = false;

    try {
      progress = await UserProgressService.instance.createIfMissing();
    } catch (_) {}

    try {
      stats = await FlashcardService.instance.fetchStats();
    } catch (_) {}

    try {
      hasPlacement = await VocabularyService.instance.fetchLatestPlacement() != null;
    } catch (_) {}

    final achievements =
        definitions
            .map((d) => _evaluate(d, progress: progress, stats: stats))
            .toList();

    return AchievementSnapshot(
      progress: progress,
      flashcardStats: stats,
      hasPlacement: hasPlacement,
      achievements: achievements,
    );
  }

  AchievementStatus _evaluate(
    AchievementDefinition definition, {
    UserProgressModel? progress,
    FlashcardStudyStats? stats,
  }) {
    final current = switch (definition.metric) {
      AchievementMetric.streakDays => progress?.streakDays ?? 0,
      AchievementMetric.speakingMinutes => progress?.totalSpeakingMinutes ?? 0,
      AchievementMetric.uniqueWords => progress?.uniqueWordsUsed ?? 0,
      AchievementMetric.perfectSentences => progress?.perfectSentencesCount ?? 0,
      AchievementMetric.reviewStreakDays => stats?.reviewStreakDays ?? 0,
      AchievementMetric.cardsReviewedToday => stats?.todayReviews ?? 0,
      AchievementMetric.exercisesCompleted =>
        progress?.completedExercises.length ?? 0,
    };

    return AchievementStatus(
      definition: definition,
      current: current,
      unlocked: current >= definition.target,
    );
  }
}
