import 'package:riovox/models/tutor_persona.dart';
import 'package:riovox/services/rio_preferences.dart';
import 'package:riovox/widgets/rio.dart';
import 'package:riovox/widgets/rio_stage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  testWidgets('Rio (the professor otter) moves its mouth while speaking and settles when it stops', (tester) async {
    RioPreferences.instance.tutor.value = TutorPersona.rio;
    await tester.pumpWidget(_app(RioMood.idle));
    expect(_frame(tester), 'assets/professor/face-encouraging.webp');

    await tester.pumpWidget(_app(RioMood.speaking));
    final seen = <String>{_frame(tester)};
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 160));
      seen.add(_frame(tester));
    }
    // Open and closed mouths alternate.
    expect(seen, containsAll(['assets/professor/face-happy.webp', 'assets/professor/face-determined.webp']));

    await tester.pumpWidget(_app(RioMood.listening));
    await tester.pump(const Duration(milliseconds: 400));
    expect(_frame(tester), 'assets/professor/face-thoughtful.webp');
    await tester.pumpWidget(const SizedBox()); // disposes timers
  });

  testWidgets('A person tutor shows their portrait', (tester) async {
    final maya = TutorPersona.people.first;
    RioPreferences.instance.tutor.value = maya;
    await tester.pumpWidget(_app(RioMood.speaking));
    await tester.pump(const Duration(milliseconds: 300));
    expect(_frame(tester), maya.image);
    await tester.pumpWidget(const SizedBox());
    RioPreferences.instance.tutor.value = TutorPersona.rio;
  });

  testWidgets('Every tutor portrait is in the asset bundle', (tester) async {
    for (final p in TutorPersona.all) {
      final data = await rootBundle.load(p.image);
      expect(data.lengthInBytes, greaterThan(1000), reason: p.image);
    }
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

  testWidgets('A popping Rio settles (so pages using it can pumpAndSettle)', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RioImage(RioPose.catchFish, motion: RioMotion.pop)));
    await tester.pumpAndSettle();
    expect(find.byType(RioImage), findsOneWidget);
  });

  testWidgets('Every pose has its picture in the asset bundle', (tester) async {
    for (final pose in RioPose.values) {
      final data = await rootBundle.load(pose.asset);
      expect(data.lengthInBytes, greaterThan(1000), reason: pose.asset);
    }
  });

  testWidgets('Reduce motion: the swimming loader holds still', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: const Scaffold(body: RioLoader(label: 'Loading')),
        ),
      ),
    ));
    await tester.pumpAndSettle(); // would time out if the waves kept moving
    expect(find.text('Loading'), findsOneWidget);
  });
}
