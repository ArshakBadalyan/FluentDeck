import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:untitled2/models/flashcard_model.dart';
import 'package:untitled2/models/flashcard_stats_model.dart';
import 'package:untitled2/utils/statistics_labels.dart';
import 'package:untitled2/utils/file_download.dart';

class FlashcardStatsExportService {
  FlashcardStatsExportService._();
  static final FlashcardStatsExportService instance = FlashcardStatsExportService._();

  Future<List<int>> toPdfBytes(
    FlashcardDetailedStats stats, {
    List<FlashcardDeckModel> decks = const [],
  }) async {
    final scopeLabel = StatisticsLabels.scopeLabel(stats, decks);
    final rangeLabel = StatisticsLabels.rangeLabel(stats.range);

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Flashcard statistics',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Scope: $scopeLabel'),
          pw.Text('Range: $rangeLabel'),
          pw.SizedBox(height: 16),
          pw.Text('Today', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.Text('Reviews: ${stats.today.reviews}'),
          pw.Text('Study time: ${stats.today.durationLabel}'),
          pw.Text('Avg per card: ${stats.today.avgDurationMs}ms'),
          pw.SizedBox(height: 12),
          pw.Text('Card counts', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.Text('New: ${stats.cardCounts.newCount}'),
          pw.Text('Learning: ${stats.cardCounts.learning}'),
          pw.Text('Mature: ${stats.cardCounts.review}'),
          pw.Text('Suspended: ${stats.cardCounts.suspended}'),
          pw.Text('Buried: ${stats.cardCounts.buried}'),
          pw.SizedBox(height: 12),
          pw.Text('Answer buttons', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.Text('Again: ${stats.buttonCounts.again}'),
          pw.Text('Hard: ${stats.buttonCounts.hard}'),
          pw.Text('Good: ${stats.buttonCounts.good}'),
          pw.Text('Easy: ${stats.buttonCounts.easy}'),
          pw.SizedBox(height: 12),
          pw.Text('Total reviews in range: ${stats.totalReviewsInRange}'),
          if (stats.reviewStreakDays > 0)
            pw.Text('Review streak: ${stats.reviewStreakDays} days'),
        ],
      ),
    );
    return doc.save();
  }

  Future<void> exportPdf(
    FlashcardDetailedStats stats, {
    List<FlashcardDeckModel> decks = const [],
  }) async {
    final bytes = await toPdfBytes(stats, decks: decks);
    final filename = 'flashcard_stats_${DateTime.now().millisecondsSinceEpoch}.pdf';
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

  Future<void> sharePdf(
    FlashcardDetailedStats stats, {
    List<FlashcardDeckModel> decks = const [],
  }) async {
    final bytes = await toPdfBytes(stats, decks: decks);
    await Share.shareXFiles(
      [
        XFile.fromData(Uint8List.fromList(bytes), name: 'flashcard-stats.pdf', mimeType: 'application/pdf'),
      ],
      subject: 'Flashcard statistics',
    );
  }
}
