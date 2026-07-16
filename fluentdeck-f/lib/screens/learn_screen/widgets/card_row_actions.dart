import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/models/flashcard_model.dart';
import 'package:fluentdeck/models/flashcard_note_model.dart';
import 'package:fluentdeck/screens/learn_screen/card_edit_screen.dart';
import 'package:fluentdeck/services/card_tag_undo_store.dart';
import 'package:fluentdeck/services/flashcard_service.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';
import 'package:fluentdeck/utils/api_exception.dart';
import 'package:fluentdeck/utils/card_browser_utils.dart';
import 'package:fluentdeck/utils/html_text_utils.dart';
import 'package:fluentdeck/widgets/card_preview_sheet.dart';

/// Card browser row ⋮ menu actions.
class CardRowActions {
  CardRowActions({
    required this.context,
    required this.card,
    required this.decks,
    required this.noteTypes,
    required this.onChanged,
    this.onBrowserReposition,
  });

  final BuildContext context;
  final FlashcardModel card;
  final List<FlashcardDeckModel> decks;
  final List<NoteTypeModel> noteTypes;
  final VoidCallback onChanged;
  /// For Basic / single-card notes: reorder row in the browser list instead of
  /// sibling reposition within a multi-card note.
  final Future<bool> Function({required bool down})? onBrowserReposition;

  bool get _isSingleCardNote => (card.siblingCardCount ?? 1) <= 1;

  String _friendlyError(Object error) {
    if (error is ApiException) {
      final msg = error.message;
      if (msg.contains('only one card')) {
        return 'This note has only one card — repositioning needs multiple cards '
            '(e.g. Basic with reversed card).';
      }
      if (msg.contains('edge of note')) {
        return 'This card is already at the top/bottom of its note.';
      }
      if (msg.contains('no linked note')) {
        return 'This card is not linked to a note yet.';
      }
      return msg;
    }
    final text = error.toString();
    if (text.contains('No linked note')) {
      return 'This card is not linked to a note yet.';
    }
    if (text.contains('No note types')) {
      return 'Note types could not be loaded. Check your connection and try again.';
    }
    return text.replaceFirst('Exception: ', '');
  }

  void _showMessage(String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<int?> _resolveNoteId() async {
    return FlashcardService.instance.ensureCardNote(card.id);
  }

  Future<T?> _showDialogAfterMenu<T>(WidgetBuilder builder) {
    final completer = Completer<T?>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) {
        completer.complete(null);
        return;
      }
      completer.complete(await showDialog<T>(context: context, builder: builder));
    });
    return completer.future;
  }

  List<PopupMenuEntry<String>> buildMenuItems({required bool canUndoTag}) {
    final suspended = card.reviewState?.suspended == true;
    final buried =
        card.reviewState?.buriedUntil != null &&
        card.reviewState!.buriedUntil!.isAfter(DateTime.now());

    return [
      const PopupMenuItem(value: 'edit', child: Text('Edit note')),
      const PopupMenuItem(value: 'info', child: Text('Card info')),
      PopupMenuItem(
        value: 'suspend',
        child: Text(suspended ? 'Unsuspend' : 'Suspend'),
      ),
      PopupMenuItem(
        value: 'bury',
        child: Text(buried ? 'Unbury' : 'Bury'),
      ),
      const PopupMenuItem(value: 'change_type', child: Text('Change note type')),
      const PopupMenuItem(value: 'change_deck', child: Text('Change deck')),
      const PopupMenuItem(value: 'reposition_up', child: Text('Reposition — move up')),
      const PopupMenuItem(value: 'reposition_down', child: Text('Reposition — move down')),
      const PopupMenuItem(value: 'set_due', child: Text('Set due date')),
      const PopupMenuItem(value: 'edit_tags', child: Text('Edit tags')),
      const PopupMenuItem(value: 'grade', child: Text('Grade now')),
      const PopupMenuItem(value: 'reset', child: Text('Reset progress')),
      const PopupMenuItem(value: 'preview', child: Text('Preview')),
      const PopupMenuItem(value: 'export', child: Text('Export card')),
      const PopupMenuItem(value: 'delete', child: Text('Delete note')),
      if (canUndoTag)
        const PopupMenuItem(value: 'undo_tag', child: Text('Undo remove tag')),
      const PopupMenuDivider(),
      const PopupMenuItem(value: 'flag_0', child: Text('Clear flag')),
      for (final e in flagColors.entries)
        PopupMenuItem(
          value: 'flag_${e.key}',
          child: Row(
            children: [
              Icon(Icons.flag, color: e.value, size: 18),
              const SizedBox(width: 8),
              Text('Flag ${e.key}'),
            ],
          ),
        ),
    ];
  }

  Future<void> handle(String action) async {
    try {
      switch (action) {
        case 'preview':
          await CardPreviewSheet.show(context, card);
        case 'edit':
          await _editNote();
        case 'info':
          await _showCardInfo();
        case 'suspend':
          await _toggleSuspend();
        case 'bury':
          await _toggleBury();
        case 'change_type':
          await _changeNoteType();
        case 'change_deck':
          await _changeDeck();
        case 'reposition_up':
          await _reposition(down: false);
        case 'reposition_down':
          await _reposition(down: true);
        case 'set_due':
          await _setDueDate();
        case 'edit_tags':
          await _editTags();
        case 'grade':
          await _gradeNow();
        case 'reset':
          await _resetProgress();
        case 'export':
          await _exportCard();
        case 'delete':
          await _deleteNote();
        case 'undo_tag':
          await _undoRemoveTag();
        default:
          if (action.startsWith('flag_')) {
            await _setFlag(int.parse(action.split('_').last));
          }
      }
    } catch (e) {
      if (!context.mounted) return;
      _showMessage(_friendlyError(e));
    }
  }

  Future<void> _editNote() async {
    if (card.noteId == null) {
      throw Exception('This card has no linked note to edit');
    }
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CardEditScreen(deckId: card.deckId, noteId: card.noteId),
      ),
    );
    if (saved == true) onChanged();
  }

  Future<void> _showCardInfo() async {
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    FlashcardCardInfo info;
    try {
      info = await FlashcardService.instance.fetchCardInfo(card.id);
    } finally {
      if (context.mounted) Navigator.pop(context);
    }
    if (!context.mounted) return;

    final rs = info.card.reviewState;
    final due = rs?.dueAt != null ? formatDueLabel(info.card) : '—';

    await showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Card info'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _infoRow('Card ID', '${info.card.id}'),
                  if (info.note != null) _infoRow('Note ID', '${info.note!.id}'),
                  _infoRow('Deck', info.card.deckName ?? '—'),
                  _infoRow('Type', cardTypeLabel(info.card.cardType)),
                  _infoRow('Template', info.templateName),
                  if (info.siblingCount > 1)
                    _infoRow('Position', '${info.templateOrdinal + 1} of ${info.siblingCount}'),
                  _infoRow('State', rs?.state ?? 'new'),
                  _infoRow('Due', due),
                  _infoRow('Interval', '${rs?.intervalDays.toStringAsFixed(1) ?? 0} days'),
                  _infoRow('Ease', rs?.easeFactor.toStringAsFixed(2) ?? '2.50'),
                  _infoRow('Reviews', '${rs?.repetitions ?? 0}'),
                  _infoRow('Lapses', '${rs?.lapses ?? 0}'),
                  if (info.note != null) _infoRow('Note type', info.note!.noteType),
                  if (info.card.tags.isNotEmpty)
                    _infoRow('Tags', info.card.tags.join(', ')),
                  const SizedBox(height: 8),
                  Text(
                    stripHtml(info.card.displayFront),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
            ],
          ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 88, child: Text(label, style: TextStyle(color: Colors.grey.shade600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _toggleSuspend() async {
    if (card.reviewState?.suspended == true) {
      await FlashcardService.instance.unsuspendCard(card.id);
    } else {
      await FlashcardService.instance.suspendCard(card.id);
    }
    onChanged();
  }

  Future<void> _toggleBury() async {
    final buried =
        card.reviewState?.buriedUntil != null &&
        card.reviewState!.buriedUntil!.isAfter(DateTime.now());
    if (buried) {
      await FlashcardService.instance.unburyCard(card.id);
    } else {
      await FlashcardService.instance.buryCard(card.id);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(buried ? 'Card unburied' : 'Card buried until end of day')),
      );
    }
    onChanged();
  }

  Future<void> _changeNoteType() async {
    if (noteTypes.isEmpty) throw Exception('No note types available');

    final noteId = await _resolveNoteId();
    if (noteId == null) throw Exception('Could not link card to a note');

    final note = await FlashcardService.instance.fetchNote(noteId);
    final current = note?.noteType ?? card.noteTypeId;

    if (!context.mounted) return;

    final picked = await _showDialogAfterMenu<String>(
      (ctx) => SimpleDialog(
        title: const Text('Change note type'),
        children:
            noteTypes
                .map(
                  (t) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(ctx, t.id),
                    child: Row(
                      children: [
                        Expanded(child: Text(t.name)),
                        if (t.id == current)
                          const Icon(Icons.check, color: AppColors.primaryPurple, size: 18),
                      ],
                    ),
                  ),
                )
                .toList(),
      ),
    );
    if (picked == null || picked == current) return;
    if (!context.mounted) return;

    final ok = await _showDialogAfterMenu<bool>(
      (ctx) => AlertDialog(
        title: const Text('Change note type?'),
        content: const Text(
          'Cards will be regenerated from the new template. Review history is preserved where possible.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Change')),
        ],
      ),
    );
    if (ok != true) return;

    await FlashcardService.instance.changeNoteType(
      noteId: noteId,
      noteType: picked,
    );
    _showMessage('Note type updated');
    onChanged();
  }

  Future<void> _changeDeck() async {
    final noteId = await _resolveNoteId();
    if (noteId == null) throw Exception('No linked note');
    if (decks.isEmpty) throw Exception('No decks available');

    if (!context.mounted) return;
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
    if (targetId == null || targetId == card.deckId) return;

    await FlashcardService.instance.updateNote(noteId: noteId, deckId: targetId);
    onChanged();
  }

  Future<void> _reposition({required bool down}) async {
    if (_isSingleCardNote && onBrowserReposition != null) {
      final moved = await onBrowserReposition!(down: down);
      if (!context.mounted) return;
      if (moved) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          _showMessage(down ? 'Moved down in list' : 'Moved up in list');
        });
      }
      return;
    }

    await FlashcardService.instance.repositionCard(card.id, down: down);
    if (context.mounted) {
      _showMessage(down ? 'Moved down in note' : 'Moved up in note');
    }
    onChanged();
  }

  Future<void> _setDueDate() async {
    final initial = card.reviewState?.dueAt?.toLocal() ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;

    final due = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    await FlashcardService.instance.setCardDue(card.id, due);
    if (context.mounted) {
      _showMessage('Due date set to ${formatDueDateTime(due)}');
    }
    onChanged();
  }

  Future<void> _editTags() async {
    if (card.noteId == null) throw Exception('No linked note');

    final note = await FlashcardService.instance.fetchNote(card.noteId!);
    final previousTags = List<String>.from(note?.tags ?? card.tags);
    final ctrl = TextEditingController(text: previousTags.join(', '));

    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Edit tags'),
            content: TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                hintText: 'Comma-separated tags',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
            ],
          ),
    );

    if (ok != true) {
      ctrl.dispose();
      return;
    }

    final newTags =
        ctrl.text
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList();
    ctrl.dispose();

    for (final tag in previousTags) {
      if (!newTags.contains(tag)) {
        await CardTagUndoStore.instance.save(
          noteId: card.noteId!,
          removedTag: tag,
          previousTags: previousTags,
        );
        break;
      }
    }

    await FlashcardService.instance.updateNote(noteId: card.noteId!, tags: newTags);
    onChanged();
  }

  Future<void> _gradeNow() async {
    if (!context.mounted) return;
    final rating = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppPageColors.fieldBgOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Grade now', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                ListTile(title: const Text('Again'), onTap: () => Navigator.pop(ctx, 'again')),
                ListTile(title: const Text('Hard'), onTap: () => Navigator.pop(ctx, 'hard')),
                ListTile(title: const Text('Good'), onTap: () => Navigator.pop(ctx, 'good')),
                ListTile(title: const Text('Easy'), onTap: () => Navigator.pop(ctx, 'easy')),
                const SizedBox(height: 8),
              ],
            ),
          ),
    );
    if (rating == null) return;

    await FlashcardService.instance.gradeCardNow(card.id, rating);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Graded as $rating')),
      );
    }
    onChanged();
  }

  Future<void> _resetProgress() async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Reset progress?'),
            content: const Text('This card will return to new with no review history.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset')),
            ],
          ),
    );
    if (ok != true) return;

    await FlashcardService.instance.resetCardProgress(card.id);
    onChanged();
  }

  Future<void> _exportCard() async {
    final data = await FlashcardService.instance.exportCardJson(card.id);
    final json = const JsonEncoder.withIndent('  ').convert(data);
    await Share.share(json, subject: 'Flashcard export');
  }

  Future<void> _deleteNote() async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete note?'),
            content: const Text('All cards generated from this note will be deleted.'),
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

    await FlashcardService.instance.deleteCard(card.id);
    onChanged();
  }

  Future<void> _undoRemoveTag() async {
    final undo = await CardTagUndoStore.instance.load();
    if (undo == null || undo.noteId != card.noteId) {
      throw Exception('Nothing to undo');
    }
    await FlashcardService.instance.updateNote(
      noteId: undo.noteId,
      tags: undo.previousTags,
    );
    await CardTagUndoStore.instance.clear();
    onChanged();
  }

  Future<void> _setFlag(int flag) async {
    await FlashcardService.instance.setCardFlag(card.id, flag);
    onChanged();
  }
}
