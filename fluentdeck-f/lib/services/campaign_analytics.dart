import 'package:riovox/services/analytics_service.dart';

/// GA4 sign-in events for Ads / Firebase Analytics:
/// - [logLogin] → `login` (param `method`, e.g. `email`)
/// - [logSignUp] → `sign_up` (param `method`: `password` | `nickname`)
class CampaignAnalytics {
  CampaignAnalytics._();

  static Future<void> logLogin({required String method}) {
    return AnalyticsService.instance.logLoginEvent(method: method);
  }

  /// [method] `password` = email+password registration; `nickname` = without password.
  static Future<void> logSignUp({required String method}) {
    return AnalyticsService.instance.logSignUpEvent(method: method);
  }
}
