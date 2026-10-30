import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'auth_service.dart';

enum PushSubscriptionRequestOutcome {
  granted,
  denied,
  openedSystemSettings,
  unavailable,
}

class PushNotificationService {
  static String? _currentExternalUserId;

  static bool get isConfigured {
    if (kIsWeb) return false;
    final appId = dotenv.env['ONESIGNAL_APP_ID'] ?? '';
    return appId.isNotEmpty;
  }

  static Future<void> initialize() async {
    if (kIsWeb) return;
    final appId = dotenv.env['ONESIGNAL_APP_ID'] ?? '';
    if (appId.isEmpty) {
      return;
    }

    OneSignal.initialize(appId);

    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      event.notification.display();
    });

    OneSignal.User.pushSubscription.addObserver((state) {
      _syncSubscriptionStatus();
    });
  }

  static Future<bool> requestSubscription() async {
    if (kIsWeb) return false;
    final granted =
        await OneSignal.Notifications.requestPermission(true);

    if (granted) {
      await _finishOptInAfterOsAllows();
    }

    return granted;
  }

  static Future<void> _finishOptInAfterOsAllows() async {
    if (kIsWeb) return;
    OneSignal.User.pushSubscription.optIn();
    if (_currentExternalUserId != null) {
      await OneSignal.login(_currentExternalUserId!);
    }
    await _syncSubscriptionStatus();
  }

  /// After the user agreed in an in-app explanation (banner, milestone dialog).
  ///
  /// If iOS/Android already allows notifications, [canRequest] is often false;
  /// we still must call [optIn] — otherwise we would wrongly send users to
  /// Settings while permission is already on.
  static Future<PushSubscriptionRequestOutcome>
      requestSubscriptionAfterSoftPrompt() async {
    if (!isConfigured) {
      return PushSubscriptionRequestOutcome.unavailable;
    }

    if (OneSignal.Notifications.permission) {
      await _finishOptInAfterOsAllows();
      return PushSubscriptionRequestOutcome.granted;
    }

    final canRequest = await OneSignal.Notifications.canRequest();

    if (canRequest) {
      final granted =
          await OneSignal.Notifications.requestPermission(false);
      if (granted) {
        await _finishOptInAfterOsAllows();
        return PushSubscriptionRequestOutcome.granted;
      }
      return PushSubscriptionRequestOutcome.denied;
    }

    await AppSettings.openAppSettings();
    return PushSubscriptionRequestOutcome.openedSystemSettings;
  }

  static Future<void> unsubscribe() async {
    if (kIsWeb) return;
    OneSignal.User.pushSubscription.optOut();
  }

  static bool get isSubscribed {
    if (kIsWeb) return false;
    final sub = OneSignal.User.pushSubscription;
    return sub.optedIn == true && sub.id != null;
  }

  /// True when the OS allows notifications and OneSignal has an active opt-in.
  /// Used for UI like the status banner: simulator often has no token, so
  /// [isSubscribed] stays false there while a real device may already be fully
  /// enrolled after "Allow", which hides the banner by design.
  static bool get hasActivePushEnrollment {
    if (!isConfigured) return false;
    return OneSignal.Notifications.permission && isSubscribed;
  }

  static Future<void> login(String externalUserId) async {
    _currentExternalUserId = externalUserId;
    if (kIsWeb) return;
    await OneSignal.login(externalUserId);
  }

  static Future<void> logout() async {
    _currentExternalUserId = null;
    if (kIsWeb) return;
    await OneSignal.logout();
  }

  static Future<void> _syncSubscriptionStatus() async {
    try {
      await AuthService.updateUser({'push_subscribed': isSubscribed});
    } catch (_) {}
  }
}
