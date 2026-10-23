import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:fluentdeck/models/flashcard_model.dart';
import 'package:fluentdeck/screens/learn_screen/shared_decks_screen.dart';
import 'package:fluentdeck/services/flashcard_import_service.dart';
import 'package:fluentdeck/services/flashcard_service.dart';
import 'package:fluentdeck/ui_elements/app_toast.dart';
import 'package:fluentdeck/utils/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Returns [file] (or nothing when null) and records what was asked for.
class FakeFilePicker extends FilePicker {
  PlatformFile? file;
  List<String>? allowedExtensions;
  bool? withData;
  int calls = 0;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    calls++;
    this.allowedExtensions = allowedExtensions;
    this.withData = withData;
    return file == null ? null : FilePickerResult([file!]);
  }
}

PlatformFile _file(String name, List<int>? bytes) =>
    PlatformFile(
      name: name,
      size: bytes?.length ?? 0,
      bytes: bytes == null ? null : Uint8List.fromList(bytes),
    );

/// Captures requests and answers with [respond] (default: 3 imported, 1 skipped).
class FakeServer {
  final requests = <http.Request>[];
  http.Response Function(http.Request)? respond;

  MockClient get client => MockClient((req) async {
    requests.add(req);
    return respond?.call(req) ??
        http.Response(
          jsonEncode({'ok': true, 'imported': 3, 'skipped': 1, 'errors': []}),
          200,
          headers: {'content-type': 'application/json'},
        );
  });

  Map<String, dynamic> get lastJson =>
      jsonDecode(requests.last.body) as Map<String, dynamic>;
}

void main() {
  late FakeFilePicker picker;
  late FakeServer server;

  setUp(() {
    dotenv.testLoad(fileInput: 'API_URL=https://api.test/api');
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({'token': 'jwt-123'});
    picker = FakeFilePicker();
    FilePicker.platform = picker;
    server = FakeServer();
  });

  Future<T> withServer<T>(Future<T> Function() body) =>
      http.runWithClient(body, () => server.client);

  group('FlashcardService import requests', () {
    test('CSV posts text, deck and createDecks with the auth token', () async {
      final result = await withServer(
        () => FlashcardService.instance.importCsv(
          'Front,Back\nhi,bonjour',
          deckId: 4,
        ),
      );

      final req = server.requests.single;
      expect(req.method, 'POST');
      expect(req.url.toString(), 'https://api.test/api/flashcards/import/csv');
      expect(req.headers['Authorization'], 'Bearer jwt-123');
      expect(server.lastJson, {
        'csv': 'Front,Back\nhi,bonjour',
        'deckId': 4,
        'createDecks': true,
      });
      expect(result.imported, 3);
      expect(result.skipped, 1);
    });

    test('TXT leaves out deckId when none is chosen', () async {
      await withServer(
        () => FlashcardService.instance.importTxt(
          '#deck:Travel\nhi\tbonjour',
          createDecks: false,
        ),
      );
      expect(server.requests.single.url.path, '/api/flashcards/import/txt');
      expect(server.lastJson, {
        'text': '#deck:Travel\nhi\tbonjour',
        'createDecks': false,
      });
    });

    test('APKG is sent as multipart with filename and options', () async {
      await withServer(
        () => FlashcardService.instance.importApkgBytes(
          [1, 2, 3],
          filename: 'french.apkg',
          deckId: 9,
          importScheduling: true,
        ),
      );
      final req = server.requests.single;
      expect(req.url.path, '/api/flashcards/import/apkg');
      expect(req.headers['content-type'], startsWith('multipart/form-data'));
      final body = latin1.decode(req.bodyBytes);
      expect(body, contains('name="file"; filename="french.apkg"'));
      expect(body, contains('name="deckId"\r\n\r\n9'));
      expect(body, contains('name="createDecks"\r\n\r\ntrue'));
      expect(body, contains('name="importScheduling"\r\n\r\ntrue'));
    });

    test('JSON backup posts the decoded backup', () async {
      await withServer(
        () => FlashcardService.instance.importJsonBackup({
          'cards': [
            {'front': 'a', 'back': 'b'},
          ],
        }),
      );
      expect(server.requests.single.url.path, '/api/flashcards/import/json');
      expect(server.lastJson['data'], {
        'cards': [
          {'front': 'a', 'back': 'b'},
        ],
      });
      expect(server.lastJson['createDecks'], true);
    });

    test('server refusal (free deck limit) surfaces as ApiException', () async {
      server.respond = (_) => http.Response(
        jsonEncode({
          'error': {'message': 'Free tier limit: 1 custom deck(s).'},
        }),
        403,
      );
      await expectLater(
        withServer(() => FlashcardService.instance.importCsv('a,b')),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 403)
              .having((e) => e.message, 'message', contains('Free tier limit')),
        ),
      );
    });
  });

  group('FlashcardImportResult.fromJson', () {
    test('reads counts and errors', () {
      final r = FlashcardImportResult.fromJson({
        'ok': true,
        'imported': 2,
        'skipped': 1,
        'errors': ['row 3: empty'],
      });
      expect(r.ok, isTrue);
      expect(r.imported, 2);
      expect(r.skipped, 1);
      expect(r.errors, ['row 3: empty']);
    });

    test('missing fields default to zero', () {
      final r = FlashcardImportResult.fromJson(<String, dynamic>{});
      expect(r.imported, 0);
      expect(r.skipped, 0);
      expect(r.errors, isEmpty);
    });

    test('an error body or a non-object throws', () {
      expect(
        () => FlashcardImportResult.fromJson({
          'error': {'message': 'bad file'},
        }),
        throwsA(predicate((e) => '$e'.contains('bad file'))),
      );
      expect(() => FlashcardImportResult.fromJson('oops'), throwsException);
    });
  });

  group('pickAndImportFlashcards', () {
    late BuildContext context;

    Future<void> pumpContext(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      );
    }

    testWidgets('CSV: limits the picker to .csv and sends UTF-8 text', (
      tester,
    ) async {
      await pumpContext(tester);
      picker.file = _file('words.csv', utf8.encode('Front,Back\nբարև,hello'));

      final result = await tester.runAsync(
        () => withServer(
          () => pickAndImportFlashcards(
            context,
            format: FlashcardImportFormat.csv,
            createDecks: false,
          ),
        ),
      );

      expect(picker.allowedExtensions, ['csv']);
      expect(picker.withData, isTrue);
      expect(server.lastJson['csv'], 'Front,Back\nբարև,hello');
      expect(server.lastJson['createDecks'], false);
      expect(result!.imported, 3);
    });

    testWidgets('each format asks for its own extension and endpoint', (
      tester,
    ) async {
      await pumpContext(tester);
      final cases = {
        FlashcardImportFormat.txt: ('deck.txt', 'txt', '/api/flashcards/import/txt'),
        FlashcardImportFormat.apkg: ('deck.apkg', 'apkg', '/api/flashcards/import/apkg'),
        FlashcardImportFormat.json: ('backup.json', 'json', '/api/flashcards/import/json'),
      };
      for (final entry in cases.entries) {
        final (name, ext, endpoint) = entry.value;
        picker.file = _file(name, utf8.encode(ext == 'json' ? '{"cards":[]}' : 'a\tb'));
        await tester.runAsync(
          () => withServer(
            () => pickAndImportFlashcards(context, format: entry.key),
          ),
        );
        expect(picker.allowedExtensions, [ext], reason: '$ext picker');
        expect(server.requests.last.url.path, endpoint, reason: '$ext endpoint');
      }
    });

    testWidgets('cancelling the picker imports nothing', (tester) async {
      await pumpContext(tester);
      picker.file = null;
      final result = await tester.runAsync(
        () => withServer(
          () => pickAndImportFlashcards(context, format: FlashcardImportFormat.csv),
        ),
      );
      expect(result, isNull);
      expect(server.requests, isEmpty);
    });

    testWidgets('a file without bytes is an error', (tester) async {
      await pumpContext(tester);
      picker.file = _file('words.csv', null);
      // runAsync reports errors via takeException instead of rethrowing.
      await tester.runAsync(
        () => pickAndImportFlashcards(context, format: FlashcardImportFormat.csv),
      );
      expect('${tester.takeException()}', contains('Could not read file bytes'));
    });

    testWidgets('a JSON file that is not an object is rejected locally', (
      tester,
    ) async {
      await pumpContext(tester);
      picker.file = _file('backup.json', utf8.encode('[1, 2, 3]'));
      await tester.runAsync(
        () => withServer(
          () => pickAndImportFlashcards(context, format: FlashcardImportFormat.json),
        ),
      );
      expect('${tester.takeException()}', contains('Invalid JSON backup'));
      expect(server.requests, isEmpty);
    });
  });

  group('Shared decks screen', () {
    /// Opens SharedDecksScreen from a host page and records what it returns.
    Future<List<Object?>> pumpShared(
      WidgetTester tester, {
      List<FlashcardDeckModel> decks = const [],
    }) async {
      final popped = <Object?>[];
      // Tall enough that the whole import sheet (a lazy list) is built.
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => AppToastHost(child: child!),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  popped.add(
                    await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => SharedDecksScreen(decks: decks),
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return popped;
    }

    tearDown(AppToast.dismissAll);

    testWidgets('without a web URL the browse button says Coming soon', (
      tester,
    ) async {
      await pumpShared(tester);
      expect(find.text('Coming soon'), findsOneWidget);
      expect(find.text('Open shared decks'), findsNothing);

      await tester.tap(find.text('Coming soon'));
      await tester.pump();
      expect(find.text('Shared decks page is coming soon.'), findsOneWidget);
      AppToast.dismissAll();
      await tester.pumpAndSettle();
    });

    testWidgets('with SHARED_DECKS_WEB_URL the browse button opens the site', (
      tester,
    ) async {
      dotenv.testLoad(
        fileInput:
            'API_URL=https://api.test/api\nSHARED_DECKS_WEB_URL=https://fluentdeck.com/decks',
      );
      await pumpShared(tester);
      expect(find.text('Open shared decks'), findsOneWidget);
      expect(find.text('Opens fluentdeck.com in your browser'), findsOneWidget);
      expect(find.text('Coming soon'), findsNothing);
    });

    testWidgets('Import a file opens the import sheet with every format', (
      tester,
    ) async {
      await pumpShared(tester);
      await tester.tap(find.text('Import a file'));
      await tester.pumpAndSettle();

      expect(find.text('Import flashcards'), findsOneWidget);
      for (final label in [
        'Import CSV',
        'Import TXT',
        'Import deck package (.apkg)',
        'Restore JSON backup',
        'Create missing decks',
        'Import review scheduling (.apkg)',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('importing a CSV shows the result and returns to Decks', (
      tester,
    ) async {
      final popped = await pumpShared(tester);
      picker.file = _file('words.csv', utf8.encode('Front,Back\nhi,bonjour'));

      await tester.tap(find.text('Import a file'));
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => withServer(() async {
          await tester.tap(find.text('Import CSV'));
          // Let the picker + mocked request finish on real async.
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }),
      );
      await tester.pumpAndSettle();

      expect(server.requests.single.url.path, '/api/flashcards/import/csv');
      expect(find.text('Imported 3 notes (1 skipped)'), findsOneWidget);
      expect(popped, [true], reason: 'screen closes with "imported"');
      expect(find.byType(SharedDecksScreen), findsNothing);
      AppToast.dismissAll();
      await tester.pumpAndSettle();
    });

    testWidgets('a server error during import is shown, screen stays open', (
      tester,
    ) async {
      server.respond = (_) => http.Response(
        jsonEncode({
          'error': {'message': 'Free tier limit: 1 custom deck(s).'},
        }),
        403,
      );
      final popped = await pumpShared(tester);
      picker.file = _file('words.csv', utf8.encode('a,b'));

      await tester.tap(find.text('Import a file'));
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => withServer(() async {
          await tester.tap(find.text('Import CSV'));
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Free tier limit'), findsOneWidget);
      expect(popped, isEmpty);
      expect(find.byType(SharedDecksScreen), findsOneWidget);
      AppToast.dismissAll();
      await tester.pumpAndSettle();
    });
  });

  group('showImportResultSnackBar', () {
    Future<void> show(WidgetTester tester, FlashcardImportResult result) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => AppToastHost(child: child!),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showImportResultSnackBar(context, result),
              child: const Text('go'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
    }

    tearDown(AppToast.dismissAll);

    testWidgets('singular note, no skipped', (tester) async {
      await show(tester, const FlashcardImportResult(imported: 1));
      expect(find.text('Imported 1 note'), findsOneWidget);
      AppToast.dismissAll();
      await tester.pumpAndSettle();
    });

    testWidgets('nothing imported', (tester) async {
      await show(tester, const FlashcardImportResult(skipped: 2));
      expect(find.text('No cards imported (2 skipped)'), findsOneWidget);
      AppToast.dismissAll();
      await tester.pumpAndSettle();
    });

    testWidgets('row errors open an Import warnings dialog', (tester) async {
      await show(
        tester,
        const FlashcardImportResult(
          imported: 1,
          skipped: 1,
          errors: ['row 2: missing front'],
        ),
      );
      expect(find.text('Import warnings'), findsOneWidget);
      expect(find.text('row 2: missing front'), findsOneWidget);
      AppToast.dismissAll();
      await tester.pumpAndSettle();
    });
  });
}
