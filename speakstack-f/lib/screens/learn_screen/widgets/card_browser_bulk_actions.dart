import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:untitled2/app_colors.dart';
import 'package:untitled2/models/flashcard_model.dart';
import 'package:untitled2/services/card_tag_undo_store.dart';
import 'package:untitled2/services/flashcard_service.dart';

enum BulkTagMode { add, remove, replace }

/// Card browser bulk selection actions (Step 4 AnkiDroid parity).
class CardBrowserBulkActions {
  CardBrowserBulkActions({
    required this.context,
    required this.selectedCards,
    required this.decks,
    required this.onComplete,
  });

  final BuildContext context;
  final List<FlashcardModel> selectedCards;
  final List<FlashcardDeckModel> decks;
  final Future<void> Function() onComplete;

  Set<int> get _noteIds =>
      selectedCards
          .where((c) => c.noteId != null)
          .map((c) => c.noteId!)
          .toSet();

  static Future<void> showMenu(
    BuildContext context, {
    required List<FlashcardModel> selectedCards,
    required List<FlashcardDeckModel> decks,
    required Future<void> Function() onComplete,
  }) async {
    final hasBulkUndo = await CardTagUndoStore.instance.hasBulkUndo();
    if (!context.mounted) return;

    final itemCount = 8 + (hasBulkUndo ? 1 : 0);

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (ctx) => SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${selectedCards.length} selected',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.pause_circle_outline),
                  title: const Text('Suspend'),
                  onTap: () => Navigator.pop(ctx, 'suspend'),
                ),
                ListTile(
                  leading: const Icon(Icons.play_circle_outline),
                  title: const Text('Unsuspend'),
                  onTap: () => Navigator.pop(ctx, 'unsuspend'),
                ),
                ListTile(
                  leading: const Icon(Icons.layers_clear_outlined),
                  title: const Text('Bury'),
                  onTap: () => Navigator.pop(ctx, 'bury'),
                ),
                ListTile(
                  leading: const Icon(Icons.layers_outlined),
                  title: const Text('Unbury'),
                  onTap: () => Navigator.pop(ctx, 'unbury'),
                ),
                ListTile(
                  leading: const Icon(Icons.drive_file_move_outline),
                  title: const Text('Change deck'),
                  onTap: () => Navigator.pop(ctx, 'deck'),
                ),
                ListTile(
                  leading: const Icon(Icons.label_outline),
                  title: const Text('Edit tags'),
                  onTap: () => Navigator.pop(ctx, 'tags'),
                ),
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('Export cards'),
                  onTap: () => Navigator.pop(ctx, 'export'),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Delete notes', style: TextStyle(color: Colors.red)),
                  onTap: () => Navigator.pop(ctx, 'delete'),
                ),
                if (hasBulkUndo)
                  ListTile(
                    leading: Icon(Icons.undo, color: AppColors.primaryPurple),
                    title: const Text('Undo tag change'),
                    onTap: () => Navigator.pop(ctx, 'undo_tags'),
                  ),
                const SizedBox(height: 8),
              ],
            ),
            ),
          ),
    );

    if (!context.mounted || action == null) return;

    final bulk = CardBrowserBulkActions(
      context: context,
      selectedCards: selectedCards,
      decks: decks,
      onComplete: onComplete,
    );

    try {
      switch (action) {
        case 'suspend':
          await bulk.suspend();
        case 'unsuspend':
          await bulk.unsuspend();
        case 'bury':
          await bulk.bury();
        case 'unbury':
          await bulk.unbury();
        case 'deck':
          await bulk.changeDeck();
        case 'tags':
          await bulk.editTags();
        case 'export':
          await bulk.exportCards();
          return;
        case 'delete':
          await bulk.deleteNotes();
        case 'undo_tags':
          await bulk.undoTagChange();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> suspend() async {
    for (final card in selectedCards) {
      if (card.reviewState?.suspended != true) {
        await FlashcardService.instance.suspendCard(card.id);
      }
    }
    await _done('Suspended selected cards');
  }

  Future<void> unsuspend() async {
    for (final card in selectedCards) {
      if (card.reviewState?.suspended == true) {
        await FlashcardService.instance.unsuspendCard(card.id);
      }
    }
    await _done('Unsuspended selected cards');
  }

  Future<void> bury() async {
    for (final card in selectedCards) {
      final buried =
          card.reviewState?.buriedUntil != null &&
          card.reviewState!.buriedUntil!.isAfter(DateTime.now());
      if (!buried) {
        await FlashcardService.instance.buryCard(card.id);
      }
    }
    await _done('Buried selected cards');
  }

  Future<void> unbury() async {
    for (final card in selectedCards) {
      final buried =
          card.reviewState?.buriedUntil != null &&
          card.reviewState!.buriedUntil!.isAfter(DateTime.now());
      if (buried) {
        await FlashcardService.instance.unburyCard(card.id);
      }
    }
    await _done('Unburied selected cards');
  }

  Future<void> changeDeck() async {
    if (_noteIds.isEmpty) throw Exception('Selected cards have no linked notes');
    if (decks.isEmpty) throw Exception('No decks available');

    final targetId = await showDialog<int>(
      context: context,
      builder:
          (ctx) => SimpleDialog(
            title: const Text('Change deck'),
            children:
                decks
                    .map(
                      (d) => SimpleDialogOption(
                        onPressed: () => Navigator.pop(ctx, d.id),
                        child: Text(d.name),
                      ),
                    )
                    .toList(),
          ),
    );
    if (targetId == null) return;

    for (final noteId in _noteIds) {
      await FlashcardService.instance.updateNote(noteId: noteId, deckId: targetId);
    }
    await _done('Moved ${_noteIds.length} note(s)');
  }

  Future<void> editTags() async {
    if (_noteIds.isEmpty) throw Exception('Selected cards have no linked notes');

    var mode = BulkTagMode.add;
    final ctrl = TextEditingController();

    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setLocal) => AlertDialog(
                  title: const Text('Edit tags'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<BulkTagMode>(
                        value: mode,
                        decoration: const InputDecoration(
                          labelText: 'Action',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: BulkTagMode.add, child: Text('Add tags')),
                          DropdownMenuItem(value: BulkTagMode.remove, child: Text('Remove tags')),
                          DropdownMenuItem(value: BulkTagMode.replace, child: Text('Replace all tags')),
                        ],
                        onChanged: (v) {
                          if (v != null) setLocal(() => mode = v);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: ctrl,
                        decoration: const InputDecoration(
                          hintText: 'Comma-separated tags',
                          border: OutlineInputBorder(),
                        ),
                        autofocus: true,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Apply')),
                  ],
                ),
          ),
    );

    if (ok != true) {
      ctrl.dispose();
      return;
    }

    final tagInput =
        ctrl.text
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList();
    ctrl.dispose();

    if (tagInput.isEmpty && mode != BulkTagMode.replace) {
      throw Exception('Enter at least one tag');
    }

    final previousByNote = <int, List<String>>{};

    for (final noteId in _noteIds) {
      final note = await FlashcardService.instance.fetchNote(noteId);
      final existing = List<String>.from(note?.tags ?? []);
      previousByNote[noteId] = existing;

      List<String> next;
      switch (mode) {
        case BulkTagMode.add:
          next = {...existing, ...tagInput}.toList();
        case BulkTagMode.remove:
          next = existing.where((t) => !tagInput.contains(t)).toList();
        case BulkTagMode.replace:
          next = tagInput;
      }

      await FlashcardService.instance.updateNote(noteId: noteId, tags: next);
    }

    if (mode == BulkTagMode.remove && tagInput.length == 1) {
      await CardTagUndoStore.instance.saveBulkRemove(
        removedTag: tagInput.first,
        previousTagsByNote: previousByNote,
      );
    }

    await _done('Updated tags on ${_noteIds.length} note(s)');
  }

  Future<void> undoTagChange() async {
    final undo = await CardTagUndoStore.instance.loadBulk();
    if (undo == null) throw Exception('Nothing to undo');

    for (final entry in undo.notes.entries) {
      await FlashcardService.instance.updateNote(
        noteId: entry.key,
        tags: entry.value,
      );
    }
    await CardTagUndoStore.instance.clearBulk();
    await _done('Restored tags on ${undo.notes.length} note(s)');
  }

  Future<void> exportCards() async {
    final payload = {
      'format': 'english-app-flashcards-bulk-v1',
      'exportedAt': DateTime.now().toIso8601String(),
      'count': selectedCards.length,
      'cards': selectedCards.map((c) => c.toJson()).toList(),
    };
    final json = JsonEncoder.withIndent('  ').convert(payload);
    await Share.share(json, subject: 'Flashcards export (${selectedCards.length})');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported ${selectedCards.length} card(s)')),
      );
    }
  }

  Future<void> deleteNotes() async {
    final noteIds = _noteIds;
    final orphanCount = selectedCards.where((c) => c.noteId == null).length;

    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete notes?'),
            content: Text(
              noteIds.isEmpty
                  ? 'Delete $orphanCount card(s) without linked notes?'
                  : 'Delete ${noteIds.length} note(s) '
                      '(${selectedCards.length} selected card(s)'
                      '${orphanCount > 0 ? ', including $orphanCount orphan card(s)' : ''})?',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (ok != true) return;

    var deleted = 0;
    Object? lastError;
    for (final card in selectedCards) {
      try {
        await FlashcardService.instance.deleteCard(card.id);
        deleted += 1;
      } catch (e) {
        lastError = e;
      }
    }

    if (deleted == 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lastError?.toString().replaceFirst('Exception: ', '') ??
                  'Could not delete selected notes',
            ),
          ),
        );
      }
      return;
    }

    await _done(
      deleted == selectedCards.length
          ? 'Deleted selected notes'
          : 'Deleted $deleted of ${selectedCards.length} selected',
    );
  }

  Future<void> _done(String message) async {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
    await onComplete();
  }
}
