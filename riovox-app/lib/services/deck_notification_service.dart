import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'main_navigation_coordinator.dart';
import 'main_tab_config.dart';
import 'review_settings_store.dart';

/// Daily review reminder (Phase 5B). Mobile only.
class DeckNotificationService {
  DeckNotificationService._();
  static final DeckNotificationService instance = DeckNotificationService._();

  static const _channelId = 'deck_review_reminder';
  static const _notificationId = 4242;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (kIsWeb) return;
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    // Ask only when the user turns the reminder on, not at first launch.
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onTap,
    );
    _initialized = true;

    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true &&
        launch?.notificationResponse?.id == _notificationId) {
      _openDecksOnLaunch = true;
    }

    await syncFromSettings();
  }

  bool _openDecksOnLaunch = false;

  /// True once if the app was cold-started by tapping the reminder.
  bool consumeOpenDecksOnLaunch() {
    final open = _openDecksOnLaunch;
    _openDecksOnLaunch = false;
    return open;
  }

  void _onTap(NotificationResponse response) {
    if (response.id == _notificationId) {
      MainNavigationCoordinator.goToTab(MainTabId.decks);
    }
  }

  /// Asks the OS for notification permission. False if the user declined.
  Future<bool> requestPermission() async {
    if (kIsWeb || !_initialized) return false;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android =
          _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      return await android?.requestNotificationsPermission() ?? true;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios =
          _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >();
      return await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return true;
  }

  Future<void> syncFromSettings() async {
    if (kIsWeb || !_initialized) return;

    final settings = await ReviewSettingsStore.instance.load();
    if (!settings.reviewReminderEnabled) {
      await _plugin.cancel(_notificationId);
      return;
    }

    await _scheduleDaily(settings.reviewReminderHour, settings.reviewReminderMinute);
  }

  /// Next time the reminder should fire: today at [hour]:[minute] if that is
  /// still ahead of [now], otherwise tomorrow. Built from calendar fields (not
  /// +24h) so the wall-clock time survives daylight-saving changes.
  static tz.TZDateTime nextReminderTime(
    tz.TZDateTime now,
    int hour,
    int minute,
  ) {
    final today = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (today.isAfter(now)) return today;
    return tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day + 1,
      hour,
      minute,
    );
  }

  static const _title = 'Time to review';
  static const _body = 'You have flashcards waiting in Decks.';

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      'Review reminders',
      channelDescription: 'Daily flashcard review reminder',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Shows the reminder right now so the user can check it works.
  /// False if notifications are unavailable or not allowed.
  Future<bool> showTestReminder() async {
    if (kIsWeb || !_initialized) return false;
    if (!await requestPermission()) return false;
    await _plugin.show(_notificationId, _title, _body, _details);
    return true;
  }

  Future<void> _scheduleDaily(int hour, int minute) async {
    await _plugin.cancel(_notificationId);

    final scheduled = nextReminderTime(
      tz.TZDateTime.now(tz.local),
      hour,
      minute,
    );

    await _plugin.zonedSchedule(
      _notificationId,
      _title,
      _body,
      scheduled,
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
