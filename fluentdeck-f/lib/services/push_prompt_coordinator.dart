import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluentdeck/localization/app_localizations.dart';
import 'package:fluentdeck/services/push_notification_analytics.dart';
import 'package:fluentdeck/services/push_notification_service.dart';
import 'package:fluentdeck/ui_elements/dialogs/push_notification_invite_dialog.dart';

/// Milestone prompts for push notifications.
class PushPromptCoordinator {
  PushPromptCoordinator._();

  static String _cacheKey(int userId) => 'push_cached_conversations_$userId';

  static String _dialog20Key(int userId) => 'push_dialog_20_done_$userId';

  static String _dialog200Key(int userId) => 'push_dialog_200_done_$userId';

  static Future<void> syncBaselineFromServer() async {
    if (kIsWeb || !PushNotificationService.isConfigured) return;
    // Baseline sync is optional for the English app; conversations are tracked locally.
  }

  static Future<void> onConversationCompleted(BuildContext context) async {
    if (kIsWeb || !PushNotificationService.isConfigured) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) return;

    if (PushNotificationService.isSubscribed) return;

    final prev = prefs.getInt(_cacheKey(userId)) ?? 0;
    final count = prev + 1;
    await prefs.setInt(_cacheKey(userId), count);

    final dialog20Done = prefs.getBool(_dialog20Key(userId)) ?? false;
    final dialog200Done = prefs.getBool(_dialog200Key(userId)) ?? false;

    if (!dialog20Done && prev < 20 && count >= 20) {
      await _showMilestoneDialog(
        context,
        userId,
        milestone200: false,
        prefs: prefs,
      );
    } else if (!dialog200Done && prev < 200 && count >= 200) {
      await _showMilestoneDialog(
        context,
        userId,
        milestone200: true,
        prefs: prefs,
      );
    }
  }

  /// Legacy hook from math exercise saves — no-op in English app.
  static Future<void> onExerciseSaved(BuildContext context) async {}

  static Future<void> _showMilestoneDialog(
    BuildContext context,
    int userId, {
    required bool milestone200,
    required SharedPreferences prefs,
  }) async {
    if (!context.mounted) return;

    final accepted =
        await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder:
              (ctx) =>
                  PushNotificationInviteDialog(milestone200: milestone200),
        ) ??
        false;

    if (milestone200) {
      await prefs.setBool(_dialog200Key(userId), true);
    } else {
      await prefs.setBool(_dialog20Key(userId), true);
    }

    if (!accepted || !context.mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    final loc = AppLocalizations.instance;

    final outcome =
        await PushNotificationService.requestSubscriptionAfterSoftPrompt();

    if (!context.mounted) return;

    switch (outcome) {
      case PushSubscriptionRequestOutcome.granted:
        PushNotificationAnalytics.logOptInSuccess(
          entryPoint: PushNotificationAnalytics.entryMilestoneDialog,
          milestoneStep: milestone200 ? '200' : '20',
        );
        break;
      case PushSubscriptionRequestOutcome.openedSystemSettings:
        messenger?.showSnackBar(
          SnackBar(content: Text(loc.t('push-prompt.opened-settings-hint'))),
        );
        break;
      case PushSubscriptionRequestOutcome.denied:
        messenger?.showSnackBar(
          SnackBar(content: Text(loc.t('push-prompt.native-denied-hint'))),
        );
        break;
      default:
        break;
    }
  }
}
