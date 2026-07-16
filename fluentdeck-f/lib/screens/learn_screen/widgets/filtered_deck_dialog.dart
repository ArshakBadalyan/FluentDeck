import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/models/flashcard_model.dart';
import 'package:fluentdeck/services/flashcard_service.dart';
import 'package:fluentdeck/ui_elements/frosted_bottom_sheet.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';

/// Create a filtered deck from a saved search query (Phase 4F).
Future<FlashcardDeckModel?> showFilteredDeckDialog(
  BuildContext context, {
  Map<String, dynamic>? initialFilter,
  List<FlashcardDeckModel> decks = const [],
}) {
  return showFrostedBottomSheet<FlashcardDeckModel>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    useSafeArea: true,
    builder: (ctx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.82,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return _FilteredDeckSheet(
            initialFilter: initialFilter ?? const {},
            decks: decks,
            scrollController: scrollController,
          );
        },
      );
    },
  );
}

class _FilteredDeckSheet extends StatefulWidget {
  const _FilteredDeckSheet({
    required this.initialFilter,
    required this.decks,
    required this.scrollController,
  });

  final Map<String, dynamic> initialFilter;
  final List<FlashcardDeckModel> decks;
  final ScrollController scrollController;

  @override
  State<_FilteredDeckSheet> createState() => _FilteredDeckSheetState();
}

class _FilteredDeckSheetState extends State<_FilteredDeckSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _searchCtrl;
  late final TextEditingController _tagCtrl;
  int? _sourceDeckId;
  String _state = '';
  bool _saving = false;

  static const _stateOptions = [
    ('', 'Any state', Icons.all_inclusive_rounded),
    ('new', 'New', Icons.fiber_new_rounded),
    ('learning', 'Learning', Icons.school_outlined),
    ('review', 'Review', Icons.refresh_rounded),
    ('relearning', 'Relearning', Icons.replay_rounded),
    ('suspended', 'Suspended', Icons.pause_circle_outline_rounded),
    ('buried', 'Buried', Icons.archive_outlined),
  ];

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
    if (_state.isNotEmpty) {
      final label = _stateOptions.firstWhere((s) => s.$1 == _state).$2;
      parts.add('state $label');
    }
    if (parts.isEmpty) return 'All cards — no filters applied yet';
    return parts.join(' · ');
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give this deck a name')),
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

  InputDecoration _fieldDecoration({String? hint, Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primaryPurple, width: 1.5),
      ),
    );
  }

  TextStyle get _labelStyle => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Colors.grey.shade700,
  );

  Widget _labeledField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle),
        const SizedBox(height: 8),
        field,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final realDecks =
        widget.decks.where((d) => !d.isFiltered).toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    return Column(
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
          padding: const EdgeInsets.fromLTRB(4, 0, 8, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Close',
                onPressed: _saving ? null : () => Navigator.pop(context),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.filter_list_rounded,
                  color: AppColors.primaryPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create filtered deck',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Study cards matching a saved search',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            children: [
              _labeledField(
                'Deck name',
                TextField(
                  controller: _nameCtrl,
                  autofocus: true,
                  decoration: _fieldDecoration(hint: 'e.g. Hard French verbs'),
                ),
              ),
              const SizedBox(height: 16),
              _labeledField(
                'Search text',
                TextField(
                  controller: _searchCtrl,
                  decoration: _fieldDecoration(
                    hint: 'Match text on the front or back',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 16),
              _labeledField(
                'Tag contains',
                TextField(
                  controller: _tagCtrl,
                  decoration: _fieldDecoration(
                    hint: 'e.g. verbs',
                    prefixIcon: const Icon(Icons.sell_outlined, size: 20),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 16),
              AppSelectField<int?>(
                label: 'Source deck',
                value: _sourceDeckId,
                options: [
                  const AppSelectOption<int?>(value: null, label: 'Any deck'),
                  ...realDecks.map(
                    (d) => AppSelectOption<int?>(value: d.id, label: d.name),
                  ),
                ],
                onChanged: (v) => setState(() => _sourceDeckId = v),
              ),
              const SizedBox(height: 16),
              Text('Card state', style: _labelStyle),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in _stateOptions)
                    _StateChip(
                      label: option.$2,
                      icon: option.$3,
                      selected: _state == option.$1,
                      onTap: () => setState(() => _state = option.$1),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primaryPurple),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _filterSummary(),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            12 + MediaQuery.paddingOf(context).bottom,
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _create,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Create deck', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ],
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryPurple : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: !selected ? Border.all(color: Colors.grey.shade200, width: 1) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : Colors.grey.shade700),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
