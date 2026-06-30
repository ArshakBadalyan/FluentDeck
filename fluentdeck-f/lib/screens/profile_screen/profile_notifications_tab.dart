import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/localization/app_localizations.dart';
import 'package:fluentdeck/models/speaking_preferences.dart';
import 'package:fluentdeck/services/push_notification_analytics.dart';
import 'package:fluentdeck/services/push_notification_service.dart';
import 'package:fluentdeck/services/speaking_preferences_service.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';

class ProfileNotificationsTab extends StatefulWidget {
  const ProfileNotificationsTab({super.key});

  @override
  State<ProfileNotificationsTab> createState() =>
      _ProfileNotificationsTabState();
}

class _ProfileNotificationsTabState extends State<ProfileNotificationsTab> {
  bool _subscribed = PushNotificationService.isSubscribed;
  bool _toggling = false;
  bool _loadingPrefs = true;
  bool _savingReminder = false;
  SpeakingPreferences _speakingPrefs = const SpeakingPreferences();

  void _onSubscriptionChanged(OSPushSubscriptionChangedState state) {
    if (!mounted) return;
    setState(() => _subscribed = PushNotificationService.isSubscribed);
  }

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      OneSignal.User.pushSubscription.addObserver(_onSubscriptionChanged);
    }
    _loadReminderPrefs();
  }

  Future<void> _loadReminderPrefs() async {
    final prefs = await SpeakingPreferencesService.instance.load(forceRefresh: true);
    if (!mounted) return;
    setState(() {
      _speakingPrefs = prefs;
      _loadingPrefs = false;
    });
  }

  Future<void> _saveReminderPrefs(SpeakingPreferences next) async {
    setState(() {
      _speakingPrefs = next;
      _savingReminder = true;
    });
    final result = await SpeakingPreferencesService.instance.saveWithDetails(next);
    if (!mounted) return;
    setState(() => _savingReminder = false);
    if (!result.ok) {
      await _loadReminderPrefs();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Could not update reminder'),
        ),
      );
    }
  }

  Future<void> _pickReminderTime() async {
    final parts = _speakingPrefs.dailyReminderTime.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.first) ?? 9,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !mounted) return;
    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    await _saveReminderPrefs(
      _speakingPrefs.copyWith(dailyReminderTime: formatted),
    );
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      OneSignal.User.pushSubscription.removeObserver(_onSubscriptionChanged);
    }
    super.dispose();
  }

  Future<void> _toggle(bool value) async {
    if (_toggling) return;
    setState(() => _toggling = true);

    if (value) {
      await PushNotificationService.requestSubscription();
      if (PushNotificationService.isSubscribed) {
        PushNotificationAnalytics.logOptInSuccess(
          entryPoint: PushNotificationAnalytics.entryProfileNotifications,
        );
      }
    } else {
      await PushNotificationService.unsubscribe();
    }

    if (!mounted) return;
    setState(() {
      _subscribed = PushNotificationService.isSubscribed;
      _toggling = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppPageBackground(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          children: [
            AppSectionCard(
              title: context.tr('profile.notifications.title'),
              icon: Icons.notifications_outlined,
              subtitle: context.tr('profile.notifications.description'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppToggleRow(
                    title: context.tr('profile.notifications.push-label'),
                    value: _subscribed,
                    enabled: !_toggling,
                    onChanged: _toggle,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: (_subscribed ? AppColors.greenCorrect : Colors.grey)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _subscribed ? Icons.check_circle_outline : Icons.notifications_off_outlined,
                          size: 18,
                          color: _subscribed ? AppColors.greenCorrect : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _subscribed
                              ? context.tr('profile.notifications.status-on')
                              : context.tr('profile.notifications.status-off'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _subscribed ? const Color(0xFF1B9E4B) : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppSectionCard(
              title: 'Daily practice reminder',
              icon: Icons.alarm_outlined,
              subtitle: 'Get a nudge to practice speaking each day.',
              child:
                  _loadingPrefs
                      ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: LinearProgressIndicator(minHeight: 2),
                      )
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppToggleRow(
                            title: 'Daily reminder',
                            subtitle: 'Send a push notification at your chosen time.',
                            value: _speakingPrefs.dailyReminderEnabled,
                            enabled: !_savingReminder,
                            onChanged: (value) {
                              _saveReminderPrefs(
                                _speakingPrefs.copyWith(
                                  dailyReminderEnabled: value,
                                ),
                              );
                            },
                          ),
                          if (_speakingPrefs.dailyReminderEnabled) ...[
                            const SizedBox(height: 8),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.schedule_outlined),
                              title: const Text('Reminder time'),
                              subtitle: Text(_speakingPrefs.dailyReminderTime),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: _savingReminder ? null : _pickReminderTime,
                            ),
                          ],
                          if (_savingReminder)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: LinearProgressIndicator(minHeight: 2),
                            ),
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
