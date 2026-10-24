import 'package:fluentdeck/services/rio_preferences.dart';
import 'package:fluentdeck/widgets/rio_stage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(RioMood mood, {bool reduceMotion = false}) => MaterialApp(
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: Scaffold(body: RioStage(mood: mood)),
    ),
  ),
);

String _frame(WidgetTester tester) =>
    ((tester.widget<Image>(find.byType(Image)).image) as AssetImage).assetName;

void main() {
  testWidgets('Rio moves its mouth while speaking and settles when it stops', (tester) async {
    await tester.pumpWidget(_app(RioMood.idle));
    expect(_frame(tester), 'assets/rio/rio-happy.webp');

    await tester.pumpWidget(_app(RioMood.speaking));
    final seen = <String>{_frame(tester)};
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 160));
      seen.add(_frame(tester));
    }
    expect(seen, containsAll(['assets/rio/rio-talk.webp', 'assets/rio/rio-talk-mid.webp']));

    await tester.pumpWidget(_app(RioMood.listening));
    await tester.pump(const Duration(milliseconds: 400));
    expect(_frame(tester), 'assets/rio/rio-curious.webp');
    await tester.pumpWidget(const SizedBox()); // disposes timers
  });

  testWidgets('Reduce motion: Rio stays still while speaking', (tester) async {
    await tester.pumpWidget(_app(RioMood.speaking, reduceMotion: true));
    final first = _frame(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(_frame(tester), first);
    await tester.pumpWidget(const SizedBox());
  });

  test('Show Rio is on by default and remembered', () async {
    SharedPreferences.setMockInitialValues({});
    await RioPreferences.instance.load();
    expect(RioPreferences.instance.showRio.value, isTrue);
    await RioPreferences.instance.setShowRio(false);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('show_rio'), isFalse);
  });
}
