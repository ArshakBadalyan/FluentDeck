import 'dart:convert';
import 'dart:io';

import 'package:riovox/localization/app_localizations.dart';
import 'package:riovox/screens/onboarding/english_onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Server config the plan page reads (free / Premium daily minutes).
final _server = MockClient((req) async {
  if (req.url.path == '/api/app-feature-config-public') {
    return http.Response(
      jsonEncode({'freeDailyMinutes': 10, 'premiumDailyMinutes': 300}),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
  return http.Response('{}', 404);
});

Future<void> _pumpOnboarding(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.6;
  addTearDown(tester.view.reset);
  await tester.runAsync(
    () => http.runWithClient(() async {
      await AppLocalizations.instance.load();
      await tester.pumpWidget(
        MaterialApp(
          home: EnglishOnboardingScreen(
            nextScreenBuilder: (_) => const Scaffold(body: Text('SIGN IN')),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }, () => _server),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapNext(WidgetTester tester) async {
  await tester.tap(find.text('Next'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    dotenv.testLoad(fileInput: 'API_URL=https://api.test/api');
    SharedPreferences.setMockInitialValues({
      'app_language_default_en_v1': true,
      'app_language_override': 'en',
    });
  });

  testWidgets('walks through the five real features, then sign-in', (tester) async {
    await _pumpOnboarding(tester);

    expect(find.text('Speak with an AI tutor who never judges'), findsOneWidget);
    expect(find.text('Gentle corrections'), findsOneWidget);

    await _tapNext(tester);
    expect(find.text('Practice what you need'), findsOneWidget);
    expect(find.text('16 languages'), findsOneWidget);

    await _tapNext(tester);
    expect(find.text('Your mistakes become flashcards'), findsOneWidget);
    expect(find.text('Other deck import'), findsOneWidget);

    await _tapNext(tester);
    expect(find.text('See your progress'), findsOneWidget);

    await _tapNext(tester);
    expect(find.text('Start for free'), findsOneWidget);
    // Real limits from the server, not hard-coded.
    expect(find.text('10 min of AI conversation a day, plus flashcards and decks.'), findsOneWidget);
    expect(
      find.text('Up to 5 h of AI conversation a day, no ads, and all speaking content.'),
      findsOneWidget,
    );
    expect(find.text('Get started'), findsOneWidget);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text('SIGN IN'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(kEnglishOnboardingSeenPrefsKey), isTrue);
  });

  testWidgets('Skip goes straight to sign-in and marks onboarding as seen', (tester) async {
    await _pumpOnboarding(tester);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('SIGN IN'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(kEnglishOnboardingSeenPrefsKey), isTrue);
  });

  testWidgets('swiping also moves between pages', (tester) async {
    await _pumpOnboarding(tester);
    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Practice what you need'), findsOneWidget);
  });

  test('every onboarding key the screen uses exists in English', () {
    final en = jsonDecode(File('assets/locales/en.json').readAsStringSync())['onboarding'] as Map;
    final pages = en['pages'] as Map;
    for (final id in ['speak', 'practice', 'flashcards', 'progress', 'plan']) {
      expect(pages[id]['title'], isA<String>(), reason: id);
      expect(pages[id]['body'], isA<String>(), reason: id);
    }
    for (final k in ['skip', 'next', 'get-started', 'language']) {
      expect(en[k], isA<String>(), reason: k);
    }
    // The old school / maths onboarding is gone.
    expect(en.containsKey('school'), isFalse);
    expect(en.containsKey('exercise'), isFalse);
  });
}
