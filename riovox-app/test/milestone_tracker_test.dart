import 'package:riovox/services/milestone_tracker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final tracker = MilestoneTracker.instance;

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('streak milestones', () {
    test('celebrates each milestone once', () async {
      expect(await tracker.streakMilestone(2), isNull);
      expect(await tracker.streakMilestone(3), 3);
      expect(await tracker.streakMilestone(3), isNull);
      expect(await tracker.streakMilestone(5), isNull);
      expect(await tracker.streakMilestone(7), 7);
    });

    test('a broken streak lets milestones count again', () async {
      expect(await tracker.streakMilestone(7), 7);
      expect(await tracker.streakMilestone(1), isNull);
      expect(await tracker.streakMilestone(3), 3);
    });
  });

  group('level up', () {
    test('the first level seen is remembered, not celebrated', () async {
      expect(await tracker.isLevelUp('en', 'B1'), isFalse);
      expect(await tracker.isLevelUp('en', 'B1'), isFalse);
    });

    test('a higher level celebrates once; a lower one does not', () async {
      await tracker.isLevelUp('en', 'A2');
      expect(await tracker.isLevelUp('en', 'B1'), isTrue);
      expect(await tracker.isLevelUp('en', 'B1'), isFalse);
      expect(await tracker.isLevelUp('en', 'A2'), isFalse);
      expect(await tracker.isLevelUp('en', 'B1'), isTrue);
    });

    test('each language keeps its own level; unknown levels are ignored', () async {
      await tracker.isLevelUp('en', 'C1');
      expect(await tracker.isLevelUp('de', 'A1'), isFalse);
      expect(await tracker.isLevelUp('de', null), isFalse);
      expect(await tracker.isLevelUp('de', 'Z9'), isFalse);
      expect(await tracker.isLevelUp('de', 'A2'), isTrue);
    });
  });
}
