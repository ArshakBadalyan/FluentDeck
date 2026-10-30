import 'package:riovox/ui_elements/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:riovox/app_colors.dart';
import 'package:riovox/models/flashcard_model.dart';
import 'package:riovox/models/user_note_model.dart';
import 'package:riovox/services/flashcard_service.dart';
import 'package:riovox/services/my_notes_linked_decks_store.dart';
import 'package:riovox/services/note_service.dart';
import 'package:riovox/ui_elements/frosted_bottom_sheet.dart';
import 'package:riovox/ui_elements/modern_page_widgets.dart';

class ImportDecksToNotesSheet extends StatefulWidget {
  const ImportDecksToNotesSheet({super.key});

  @override
  State<ImportDecksToNotesSheet> createState() => _ImportDecksToNotesSheetState();
}

class _ImportDecksToNotesSheetState extends State<ImportDecksToNotesSheet> {
  List<FlashcardDeckModel> _decks = const [];
  final Set<int> _selectedDeckIds = {};

  /// Decks already in My notes when the sheet opened (pre-checked).
  final Set<int> _linkedDeckIds = {};

  // A subtle brand tint over the card background reads as "selected" in
  // both themes, unlike a flat black overlay (invisible-to-muddy on dark).
  Color _checkedRowColor(BuildContext context) => Color.alphaBlend(
        AppColors.brandPrimary.withValues(alpha: 0.08),
        AppPageColors.cardBgOf(context),
      );
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDecks();
  }

  Future<void> _loadDecks() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final decks = await FlashcardService.instance.fetchDecksWithCache();
      final linked = await MyNotesLinkedDecksStore.instance.load();
      if (!mounted) return;
      setState(() {
        _decks = decks.where((d) => !d.isFiltered).toList();
        final ids = _decks.map((d) => d.id).toSet();
        _linkedDeckIds
          ..clear()
          ..addAll(linked.map((d) => d.id).where(ids.contains));
        _selectedDeckIds
          ..clear()
          ..addAll(_linkedDeckIds)
          // "From speaking" notes are always in My notes.
          ..addAll(_decks.where(_isAlwaysIncluded).map((d) => d.id));
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  bool _isAlwaysIncluded(FlashcardDeckModel deck) =>
      LinkedMyNotesDeck(id: deck.id, name: deck.name, deckSlug: deck.deckSlug)
          .duplicatesSpeakingSource;

  Set<int> get _toAdd => _selectedDeckIds
      .difference(_linkedDeckIds)
      .where((id) => !_decks.any((d) => d.id == id && _isAlwaysIncluded(d)))
      .toSet();

  Set<int> get _toRemove => _linkedDeckIds.difference(_selectedDeckIds);

  bool get _hasChanges => _toAdd.isNotEmpty || _toRemove.isNotEmpty;

  void _toggleDeck(int deckId, bool value) {
    setState(() {
      if (value) {
        _selectedDeckIds.add(deckId);
      } else {
        _selectedDeckIds.remove(deckId);
      }
    });
  }

  void _toggleAll(bool value) {
    setState(() {
      if (value) {
        _selectedDeckIds.addAll(_decks.map((d) => d.id));
      } else {
        _selectedDeckIds
          ..clear()
          ..addAll(_decks.where(_isAlwaysIncluded).map((d) => d.id));
      }
    });
  }

  Future<void> _submit() async {
    if (!_hasChanges || _submitting) return;
    setState(() => _submitting = true);
    try {
      var removed = 0;
      if (_toRemove.isNotEmpty) {
        final n = await NoteService.instance.unlinkDecks(deckIds: _toRemove.toList());
        if (!mounted) return;
        if (n == null) {
          AppToast.error('Could not remove decks from My notes');
          return;
        }
        removed = n;
      }
      final result =
          _toAdd.isEmpty
              ? const ImportDecksResult(ok: true)
              : await NoteService.instance.importFromDecks(deckIds: _toAdd.toList());
      if (!mounted) return;
      if (result.ok) {
        final linked =
            _decks
                .where((d) => _selectedDeckIds.contains(d.id) && !_isAlwaysIncluded(d))
                .map(
                  (d) => LinkedMyNotesDeck(
                    id: d.id,
                    name: d.name,
                    deckSlug: d.deckSlug,
                  ),
                )
                .toList();
        Navigator.pop(
          context,
          ImportDecksResult(
            ok: true,
            created: result.created,
            skipped: result.skipped,
            deckNames: result.deckNames,
            linkedDecks: linked,
            removed: removed,
            limitReached: result.limitReached,
          ),
        );
      } else {
        AppToast.showSnackBar(context, 
          SnackBar(content: Text(result.message ?? 'Could not import decks')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String get _buttonLabel {
    String decks(int n) => '$n deck${n == 1 ? '' : 's'}';
    final add = _toAdd.length, remove = _toRemove.length;
    if (add > 0 && remove > 0) return 'Add ${decks(add)} · Remove ${decks(remove)}';
    if (remove > 0) return 'Remove ${decks(remove)}';
    if (add > 0) return 'Add ${decks(add)}';
    return 'No changes';
  }

  @override
  Widget build(BuildContext context) {
    final allSelected =
        _decks.isNotEmpty && _selectedDeckIds.length == _decks.length;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppPageColors.subtitleOf(context).withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 12, 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.library_add_rounded,
                    color: AppColors.brandPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Decks in My notes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Rubik',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'Checked decks show their cards in My notes for AI practice. Uncheck a deck to take it out — its cards stay in the deck.',
              style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF777481)),
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _loadDecks, child: const Text('Retry')),
                ],
              ),
            )
          else if (_decks.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No decks found. Create a deck in the Decks tab first.',
                textAlign: TextAlign.center,
              ),
            )
          else
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                children: [
                  CheckboxListTile(
                    value: allSelected,
                    tristate: true,
                    onChanged: (value) => _toggleAll(value ?? false),
                    activeColor: AppColors.brandPrimary,
                    tileColor: allSelected == true ? _checkedRowColor(context) : null,
                    title: const Text(
                      'Select all decks',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  for (final deck in _decks)
                    CheckboxListTile(
                      value: _selectedDeckIds.contains(deck.id),
                      onChanged:
                          _isAlwaysIncluded(deck)
                              ? null
                              : (value) => _toggleDeck(deck.id, value ?? false),
                      activeColor: AppColors.brandPrimary,
                      // Same grey as the hover highlight, so checked rows stay marked.
                      tileColor:
                          _selectedDeckIds.contains(deck.id)
                              ? _checkedRowColor(context)
                              : null,
                      title: Text(deck.name),
                      subtitle: Text(
                        _isAlwaysIncluded(deck)
                            ? 'Always in My notes'
                            : deck.total > 0
                            ? '${deck.total} cards'
                            : 'No cards yet',
                      ),
                    ),
                ],
              ),
            ),
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppPageColors.subtleBorderOf(context))),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: !_hasChanges || _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(_submitting ? 'Saving…' : _buttonLabel),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<ImportDecksResult?> showImportDecksToNotesSheet(BuildContext context) {
  return showFrostedBottomSheet<ImportDecksResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => const ImportDecksToNotesSheet(),
  );
}
