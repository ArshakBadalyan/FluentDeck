import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/models/flashcard_model.dart';
import 'package:fluentdeck/services/flashcard_service.dart';
import 'package:fluentdeck/ui_elements/frosted_bottom_sheet.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';

enum FlashcardImportFormat { csv, txt, apkg, json }

/// Pick a file and import flashcards (Phase 4G).
Future<FlashcardImportResult?> pickAndImportFlashcards(
  BuildContext context, {
  required FlashcardImportFormat format,
  int? deckId,
  bool createDecks = true,
  bool importScheduling = false,
}) async {
  final allowedExtensions = switch (format) {
    FlashcardImportFormat.csv => ['csv'],
    FlashcardImportFormat.txt => ['txt'],
    FlashcardImportFormat.apkg => ['apkg'],
    FlashcardImportFormat.json => ['json'],
  };

  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: allowedExtensions,
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;

  final file = result.files.first;
  final bytes = file.bytes;
  if (bytes == null) {
    throw Exception('Could not read file bytes');
  }

  switch (format) {
    case FlashcardImportFormat.csv:
      final csv = utf8.decode(bytes);
      return FlashcardService.instance.importCsv(
        csv,
        deckId: deckId,
        createDecks: createDecks,
      );
    case FlashcardImportFormat.txt:
      final text = utf8.decode(bytes);
      return FlashcardService.instance.importTxt(
        text,
        deckId: deckId,
        createDecks: createDecks,
      );
    case FlashcardImportFormat.apkg:
      return FlashcardService.instance.importApkgBytes(
        bytes,
        filename: file.name,
        deckId: deckId,
        createDecks: createDecks,
        importScheduling: importScheduling,
      );
    case FlashcardImportFormat.json:
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map) throw Exception('Invalid JSON backup');
      return FlashcardService.instance.importJsonBackup(
        Map<String, dynamic>.from(decoded),
        createDecks: createDecks,
      );
  }
}

Future<void> showImportResultSnackBar(
  BuildContext context,
  FlashcardImportResult result,
) async {
  final msg =
      result.imported > 0
          ? 'Imported ${result.imported} note${result.imported == 1 ? '' : 's'}'
              '${result.skipped > 0 ? ' (${result.skipped} skipped)' : ''}'
          : 'No cards imported${result.skipped > 0 ? ' (${result.skipped} skipped)' : ''}';

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      duration: const Duration(seconds: 4),
    ),
  );

  if (result.errors.isNotEmpty && context.mounted) {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder:
          (ctx) => Dialog(
            backgroundColor: AppPageColors.cardBgOf(ctx),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Import warnings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: SingleChildScrollView(
                      child: Text(result.errors.join('\n')),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                      ),
                      child: const Text('OK'),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

Future<void> _runImport(
  BuildContext context, {
  required FlashcardImportFormat format,
  int? deckId,
  bool createDecks = true,
  bool importScheduling = false,
  VoidCallback? onImported,
}) async {
  try {
    final result = await pickAndImportFlashcards(
      context,
      format: format,
      deckId: deckId,
      createDecks: createDecks,
      importScheduling: importScheduling,
    );
    if (result != null && context.mounted) {
      await showImportResultSnackBar(context, result);
      onImported?.call();
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}

Future<void> showFlashcardImportSheet(
  BuildContext context, {
  List<FlashcardDeckModel> decks = const [],
  VoidCallback? onImported,
}) async {
  int? targetDeckId;
  var createDecks = true;
  var importScheduling = false;

  await showFrostedBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    useSafeArea: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          final realDecks =
              decks.where((d) => !d.isFiltered).toList()
                ..sort((a, b) => a.name.compareTo(b.name));

          Future<void> importAndClose(FlashcardImportFormat format) async {
            Navigator.pop(ctx);
            await _runImport(
              context,
              format: format,
              deckId: targetDeckId,
              createDecks: createDecks,
              importScheduling: importScheduling,
              onImported: onImported,
            );
          }

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.78,
            minChildSize: 0.45,
            maxChildSize: 0.92,
            builder: (context, scrollController) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppSheetHandle(),
                  const AppSheetHeader(
                    title: 'Import flashcards',
                    subtitle: 'Bring cards in from a file or backup',
                    icon: Icons.file_download_outlined,
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: [
                        DropdownButtonFormField<int?>(
                          initialValue: targetDeckId,
                          isExpanded: true,
                          decoration: appSheetFieldDecoration(
                            label: 'Default deck (optional)',
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Use deck column / #deck: header'),
                            ),
                            ...realDecks.map(
                              (d) => DropdownMenuItem<int?>(
                                value: d.id,
                                child: Text(d.name, overflow: TextOverflow.ellipsis),
                              ),
                            ),
                          ],
                          onChanged: (v) => setLocal(() => targetDeckId = v),
                        ),
                        const SizedBox(height: 8),
                        AppToggleRow(
                          title: 'Create missing decks',
                          subtitle: 'From CSV Deck column or #deck: lines',
                          value: createDecks,
                          onChanged: (v) => setLocal(() => createDecks = v),
                        ),
                        AppToggleRow(
                          title: 'Import review scheduling (.apkg)',
                          subtitle: 'Preserve due dates and intervals from the source deck',
                          value: importScheduling,
                          onChanged: (v) => setLocal(() => importScheduling = v),
                        ),
                        const SizedBox(height: 12),
                        AppSheetActionTile(
                          icon: Icons.table_chart_outlined,
                          title: 'Import CSV',
                          subtitle: 'Columns: Front, Back, Deck, Tags',
                          onTap: () => importAndClose(FlashcardImportFormat.csv),
                        ),
                        AppSheetActionTile(
                          icon: Icons.description_outlined,
                          title: 'Import TXT',
                          subtitle: 'Plain text (#deck:, tab-separated)',
                          onTap: () => importAndClose(FlashcardImportFormat.txt),
                        ),
                        AppSheetActionTile(
                          icon: Icons.archive_outlined,
                          title: 'Import deck package (.apkg)',
                          subtitle: 'Compatible with common flashcard apps',
                          onTap: () => importAndClose(FlashcardImportFormat.apkg),
                        ),
                        AppSheetActionTile(
                          icon: Icons.restore_outlined,
                          title: 'Restore JSON backup',
                          subtitle: 'Full collection backup from export',
                          onTap: () => importAndClose(FlashcardImportFormat.json),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    },
  );
}

/// Export format picker sheet — returns format id (apkg, csv, excel, pdf, json, share).
Future<String?> showFlashcardExportSheet(BuildContext context) {
  return showFrostedBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    useSafeArea: true,
    builder: (ctx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.62,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        builder: (context, scrollController) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppSheetHandle(),
              const AppSheetHeader(
                title: 'Export flashcards',
                subtitle: 'Save or share your collection',
                icon: Icons.file_upload_outlined,
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    AppSheetActionTile(
                      icon: Icons.archive_outlined,
                      title: 'Deck package (.apkg)',
                      subtitle: 'Compatible with common flashcard apps',
                      onTap: () => Navigator.pop(ctx, 'apkg'),
                    ),
                    AppSheetActionTile(
                      icon: Icons.table_chart_outlined,
                      title: 'CSV file',
                      subtitle: 'Spreadsheet-friendly format',
                      onTap: () => Navigator.pop(ctx, 'csv'),
                    ),
                    AppSheetActionTile(
                      icon: Icons.grid_on_outlined,
                      title: 'Excel file',
                      subtitle: 'Opens in Microsoft Excel',
                      onTap: () => Navigator.pop(ctx, 'excel'),
                    ),
                    AppSheetActionTile(
                      icon: Icons.picture_as_pdf_outlined,
                      title: 'PDF file',
                      subtitle: 'Printable card list',
                      onTap: () => Navigator.pop(ctx, 'pdf'),
                    ),
                    AppSheetActionTile(
                      icon: Icons.data_object_outlined,
                      title: 'JSON backup',
                      subtitle: 'Full collection backup',
                      onTap: () => Navigator.pop(ctx, 'json'),
                    ),
                    AppSheetActionTile(
                      icon: Icons.share_outlined,
                      title: 'Share CSV',
                      subtitle: 'Send via messages, email, etc.',
                      onTap: () => Navigator.pop(ctx, 'share'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
