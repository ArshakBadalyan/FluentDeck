import 'package:fluentdeck/screens/learn_screen/decks_settings_section.dart';
import 'package:fluentdeck/screens/learn_screen/decks_settings_section_screen.dart';
import 'package:fluentdeck/services/deck_backup_service.dart';
import 'package:fluentdeck/services/flashcard_sync_store.dart';
import 'package:fluentdeck/services/review_settings_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _lastBackupKey = 'deck_last_backup_ms_v1';

void main() {
  group('isAutoBackupDue', () {
    final now = DateTime(2026, 10, 23, 12);
    int ms(DateTime d) => d.millisecondsSinceEpoch;

    test('due when never backed up', () {
      expect(
        DeckBackupService.isAutoBackupDue(
          lastBackupMs: null,
          intervalDays: 7,
          now: now,
        ),
        isTrue,
      );
    });

    test('not due before the interval has fully passed', () {
      expect(
        DeckBackupService.isAutoBackupDue(
          lastBackupMs: ms(now.subtract(const Duration(days: 6, hours: 23))),
          intervalDays: 7,
          now: now,
        ),
        isFalse,
      );
    });

    test('due once the interval has passed', () {
      expect(
        DeckBackupService.isAutoBackupDue(
          lastBackupMs: ms(now.subtract(const Duration(days: 7))),
          intervalDays: 7,
          now: now,
        ),
        isTrue,
      );
      expect(
        DeckBackupService.isAutoBackupDue(
          lastBackupMs: ms(now.subtract(const Duration(days: 1, minutes: 1))),
          intervalDays: 1,
          now: now,
        ),
        isTrue,
      );
    });

    test('due when the last backup is in the future (clock moved back)', () {
      expect(
        DeckBackupService.isAutoBackupDue(
          lastBackupMs: ms(now.add(const Duration(days: 3))),
          intervalDays: 7,
          now: now,
        ),
        isTrue,
      );
    });
  });

  group('runAutoBackupIfDue', () {
    test('does nothing while automatic backup is off', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await DeckBackupService.instance.runAutoBackupIfDue(), isFalse);
      expect(await DeckBackupService.instance.getLastBackupMs(), isNull);
    });
  });

  group('Backups screen', () {
    Future<void> pumpBackups(
      WidgetTester tester, {
      required Future<void> Function() onBackupNow,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DecksSettingsSectionScreen(
            section: DecksSettingsSection.backups,
            settings: const ReviewSettings(),
            onSave: (_) async {},
            // Stale snapshot from the parent, as when the screen is pushed.
            lastBackupLabel: 'Never',
            syncLog: const FlashcardSyncLog(),
            syncing: false,
            onSyncNow: () async {},
            onBackupNow: onBackupNow,
            onReload: () async {},
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('"Back up now" updates Last backup without leaving', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final backupAt = DateTime(2026, 10, 23, 14, 5);

      await pumpBackups(
        tester,
        onBackupNow: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(_lastBackupKey, backupAt.millisecondsSinceEpoch);
        },
      );
      expect(find.text('Never'), findsOneWidget);

      await tester.tap(find.text('Back up now'));
      await tester.pumpAndSettle();

      expect(find.text('Never'), findsNothing);
      expect(find.text('2026-10-23 14:05'), findsOneWidget);
    });

    testWidgets('shows the real last backup even if the snapshot is stale', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        _lastBackupKey: DateTime(2026, 10, 20, 9, 30).millisecondsSinceEpoch,
      });

      await pumpBackups(tester, onBackupNow: () async {});

      expect(find.text('2026-10-20 09:30'), findsOneWidget);
    });
  });
}
