import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:riovox/services/flashcard_service.dart';
import 'package:riovox/utils/file_download.dart';

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

  static const _columns = ['Deck', 'Front', 'Back', 'Type', 'Tags', 'State', 'Due'];

  /// One row per card, in [_columns] order (shared by CSV and Excel).
  List<List<String>> _rows(Map<String, dynamic> data) {
    final deckNames = _deckNames(data);
    final cards = data['cards'] as List? ?? [];
    final rows = <List<String>>[];

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

      rows.add([
        deckNames[deckId] ?? 'Deck',
        raw['front']?.toString() ?? '',
        raw['back']?.toString() ?? '',
        raw['cardType']?.toString() ?? 'basic',
        tagStr,
        state,
        due,
      ]);
    }
    return rows;
  }

  String toCsv(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    buffer.writeln(_columns.join(','));
    for (final row in _rows(data)) {
      buffer.writeln(row.map(_csvCell).join(','));
    }
    return buffer.toString();
  }

  /// A minimal one-sheet .xlsx (Office Open XML zip) with a bold header row.
  List<int> toXlsxBytes(Map<String, dynamic> data) {
    String esc(String v) => v
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        // Control chars other than tab/newline are invalid in XML.
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
    String row(List<String> cells, {bool header = false}) {
      final style = header ? ' s="1"' : '';
      final cs = cells
          .map((c) => '<c t="inlineStr"$style><is><t xml:space="preserve">${esc(c)}</t></is></c>')
          .join();
      return '<row>$cs</row>';
    }

    final sheetRows = [
      row(_columns, header: true),
      ..._rows(data).map(row),
    ].join();

    const xmlHead = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>';
    final archive = Archive()
      ..addFile(ArchiveFile.string('[Content_Types].xml', '$xmlHead'
          '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
          '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
          '<Default Extension="xml" ContentType="application/xml"/>'
          '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
          '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
          '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
          '</Types>'))
      ..addFile(ArchiveFile.string('_rels/.rels', '$xmlHead'
          '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
          '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
          '</Relationships>'))
      ..addFile(ArchiveFile.string('xl/workbook.xml', '$xmlHead'
          '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
          'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
          '<sheets><sheet name="Flashcards" sheetId="1" r:id="rId1"/></sheets></workbook>'))
      ..addFile(ArchiveFile.string('xl/_rels/workbook.xml.rels', '$xmlHead'
          '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
          '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>'
          '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
          '</Relationships>'))
      ..addFile(ArchiveFile.string('xl/styles.xml', '$xmlHead'
          '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
          '<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font>'
          '<font><b/><sz val="11"/><name val="Calibri"/></font></fonts>'
          '<fills count="2"><fill><patternFill patternType="none"/></fill>'
          '<fill><patternFill patternType="gray125"/></fill></fills>'
          '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>'
          '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
          '<cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
          '<xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/></cellXfs>'
          '</styleSheet>'))
      ..addFile(ArchiveFile.string('xl/worksheets/sheet1.xml', '$xmlHead'
          '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
          '<sheetData>$sheetRows</sheetData></worksheet>'));
    return ZipEncoder().encodeBytes(archive);
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
                      style: const pw.TextStyle(
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
    const mimeType =
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    final bytes = toXlsxBytes(data);
    final filename =
        'flashcards_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    if (kIsWeb) {
      downloadBytesInBrowser(
        filename: filename,
        bytes: bytes,
        mimeType: mimeType,
      );
    } else {
      await saveAndShareBytes(
        filename: filename,
        bytes: bytes,
        mimeType: mimeType,
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
