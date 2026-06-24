import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:speakstack/services/flashcard_service.dart';
import 'package:speakstack/utils/file_download.dart';

class FlashcardExportService {
  FlashcardExportService._();
  static final FlashcardExportService instance = FlashcardExportService._();

  Map<int, String> _deckNames(Map<String, dynamic> data) {
    final decks = data['decks'] as List? ?? [];
    final names = <int, String>{};
    for (final raw in decks) {
      if (raw is! Map) continue;
      final id = raw['id'];
      if (id is int) {
        names[id] = raw['name']?.toString() ?? 'Deck';
      }
    }
    return names;
  }

  String toCsv(Map<String, dynamic> data) {
    final deckNames = _deckNames(data);
    final cards = data['cards'] as List? ?? [];
    final buffer = StringBuffer();
    buffer.writeln('Deck,Front,Back,Type,Tags,State,Due');

    for (final raw in cards) {
      if (raw is! Map) continue;
      final deckId = raw['deckId'] as int? ?? 0;
      final review = raw['reviewState'];
      final state =
          review is Map ? review['state']?.toString() ?? '' : '';
      final due =
          review is Map ? review['dueAt']?.toString() ?? '' : '';
      final tags = raw['tags'];
      final tagStr =
          tags is List ? tags.map((t) => t.toString()).join('; ') : '';

      buffer.writeln(
        [
          _csvCell(deckNames[deckId] ?? 'Deck'),
          _csvCell(raw['front']?.toString() ?? ''),
          _csvCell(raw['back']?.toString() ?? ''),
          _csvCell(raw['cardType']?.toString() ?? 'basic'),
          _csvCell(tagStr),
          _csvCell(state),
          _csvCell(due),
        ].join(','),
      );
    }
    return buffer.toString();
  }

  String _csvCell(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  Future<List<int>> toPdfBytes(Map<String, dynamic> data) async {
    final deckNames = _deckNames(data);
    final cards = data['cards'] as List? ?? [];
    final exportedAt = data['exportedAt']?.toString() ?? '';

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Flashcard export',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
            ),
            if (exportedAt.isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 12),
                child: pw.Text('Exported: $exportedAt', style: const pw.TextStyle(fontSize: 10)),
              ),
            ...cards.map((raw) {
              if (raw is! Map) return pw.SizedBox();
              final deckId = raw['deckId'] as int? ?? 0;
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      deckNames[deckId] ?? 'Deck',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      raw['front']?.toString() ?? '',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(raw['back']?.toString() ?? '', style: const pw.TextStyle(fontSize: 12)),
                  ],
                ),
              );
            }),
          ];
        },
      ),
    );

    return doc.save();
  }

  Future<void> exportCsv(Map<String, dynamic> data) async {
    final csv = toCsv(data);
    final bytes = utf8.encode('\uFEFF$csv');
    final filename =
        'flashcards_${DateTime.now().millisecondsSinceEpoch}.csv';
    if (kIsWeb) {
      downloadBytesInBrowser(
        filename: filename,
        bytes: bytes,
        mimeType: 'text/csv',
      );
    } else {
      await saveAndShareBytes(
        filename: filename,
        bytes: bytes,
        mimeType: 'text/csv',
      );
    }
  }

  Future<void> exportExcel(Map<String, dynamic> data) async {
    // Excel opens UTF-8 CSV reliably; use .csv extension with Excel MIME hint.
    final csv = toCsv(data);
    final bytes = utf8.encode('\uFEFF$csv');
    final filename =
        'flashcards_${DateTime.now().millisecondsSinceEpoch}.csv';
    if (kIsWeb) {
      downloadBytesInBrowser(
        filename: filename,
        bytes: bytes,
        mimeType: 'application/vnd.ms-excel',
      );
    } else {
      await saveAndShareBytes(
        filename: filename,
        bytes: bytes,
        mimeType: 'application/vnd.ms-excel',
      );
    }
  }

  Future<void> exportPdf(Map<String, dynamic> data) async {
    final bytes = await toPdfBytes(data);
    final filename =
        'flashcards_${DateTime.now().millisecondsSinceEpoch}.pdf';
    if (kIsWeb) {
      downloadBytesInBrowser(
        filename: filename,
        bytes: bytes,
        mimeType: 'application/pdf',
      );
    } else {
      await saveAndShareBytes(
        filename: filename,
        bytes: bytes,
        mimeType: 'application/pdf',
      );
    }
  }

  Future<void> exportApkg({int? deckId}) async {
    final bytes = await FlashcardService.instance.exportApkg(deckId: deckId);
    final filename =
        deckId != null
            ? 'deck_${deckId}_${DateTime.now().millisecondsSinceEpoch}.apkg'
            : 'flashcards_${DateTime.now().millisecondsSinceEpoch}.apkg';
    if (kIsWeb) {
      downloadBytesInBrowser(
        filename: filename,
        bytes: bytes,
        mimeType: 'application/octet-stream',
      );
    } else {
      await saveAndShareBytes(
        filename: filename,
        bytes: bytes,
        mimeType: 'application/octet-stream',
      );
    }
  }

  Future<void> exportJsonFile({int? deckId}) async {
    final data = await FlashcardService.instance.exportJson(deckId: deckId);
    if (data == null) return;
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    final bytes = utf8.encode(jsonStr);
    final filename =
        deckId != null
            ? 'deck_${deckId}_${DateTime.now().millisecondsSinceEpoch}.json'
            : 'flashcards_${DateTime.now().millisecondsSinceEpoch}.json';
    if (kIsWeb) {
      downloadBytesInBrowser(
        filename: filename,
        bytes: bytes,
        mimeType: 'application/json',
      );
    } else {
      await saveAndShareBytes(
        filename: filename,
        bytes: bytes,
        mimeType: 'application/json',
      );
    }
  }

  Future<void> shareExport(Map<String, dynamic> data) async {
    final csv = toCsv(data);
    final cardCount = (data['cards'] as List? ?? []).length;
    await Share.share(
      csv,
      subject: 'My flashcards ($cardCount cards)',
    );
  }
}
