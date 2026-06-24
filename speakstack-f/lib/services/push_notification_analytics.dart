import 'dart:async';

import 'package:untitled2/services/analytics_service.dart';

/// Firebase Analytics / GA4 events for push opt-in attribution (entry_point).
class PushNotificationAnalytics {
  PushNotificationAnalytics._();

  /// Mein Status banner above daily goal.
  static const String entryStatusBanner = 'status_banner';

  /// Profil → Benachrichtigungen switch turned on.
  static const String entryProfileNotifications = 'profile_notifications';

  /// Milestone soft dialog after 20 / 200 exercises (user accepted, then system flow).
  static const String entryMilestoneDialog = 'milestone_dialog';

  /// Logs a successful push opt-in from a specific entry point.
  ///
  /// [milestoneStep] use `'20'` or `'200'` when [entryPoint] is [entryMilestoneDialog].
  static void logOptInSuccess({
    required String entryPoint,
    String? milestoneStep,
  }) {
    final params = <String, Object>{'entry_point': entryPoint};
    if (milestoneStep != null) {
      params['milestone_step'] = milestoneStep;
    }
    unawaited(
      AnalyticsService.instance.logEvent('push_opt_in', parameters: params),
    );
  }
}
