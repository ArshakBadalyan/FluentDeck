import 'package:riovox/ui_elements/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:riovox/models/flashcard_model.dart';
import 'package:riovox/services/flashcard_service.dart';
import 'package:riovox/ui_elements/frosted_bottom_sheet.dart';
import 'package:riovox/ui_elements/modern_page_widgets.dart';
import 'package:riovox/utils/api_exception.dart';
import 'package:riovox/utils/speaking_premium_gate.dart';

/// Create a filtered deck from a saved search query (Phase 4F), or edit
/// [existing] (name + filter).
Future<FlashcardDeckModel?> showFilteredDeckDialog(
  BuildContext context, {
  Map<String, dynamic>? initialFilter,
  List<FlashcardDeckModel> decks = const [],
  FlashcardDeckModel? existing,
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
            initialFilter: existing?.filterQuery ?? initialFilter ?? const {},
            existing: existing,
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
    this.existing,
  });

  final Map<String, dynamic> initialFilter;
  final FlashcardDeckModel? existing;
  final List<FlashcardDeckModel> decks;
  final ScrollController scrollController;

  @override
  State<_FilteredDeckSheet> createState() => _FilteredDeckSheetState();
}

class _FilteredDeckSheetState extends State<_FilteredDeckSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _searchCtrl;
  late final TextEditingController _tagCtrl;
  /// Empty = cards from all decks.
  final Set<int> _sourceDeckIds = {};
  /// Multi-select card states; empty = any state.
  final Set<String> _states = {};
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
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _searchCtrl = TextEditingController(
      text: widget.initialFilter['q']?.toString() ?? '',
    );
    _tagCtrl = TextEditingController(
      text: widget.initialFilter['tag']?.toString() ?? '',
    );
    // Older filtered decks stored a single `sourceDeckId`.
    final single = widget.initialFilter['sourceDeckId'];
    final many = widget.initialFilter['sourceDeckIds'];
    for (final id in [if (single != null) single, if (many is List) ...many]) {
      final parsed = id is num ? id.toInt() : int.tryParse('$id');
      if (parsed != null) _sourceDeckIds.add(parsed);
    }
    // Older filtered decks stored a single state string.
    final rawState = widget.initialFilter['state'];
    _states.addAll(
      [
        if (rawState is List) ...rawState else if (rawState != null) rawState,
      ].map((s) => '$s').where((s) => s.isNotEmpty && s != 'all'),
    );
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
    if (_sourceDeckIds.isNotEmpty) {
      filter['sourceDeckIds'] = _sourceDeckIds.toList()..sort();
    }
    if (_states.isNotEmpty) filter['state'] = _states.toList()..sort();
    if (widget.initialFilter['marked'] != null) {
      filter['marked'] = widget.initialFilter['marked'];
    }
    // Set in the card browser; carried over as-is (may be lists).
    for (final key in ['flag', 'cefrLevel', 'languageCode']) {
      if (widget.initialFilter[key] != null) {
        filter[key] = widget.initialFilter[key];
      }
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
    if (_sourceDeckIds.isNotEmpty) {
      final names = [
        for (final id in _sourceDeckIds)
          widget.decks.where((d) => d.id == id).firstOrNull?.name ?? '#$id',
      ];
      parts.add('${names.length == 1 ? 'deck' : 'decks'} ${names.join(', ')}');
    }
    if (_states.isNotEmpty) {
      final labels = [
        for (final o in _stateOptions)
          if (_states.contains(o.$1)) o.$2,
      ];
      parts.add('${labels.length == 1 ? 'state' : 'states'} ${labels.join(', ')}');
    }
    if (parts.isEmpty) return 'All cards — no filters applied yet';
    return parts.join(' · ');
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      AppToast.showSnackBar(context, 
        const SnackBar(content: Text('Give this deck a name')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final existing = widget.existing;
      final deck =
          existing != null
              ? await FlashcardService.instance.updateDeck(
                existing.id,
                name: name,
                filterQuery: _buildFilterQuery(),
              )
              : await FlashcardService.instance.createFilteredDeck(
                name: name,
                filterQuery: _buildFilterQuery(),
              );
      if (!mounted) return;
      if (deck == null) {
        throw Exception(
          existing != null
              ? 'Failed to update filtered deck'
              : 'Failed to create filtered deck',
        );
      }
      Navigator.pop(context, deck);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 403) {
        showPremiumUpgradeSnackBar(context, e.message);
        Navigator.pop(context);
        return;
      }
      AppToast.showSnackBar(context, SnackBar(content: Text(e.message)));
      setState(() => _saving = false);
    } catch (e) {
      if (!mounted) return;
      AppToast.showSnackBar(context, 
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
      fillColor: AppPageColors.fieldBgOf(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppPageColors.subtleBorderOf(context), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppPageColors.subtleBorderOf(context), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppPageColors.accentOf(context), width: 1.5),
      ),
    );
  }

  TextStyle get _labelStyle => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppPageColors.subtitleOf(context),
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
        Container(
          decoration: BoxDecoration(
            color: AppPageColors.accentOf(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.transparent
                    : Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 6),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppPageColors.onAccentOf(context).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 8, 12),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppPageColors.onAccentOf(context).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.filter_list_rounded,
                        color: AppPageColors.onAccentOf(context),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.existing != null
                                ? 'Edit filtered deck'
                                : 'Create filtered deck',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppPageColors.onAccentOf(context),
                            ),
                          ),
                          Text(
                            'Study cards matching a saved search',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppPageColors.onAccentOf(context).withValues(alpha: 0.78),
                            ),
                          ),
                        ],
                      ),
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
                  autofocus: widget.existing == null,
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
              Text('Source decks', style: _labelStyle),
              const SizedBox(height: 4),
              Text(
                'Pick one or more decks, or "All decks" to search every deck.',
                style: TextStyle(fontSize: 12, color: AppPageColors.subtitleOf(context)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StateChip(
                    label: 'All decks',
                    icon: Icons.all_inclusive_rounded,
                    selected: _sourceDeckIds.isEmpty,
                    onTap: () => setState(_sourceDeckIds.clear),
                  ),
                  for (final d in realDecks)
                    _StateChip(
                      label: d.name,
                      icon: Icons.folder_outlined,
                      selected: _sourceDeckIds.contains(d.id),
                      onTap:
                          () => setState(() {
                            if (!_sourceDeckIds.remove(d.id)) _sourceDeckIds.add(d.id);
                          }),
                    ),
                ],
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
                      selected:
                          option.$1.isEmpty
                              ? _states.isEmpty
                              : _states.contains(option.$1),
                      onTap:
                          () => setState(() {
                            if (option.$1.isEmpty) {
                              _states.clear();
                            } else if (!_states.remove(option.$1)) {
                              _states.add(option.$1);
                            }
                          }),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppPageColors.accentOf(context).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: AppPageColors.accentOf(context)),
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
            color: AppPageColors.cardBgOf(context),
            border: Border(top: BorderSide(color: AppPageColors.subtleBorderOf(context))),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.transparent
                    : Colors.black.withValues(alpha: 0.04),
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
              onPressed: _saving ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppPageColors.accentOf(context),
                foregroundColor: AppPageColors.onAccentOf(context),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppPageColors.onAccentOf(context),
                      ),
                    )
                  : Text(
                      widget.existing != null ? 'Save changes' : 'Create deck',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
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
          color: selected ? AppPageColors.accentOf(context) : AppPageColors.fieldBgOf(context),
          borderRadius: BorderRadius.circular(10),
          border: !selected
              ? Border.all(color: AppPageColors.subtleBorderOf(context), width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? AppPageColors.onAccentOf(context) : AppPageColors.subtitleOf(context),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? AppPageColors.onAccentOf(context) : AppPageColors.subtitleOf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
