import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:untitled2/models/flashcard_model.dart';
import 'package:untitled2/services/flashcard_service.dart';

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
      builder:
          (ctx) => AlertDialog(
            title: const Text('Import warnings'),
            content: SingleChildScrollView(
              child: Text(result.errors.join('\n')),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
    );
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

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          final realDecks =
              decks.where((d) => !d.isFiltered).toList()
                ..sort((a, b) => a.name.compareTo(b.name));

          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  const Text(
                    'Import flashcards',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    initialValue: targetDeckId,
                    decoration: const InputDecoration(
                      labelText: 'Default deck (optional)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Use deck column / #deck: header'),
                      ),
                      ...realDecks.map(
                        (d) => DropdownMenuItem<int?>(
                          value: d.id,
                          child: Text(d.name),
                        ),
                      ),
                    ],
                    onChanged: (v) => setLocal(() => targetDeckId = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Create missing decks'),
                    subtitle: const Text('From CSV Deck column or #deck: lines'),
                    value: createDecks,
                    onChanged: (v) => setLocal(() => createDecks = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Import review scheduling (.apkg)'),
                    subtitle: const Text('Preserve due dates and intervals from Anki'),
                    value: importScheduling,
                    onChanged: (v) => setLocal(() => importScheduling = v),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.table_chart_outlined),
                    title: const Text('Import CSV'),
                    subtitle: const Text('Columns: Front, Back, Deck, Tags'),
                    onTap: () async {
                      Navigator.pop(ctx);
                      try {
                        final result = await pickAndImportFlashcards(
                          context,
                          format: FlashcardImportFormat.csv,
                          deckId: targetDeckId,
                          createDecks: createDecks,
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
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('Import TXT'),
                    subtitle: const Text('Anki plain-text (#deck:, tab-separated)'),
                    onTap: () async {
                      Navigator.pop(ctx);
                      try {
                        final result = await pickAndImportFlashcards(
                          context,
                          format: FlashcardImportFormat.txt,
                          deckId: targetDeckId,
                          createDecks: createDecks,
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
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.archive_outlined),
                    title: const Text('Import Anki .apkg'),
                    subtitle: const Text('Deck package from Anki / AnkiDroid'),
                    onTap: () async {
                      Navigator.pop(ctx);
                      try {
                        final result = await pickAndImportFlashcards(
                          context,
                          format: FlashcardImportFormat.apkg,
                          deckId: targetDeckId,
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
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.restore_outlined),
                    title: const Text('Restore JSON backup'),
                    subtitle: const Text('Full collection backup from export'),
                    onTap: () async {
                      Navigator.pop(ctx);
                      try {
                        final result = await pickAndImportFlashcards(
                          context,
                          format: FlashcardImportFormat.json,
                          createDecks: createDecks,
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
                    },
                  ),
                ],
              ),
            ),
            ),
          );
        },
      );
    },
  );
}
