/// Values for [RouteSettings.name] — consumed by Navigator observers (Firebase,
/// [AnalyticsService], Clarity).
abstract final class AppRouteNames {
  static const appLaunch = '/app_launch';
  static const main = '/main';
  static const onboarding = '/onboarding';
  static const auth = '/auth';
  static const forgotPassword = '/auth/forgot_password';
  static const resetPassword = '/auth/reset_password';

  static const profileAboutPrivacy = '/profile/about/privacy';
  static const profileAboutSoftware = '/profile/about/software';
  static const profileAboutReleaseNotes = '/profile/about/release_notes';

  static const speakingSessionDetail = '/activity/speaking_session';
}
