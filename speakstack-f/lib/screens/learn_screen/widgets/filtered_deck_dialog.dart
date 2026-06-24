import 'package:flutter/material.dart';
import 'package:speakstack/app_colors.dart';
import 'package:speakstack/models/flashcard_model.dart';
import 'package:speakstack/services/flashcard_service.dart';

/// Create a filtered deck from a saved search query (Phase 4F).
Future<FlashcardDeckModel?> showFilteredDeckDialog(
  BuildContext context, {
  Map<String, dynamic>? initialFilter,
  List<FlashcardDeckModel> decks = const [],
}) {
  return showDialog<FlashcardDeckModel>(
    context: context,
    builder: (ctx) => _FilteredDeckDialog(
      initialFilter: initialFilter ?? const {},
      decks: decks,
    ),
  );
}

class _FilteredDeckDialog extends StatefulWidget {
  const _FilteredDeckDialog({
    required this.initialFilter,
    required this.decks,
  });

  final Map<String, dynamic> initialFilter;
  final List<FlashcardDeckModel> decks;

  @override
  State<_FilteredDeckDialog> createState() => _FilteredDeckDialogState();
}

class _FilteredDeckDialogState extends State<_FilteredDeckDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _searchCtrl;
  late final TextEditingController _tagCtrl;
  int? _sourceDeckId;
  String _state = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _searchCtrl = TextEditingController(
      text: widget.initialFilter['q']?.toString() ?? '',
    );
    _tagCtrl = TextEditingController(
      text: widget.initialFilter['tag']?.toString() ?? '',
    );
    final deckId = widget.initialFilter['sourceDeckId'];
    _sourceDeckId = deckId == null ? null : (deckId as num).toInt();
    _state = widget.initialFilter['state']?.toString() ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _searchCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildFilterQuery() {
    final filter = <String, dynamic>{};
    final q = _searchCtrl.text.trim();
    final tag = _tagCtrl.text.trim();
    if (q.isNotEmpty) filter['q'] = q;
    if (tag.isNotEmpty) filter['tag'] = tag;
    if (_sourceDeckId != null) filter['sourceDeckId'] = _sourceDeckId;
    if (_state.isNotEmpty) filter['state'] = _state;
    if (widget.initialFilter['marked'] != null) {
      filter['marked'] = widget.initialFilter['marked'];
    }
    if (widget.initialFilter['flag'] != null) {
      filter['flag'] = widget.initialFilter['flag'];
    }
    return filter;
  }

  String _filterSummary() {
    final parts = <String>[];
    if (_searchCtrl.text.trim().isNotEmpty) {
      parts.add('text "${_searchCtrl.text.trim()}"');
    }
    if (_tagCtrl.text.trim().isNotEmpty) {
      parts.add('tag "${_tagCtrl.text.trim()}"');
    }
    if (_sourceDeckId != null) {
      FlashcardDeckModel? match;
      for (final d in widget.decks) {
        if (d.id == _sourceDeckId) {
          match = d;
          break;
        }
      }
      parts.add('deck ${match?.name ?? _sourceDeckId}');
    }
    if (_state.isNotEmpty) parts.add('state $_state');
    if (parts.isEmpty) return 'All cards (no filters)';
    return parts.join(' · ');
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final deck = await FlashcardService.instance.createFilteredDeck(
        name: name,
        filterQuery: _buildFilterQuery(),
      );
      if (!mounted) return;
      if (deck == null) throw Exception('Failed to create filtered deck');
      Navigator.pop(context, deck);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final realDecks =
        widget.decks.where((d) => !d.isFiltered).toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    return AlertDialog(
      title: const Text('Create filtered deck'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Filtered decks study cards matching a search across your collection.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Deck name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                labelText: 'Search text',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tagCtrl,
              decoration: const InputDecoration(
                labelText: 'Tag contains',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _sourceDeckId,
              decoration: const InputDecoration(
                labelText: 'Source deck',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Any deck'),
                ),
                ...realDecks.map(
                  (d) => DropdownMenuItem<int?>(
                    value: d.id,
                    child: Text(d.name),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _sourceDeckId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _state.isEmpty ? '' : _state,
              decoration: const InputDecoration(
                labelText: 'Card state',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: '', child: Text('Any state')),
                DropdownMenuItem(value: 'new', child: Text('New')),
                DropdownMenuItem(value: 'learning', child: Text('Learning')),
                DropdownMenuItem(value: 'review', child: Text('Review')),
                DropdownMenuItem(value: 'relearning', child: Text('Relearning')),
                DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
                DropdownMenuItem(value: 'buried', child: Text('Buried')),
              ],
              onChanged: (v) => setState(() => _state = v ?? ''),
            ),
            const SizedBox(height: 12),
            Text(
              _filterSummary(),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _create,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryPurple,
            foregroundColor: Colors.white,
          ),
          child: _saving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
