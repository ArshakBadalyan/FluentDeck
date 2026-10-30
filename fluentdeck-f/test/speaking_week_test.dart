import 'package:riovox/models/speaking_session_record_model.dart';
import 'package:riovox/screens/activity_screen/language_levels_activity_tab.dart';
import 'package:flutter_test/flutter_test.dart';

SpeakingSessionRecord _at(DateTime t) =>
    SpeakingSessionRecord(id: 1, title: 'Chat', score: 80, completedAt: t);

void main() {
  // Friday, 30 Oct 2026, mid-afternoon.
  final friday = DateTime(2026, 10, 30, 15);

  test('ticks Mon–Thu, today open: streak counts up to yesterday', () {
    final sessions = [
      for (var d = 26; d <= 29; d++) _at(DateTime(2026, 10, d, 9)),
      _at(DateTime(2026, 10, 29, 21)), // two chats one day = one tick
    ];
    final w = speakingWeek(sessions, friday);
    expect(w.monday, DateTime(2026, 10, 26));
    expect(w.today, DateTime(2026, 10, 30));
    expect(w.practiced.length, 4);
    expect(w.streak, 4);
  });

  test('practising today extends the streak', () {
    final sessions = [
      for (var d = 26; d <= 30; d++) _at(DateTime(2026, 10, d, 9)),
    ];
    expect(speakingWeek(sessions, friday).streak, 5);
  });

  test('a missed day breaks the streak', () {
    final sessions = [
      _at(DateTime(2026, 10, 26, 9)),
      _at(DateTime(2026, 10, 28, 9)),
      _at(DateTime(2026, 10, 29, 9)),
    ];
    expect(speakingWeek(sessions, friday).streak, 2);
  });

  test('streak runs back past Monday into last week', () {
    final sessions = [
      for (var d = 20; d <= 29; d++) _at(DateTime(2026, 10, d, 9)),
    ];
    expect(speakingWeek(sessions, friday).streak, 10);
  });

  test('no practice yesterday or today: no streak', () {
    final sessions = [_at(DateTime(2026, 10, 27, 9))];
    expect(speakingWeek(sessions, friday).streak, 0);
  });

  test('Monday is this week\'s Monday on a Sunday too', () {
    final w = speakingWeek(const [], DateTime(2026, 11, 1, 10));
    expect(w.monday, DateTime(2026, 10, 26));
  });
}
