import 'package:fluentdeck/services/deck_notification_service.dart';
import 'package:fluentdeck/services/review_settings_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  tz_data.initializeTimeZones();

  group('nextReminderTime', () {
    final yerevan = tz.getLocation('Asia/Yerevan');

    tz.TZDateTime at(tz.Location loc, int y, int mo, int d, int h, int mi) =>
        tz.TZDateTime(loc, y, mo, d, h, mi);

    test('later today when the time is still ahead', () {
      final next = DeckNotificationService.nextReminderTime(
        at(yerevan, 2026, 10, 23, 9, 0),
        20,
        0,
      );
      expect(next, at(yerevan, 2026, 10, 23, 20, 0));
    });

    test('tomorrow when the time has passed', () {
      final next = DeckNotificationService.nextReminderTime(
        at(yerevan, 2026, 10, 23, 21, 30),
        20,
        0,
      );
      expect(next, at(yerevan, 2026, 10, 24, 20, 0));
    });

    test('tomorrow when the time is exactly now (must be in the future)', () {
      final next = DeckNotificationService.nextReminderTime(
        at(yerevan, 2026, 10, 23, 20, 0),
        20,
        0,
      );
      expect(next, at(yerevan, 2026, 10, 24, 20, 0));
    });

    test('rolls over month and year ends', () {
      final next = DeckNotificationService.nextReminderTime(
        at(yerevan, 2026, 12, 31, 23, 0),
        8,
        15,
      );
      expect(next, at(yerevan, 2027, 1, 1, 8, 15));
    });

    test('keeps wall-clock time across a daylight-saving change', () {
      // Clocks go back in Berlin on 2026-10-25 at 03:00.
      final berlin = tz.getLocation('Europe/Berlin');
      final next = DeckNotificationService.nextReminderTime(
        at(berlin, 2026, 10, 24, 21, 0),
        20,
        0,
      );
      expect(next.hour, 20);
      expect(next.minute, 0);
      expect(next.day, 25);
    });
  });

  group('ReviewSettingsStore reminder fields', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('defaults to off at 20:00', () async {
      final settings = await ReviewSettingsStore.instance.load();
      expect(settings.reviewReminderEnabled, isFalse);
      expect(settings.reviewReminderHour, 20);
      expect(settings.reviewReminderMinute, 0);
    });

    test('saves and reloads enabled state and time', () async {
      final store = ReviewSettingsStore.instance;
      final settings = await store.load();
      await store.save(
        settings.copyWith(
          reviewReminderEnabled: true,
          reviewReminderHour: 7,
          reviewReminderMinute: 45,
        ),
      );
      final reloaded = await store.load();
      expect(reloaded.reviewReminderEnabled, isTrue);
      expect(reloaded.reviewReminderHour, 7);
      expect(reloaded.reviewReminderMinute, 45);
    });

    test('survives JSON export and import', () {
      final json =
          const ReviewSettings(
            reviewReminderEnabled: true,
            reviewReminderHour: 6,
            reviewReminderMinute: 30,
          ).toJson();
      final restored = ReviewSettings.fromJson(json);
      expect(restored.reviewReminderEnabled, isTrue);
      expect(restored.reviewReminderHour, 6);
      expect(restored.reviewReminderMinute, 30);
    });
  });
}
