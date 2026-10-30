import 'dart:convert';
import 'dart:io';

import 'package:riovox/config/app_language.dart';
import 'package:riovox/localization/app_localizations.dart';
import 'package:riovox/screens/profile_screen/profile_settings_general_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, String> _flatten(Object? node, [String prefix = '']) {
  final out = <String, String>{};
  if (node is Map) {
    node.forEach((k, v) => out.addAll(_flatten(v, prefix.isEmpty ? '$k' : '$prefix.$k')));
  } else if (node is List) {
    for (var i = 0; i < node.length; i++) {
      out.addAll(_flatten(node[i], prefix.isEmpty ? '$i' : '$prefix.$i'));
    }
  } else if (node is String) {
    out[prefix] = node;
  }
  return out;
}

List<String> _placeholders(String s) =>
    RegExp(r'\{[^{}]*\}').allMatches(s).map((m) => m.group(0)!).toList()..sort();

void main() {
  group('locale files', () {
    final dir = Directory('assets/locales');
    final english = _flatten(
      jsonDecode(File('assets/locales/en.json').readAsStringSync()),
    );

    test('every file is a known app language', () {
      for (final file in dir.listSync().whereType<File>()) {
        final code = file.uri.pathSegments.last.replaceAll('.json', '');
        expect(AppLanguage.supportedLanguages, contains(code), reason: file.path);
      }
    });

    test('translations keep English placeholders and only use English keys', () {
      for (final file in dir.listSync().whereType<File>()) {
        if (file.path.endsWith('en.json')) continue;
        final strings = _flatten(jsonDecode(file.readAsStringSync()));
        strings.forEach((key, text) {
          final source = english[key];
          if (source == null) {
            // Extra list items (e.g. more search keywords) are tolerated;
            // the translate script drops them. Any other unknown key is a typo.
            expect(RegExp(r'\.\d+$').hasMatch(key), isTrue, reason: '${file.path}: $key');
            return;
          }
          expect(
            _placeholders(text),
            _placeholders(source),
            reason: '${file.path}: $key — "$text"',
          );
        });
      }
    });

    test('picker metadata: native names, one entry per code, Arabic is RTL', () {
      final codes = AppLanguage.options.map((o) => o.code).toList();
      expect(codes.toSet().length, codes.length);
      expect(codes.first, 'en');
      expect(
        codes,
        containsAll(['es', 'pt', 'tr', 'ru', 'vi', 'id', 'ja', 'ko', 'ar', 'de']),
      );
      // Armenian is planned for later, not offered yet.
      expect(AppLanguage.optionFor('hy'), isNull);
      expect(AppLanguage.optionFor('tr')!.nativeName, 'Türkçe');
      expect(AppLanguage.optionFor('ar')!.rtl, isTrue);
      expect(AppLanguage.options.where((o) => o.rtl).map((o) => o.code), ['ar']);
    });
  });

  group('choosing the language', () {
    setUp(() => SharedPreferences.setMockInitialValues({
      'app_language_default_en_v1': true,
    }));

    test('saved choice wins, then the phone language, then English', () async {
      const available = {'en', 'es', 'de'};
      expect(
        await AppLanguage.resolveCurrent(available: available, deviceLanguage: 'es-MX'),
        'es',
      );
      expect(
        await AppLanguage.resolveCurrent(available: available, deviceLanguage: 'ja'),
        'en', // Japanese not shipped yet → English
      );
      await AppLanguage.setOverride('de');
      expect(
        await AppLanguage.resolveCurrent(available: available, deviceLanguage: 'es'),
        'de',
      );
    });

    test('a saved language whose file is gone falls back', () async {
      await AppLanguage.setOverride('ko');
      expect(
        await AppLanguage.resolveCurrent(available: {'en'}, deviceLanguage: 'fr'),
        'en',
      );
    });
  });

  group('AppLocalizations', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    setUp(() => SharedPreferences.setMockInitialValues({
      'app_language_default_en_v1': true,
      'app_language_override': 'en',
    }));

    test('missing keys fall back to English, not German', () async {
      final l10n = AppLocalizations.instance;
      await l10n.load();
      expect(l10n.t('profile.account.app-language-title'), 'App language');

      await l10n.setLanguage('de');
      expect(l10n.language, 'de');
      expect(l10n.t('profile.account.app-language-title'), 'App-Sprache');
      await l10n.setLanguage('en');

      // Any shipped language with a key it hasn't translated yet shows English
      // for it (translation files fill in over time).
      final english = _flatten(
        jsonDecode(File('assets/locales/en.json').readAsStringSync()),
      );
      for (final file in Directory('assets/locales').listSync().whereType<File>()) {
        final code = file.uri.pathSegments.last.replaceAll('.json', '');
        if (code == 'en') continue;
        final translated = _flatten(jsonDecode(file.readAsStringSync()));
        final missing = english.keys.where((k) => !translated.containsKey(k));
        if (missing.isEmpty) continue;
        await l10n.setLanguage(code);
        expect(l10n.t(missing.first), english[missing.first], reason: code);
      }
      await l10n.setLanguage('en');
    });

    test('only languages with a locale file are offered', () async {
      await AppLocalizations.instance.load();
      final shipped = Directory('assets/locales')
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last.replaceAll('.json', ''))
          .toSet();
      expect(
        AppLocalizations.instance.availableOptions.map((o) => o.code).toSet(),
        shipped,
      );
    });

    testWidgets('Settings → General lists languages by native name', (tester) async {
      // Tall screen, so every language in the picker sheet is built.
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.runAsync(AppLocalizations.instance.load);
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SingleChildScrollView(
          child: ProfileSettingsGeneralSection(),
        ))),
      );
      await tester.pumpAndSettle();
      expect(find.text('App language'), findsOneWidget);
      expect(
        find.textContaining('The language you practise is set'),
        findsOneWidget,
      );
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      // Every shipped language, by native name.
      for (final option in AppLocalizations.instance.availableOptions) {
        final label = option.code == 'en'
            ? option.nativeName
            : '${option.nativeName}  ·  ${option.englishName}';
        expect(find.text(label), findsWidgets, reason: option.code);
      }
      expect(find.text('Deutsch  ·  German'), findsOneWidget);
    });
  });
}
