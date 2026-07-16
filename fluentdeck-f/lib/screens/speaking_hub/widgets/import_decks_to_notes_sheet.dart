import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/models/flashcard_model.dart';
import 'package:fluentdeck/models/user_note_model.dart';
import 'package:fluentdeck/services/flashcard_service.dart';
import 'package:fluentdeck/services/note_service.dart';
import 'package:fluentdeck/ui_elements/frosted_bottom_sheet.dart';

class ImportDecksToNotesSheet extends StatefulWidget {
  const ImportDecksToNotesSheet({super.key});

  @override
  State<ImportDecksToNotesSheet> createState() => _ImportDecksToNotesSheetState();
}

class _ImportDecksToNotesSheetState extends State<ImportDecksToNotesSheet> {
  List<FlashcardDeckModel> _decks = const [];
  final Set<int> _selectedDeckIds = {};
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
      if (!mounted) return;
      setState(() {
        _decks = decks.where((d) => !d.isFiltered).toList();
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
        _selectedDeckIds.clear();
      }
    });
  }

  Future<void> _submit() async {
    if (_selectedDeckIds.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      final result = await NoteService.instance.importFromDecks(
        deckIds: _selectedDeckIds.toList(),
      );
      if (!mounted) return;
      if (result.ok) {
        final linked =
            _decks
                .where((d) => _selectedDeckIds.contains(d.id))
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
            limitReached: result.limitReached,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Could not import decks')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
                  color: Colors.grey.shade300,
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
                    color: AppColors.primaryPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.library_add_rounded,
                    color: AppColors.primaryPurple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Add decks to My notes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Rubik',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'Select one or more decks. All cards from those decks will be added to My notes for AI practice.',
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
                    activeColor: AppColors.primaryPurple,
                    title: const Text(
                      'Select all decks',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  for (final deck in _decks)
                    CheckboxListTile(
                      value: _selectedDeckIds.contains(deck.id),
                      onChanged: (value) => _toggleDeck(deck.id, value ?? false),
                      activeColor: AppColors.primaryPurple,
                      title: Text(deck.name),
                      subtitle: Text(
                        deck.total > 0
                            ? '${deck.total} cards'
                            : 'No cards yet',
                      ),
                    ),
                ],
              ),
            ),
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed:
                    _selectedDeckIds.isEmpty || _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _submitting
                      ? 'Importing…'
                      : 'Add ${_selectedDeckIds.length} deck${_selectedDeckIds.length == 1 ? '' : 's'}',
                ),
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
