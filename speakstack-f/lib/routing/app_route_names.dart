/// Values for [RouteSettings.name] — consumed by Navigator observers (Firebase,
/// [AnalyticsService], Clarity).
abstract final class AppRouteNames {
  static const appLaunch = '/app_launch';
  static const main = '/main';
  static const onboarding = '/onboarding';
  static const auth = '/auth';
  static const forgotPassword = '/auth/forgot_password';
  static const resetPassword = '/auth/reset_password';

  static const topicsLearningQuiz = '/topics/learning_quiz';
  static const topicsGenerateQuestion = '/topics/generate_question';
  static const topicsReviewQuestion = '/topics/review_question';

  /// Themen topic exercise runner — includes [categoryId] for analytics/Clarity.
  static String topicsLearningQuizForCategory(int categoryId) =>
      '$topicsLearningQuiz/$categoryId';
  static const topicsLearningComplete = '/topics/learning_complete';

  static const practiceRemixQuiz = '/practice/remix_quiz';
  static const practiceRemixComplete = '/practice/remix_complete';
  static const practiceMachineQuiz = '/practice/machine_quiz';
  static const practicePlayerQuiz = '/practice/player_quiz';

  static const profileAboutPrivacy = '/profile/about/privacy';
  static const profileAboutSoftware = '/profile/about/software';
  static const profileAboutReleaseNotes = '/profile/about/release_notes';

  static const globalSearch = '/search';
}
