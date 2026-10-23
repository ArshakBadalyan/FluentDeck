import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluentdeck/services/flashcard_export_service.dart';

void main() {
  final service = FlashcardExportService.instance;

  final sampleData = {
    'decks': [
      {'id': 1, 'name': 'Verbs & "Nouns"'},
    ],
    'cards': [
      {
        'deckId': 1,
        'front': '<b>go</b>',
        'back': 'gehen & tun',
        'cardType': 'basic',
        'tags': ['a', 'b'],
        'reviewState': {'state': 'new', 'dueAt': null},
      },
      {
        'deckId': 1,
        'front': 'walk',
        'back': 'gehen',
        'cardType': 'basic',
        'tags': [],
      },
    ],
  };

  group('toCsv', () {
    test('keeps the Excel-style CSV shape with a header row', () {
      final csv = service.toCsv(sampleData);
      final lines = csv.trim().split('\n');
      expect(lines.first, 'Deck,Front,Back,Type,Tags,State,Due');
      expect(lines.length, 3); // header + 2 cards
      expect(lines[1], contains('<b>go</b>'));
      expect(lines[1], contains('"a; b"'));
    });
  });

  group('toXlsxBytes', () {
    late List<int> bytes;
    late Archive archive;

    setUp(() {
      bytes = service.toXlsxBytes(sampleData);
      archive = ZipDecoder().decodeBytes(bytes);
    });

    // Regression test: exportExcel used to write a renamed .csv file. This
    // checks the bytes are an actual zip (every .xlsx is one) with the parts
    // Excel/Sheets require, not just a CSV with a different extension.
    test('is a real zip archive, not a CSV in disguise', () {
      expect(bytes.length, greaterThan(4));
      // Zip local file header magic ("PK\x03\x04").
      expect(bytes[0], 0x50);
      expect(bytes[1], 0x4B);
      expect(archive.files, isNotEmpty);
    });

    test('contains the parts required by the OOXML spreadsheet format', () {
      const required = [
        '[Content_Types].xml',
        '_rels/.rels',
        'xl/workbook.xml',
        'xl/_rels/workbook.xml.rels',
        'xl/styles.xml',
        'xl/worksheets/sheet1.xml',
      ];
      for (final name in required) {
        expect(archive.findFile(name), isNotNull, reason: 'missing $name');
      }
    });

    test('sheet has one row per card plus a header row', () {
      final sheet = String.fromCharCodes(
        archive.findFile('xl/worksheets/sheet1.xml')!.content as List<int>,
      );
      final rowCount = RegExp('<row>').allMatches(sheet).length;
      expect(rowCount, sampleData['cards']!.length + 1);
      expect(sheet, contains('<t xml:space="preserve">Deck</t>'));
      expect(sheet, contains('<t xml:space="preserve">walk</t>'));
    });

    test('escapes XML special characters instead of breaking the document', () {
      final sheet = String.fromCharCodes(
        archive.findFile('xl/worksheets/sheet1.xml')!.content as List<int>,
      );
      // Deck name has an unescaped & and "; card front has < and >.
      expect(sheet, contains('&amp;'));
      expect(sheet, contains('&quot;'));
      expect(sheet, contains('&lt;b&gt;go&lt;/b&gt;'));
      // No raw '&' that isn't part of an entity.
      expect(RegExp(r'&(?!amp;|lt;|gt;|quot;|apos;)').hasMatch(sheet), isFalse);
    });

    test('header row cells use the bold style', () {
      final sheet = String.fromCharCodes(
        archive.findFile('xl/worksheets/sheet1.xml')!.content as List<int>,
      );
      final headerRow = RegExp('<row>.*?</row>').firstMatch(sheet)!.group(0)!;
      expect(headerRow, contains('s="1"'));
    });

    test('control characters invalid in XML are stripped, not left raw', () {
      final withControlChar = {
        'decks': [
          {'id': 1, 'name': 'Deck'},
        ],
        'cards': [
          {
            'deckId': 1,
            'front': 'bad\u0001char',
            'back': 'ok',
            'cardType': 'basic',
            'tags': [],
          },
        ],
      };
      final b = service.toXlsxBytes(withControlChar);
      final a = ZipDecoder().decodeBytes(b);
      final sheet = String.fromCharCodes(
        a.findFile('xl/worksheets/sheet1.xml')!.content as List<int>,
      );
      expect(sheet, contains('badchar'));
      expect(sheet.contains('\u0001'), isFalse);
    });

    test('an empty card list still produces a valid workbook', () {
      final b = service.toXlsxBytes({'decks': [], 'cards': []});
      final a = ZipDecoder().decodeBytes(b);
      final sheet = String.fromCharCodes(
        a.findFile('xl/worksheets/sheet1.xml')!.content as List<int>,
      );
      expect(RegExp('<row>').allMatches(sheet).length, 1); // header only
    });
  });
}
