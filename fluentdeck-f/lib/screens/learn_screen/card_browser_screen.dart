import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/data/decks_help_content.dart';
import 'package:fluentdeck/models/flashcard_note_model.dart';
import 'package:fluentdeck/models/flashcard_model.dart';
import 'package:fluentdeck/screens/learn_screen/card_edit_screen.dart';
import 'package:fluentdeck/services/flashcard_service.dart';
import 'package:fluentdeck/utils/card_browser_utils.dart';
import 'package:fluentdeck/utils/html_text_utils.dart';
import 'package:fluentdeck/screens/learn_screen/widgets/filtered_deck_dialog.dart';
import 'package:fluentdeck/screens/learn_screen/widgets/card_browser_options_menu.dart';
import 'package:fluentdeck/screens/learn_screen/widgets/card_browser_bulk_actions.dart';
import 'package:fluentdeck/screens/learn_screen/widgets/card_row_actions.dart';
import 'package:fluentdeck/screens/learn_screen/widgets/decks_contextual_help.dart';
import 'package:fluentdeck/services/card_tag_undo_store.dart';
import 'package:fluentdeck/services/decks_help_hints_store.dart';
import 'package:fluentdeck/widgets/card_preview_sheet.dart';
import 'package:fluentdeck/widgets/swipe_action_backgrounds.dart';
import 'package:fluentdeck/ui_elements/app_skeletons.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';

class CardBrowserScreen extends StatefulWidget {
  const CardBrowserScreen({
    super.key,
    this.deckId,
    this.embedInShell = false,
  });

  final int? deckId;
  final bool embedInShell;

  @override
  State<CardBrowserScreen> createState() => _CardBrowserScreenState();
}

class _CardBrowserScreenState extends State<CardBrowserScreen> {
  bool _loading = true;
  String? _error;
  List<FlashcardModel> _cards = const [];
  List<FlashcardDeckModel> _decks = const [];
  List<NoteTypeModel> _noteTypes = const [];

  final _searchCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();

  int? _deckFilter;
  String _stateFilter = 'all';
  bool? _markedFilter;
  int? _flagFilter;
  CardBrowserSortField? _sortField;
  CardBrowserSortDir? _sortDir;

  bool _selectMode = false;
  final Set<int> _selected = {};

  double _colQuestion = 200;
  double _colType = 80;
  double _colDue = 72;
  double _colDeck = 120;

  static const _minColQuestion = 100;
  static const _minColType = 56;
  static const _minColDue = 56;
  static const _minColDeck = 72;

  @override
  void initState() {
    super.initState();
    _deckFilter = widget.deckId;
    _loadDecks();
    _loadNoteTypes();
    _load();
    if (widget.embedInShell) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        DecksContextualHelpButton.maybeShowFirstVisitHint(
          context,
          hintKey: DecksHelpHintsStore.cardBrowserKey,
          message: cardBrowserContextualHint,
          helpSectionId: 'card-browser',
        );
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadNoteTypes() async {
    try {
      final types = await FlashcardService.instance.fetchNoteTypesWithCache();
      if (!mounted) return;
      setState(() => _noteTypes = types);
    } catch (_) {}
  }

  Future<void> _loadDecks() async {
    try {
      final decks = await FlashcardService.instance.fetchDecksWithCache();
      if (!mounted) return;
      setState(() => _decks = decks);
    } catch (_) {}
  }

  int? _safeDeckDropdownValue(int? value) {
    if (value == null) return null;
    return _decks.any((d) => d.id == value) ? value : null;
  }

  bool get _fixedDeckScope =>
      widget.deckId != null && !widget.embedInShell;

  InputDecoration _filledFieldDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: AppPageColors.fieldBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.04)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.primaryPurple.withValues(alpha: 0.45)),
      ),
    );
  }

  Widget _labeledDropdownField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cards = await FlashcardService.instance.browseCards(
        deckId: _deckFilter,
        query: _searchCtrl.text,
        tag: _tagCtrl.text.trim().isEmpty ? null : _tagCtrl.text.trim(),
        state: _stateFilter == 'all' ? null : _stateFilter,
        marked: _markedFilter,
        flag: _flagFilter,
      );
      if (!mounted) return;
      setState(() {
        _cards = sortBrowserCards(cards, _sortField, _sortDir);
        _loading = false;
        _selected.removeWhere((id) => !_cards.any((c) => c.id == id));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<FlashcardModel> get _visibleCards => _cards;

  void _toggleSelectMode() {
    setState(() {
      _selectMode = !_selectMode;
      if (!_selectMode) _selected.clear();
    });
  }

  void _toggleSelected(int cardId) {
    setState(() {
      if (_selected.contains(cardId)) {
        _selected.remove(cardId);
      } else {
        _selected.add(cardId);
      }
    });
  }

  Future<void> _editCardNote(FlashcardModel card) async {
    if (card.noteId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This card has no linked note to edit')),
      );
      return;
    }

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CardEditScreen(deckId: card.deckId, noteId: card.noteId),
      ),
    );
    if (saved == true) await _load();
  }

  Future<void> _deleteCardNote(FlashcardModel card) async {
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
    if (ok != true || !mounted) return;

    await FlashcardService.instance.deleteCard(card.id);
    await _load();
  }

  Widget _wrapSwipeRow(FlashcardModel card, Widget child) {
    if (_selectMode || widget.embedInShell) return child;

    return Dismissible(
      key: ValueKey('browser-card-${card.id}'),
      direction: DismissDirection.horizontal,
      background: SwipeActionBackgrounds.edit(),
      secondaryBackground: SwipeActionBackgrounds.delete(),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await _editCardNote(card);
        } else if (direction == DismissDirection.endToStart) {
          await _deleteCardNote(card);
        }
        return false;
      },
      child: child,
    );
  }

  void _selectAll() {
    setState(() {
      _selected
        ..clear()
        ..addAll(_visibleCards.map((c) => c.id));
    });
  }

  bool get _allVisibleSelected =>
      _visibleCards.isNotEmpty &&
      _visibleCards.every((c) => _selected.contains(c.id));

  bool? get _selectAllCheckboxValue {
    if (_visibleCards.isEmpty) return false;
    if (_allVisibleSelected) return true;
    if (_selected.isEmpty) return false;
    return null;
  }

  void _toggleSelectAllVisible() {
    setState(() {
      if (_allVisibleSelected) {
        for (final card in _visibleCards) {
          _selected.remove(card.id);
        }
      } else {
        for (final card in _visibleCards) {
          _selected.add(card.id);
        }
      }
    });
  }

  Future<void> _addNote() async {
    final bool? saved;
    if (widget.embedInShell) {
      saved = await CardEditScreen.showAddSheet(context, deckId: _deckFilter);
    } else {
      saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => CardEditScreen(deckId: _deckFilter),
        ),
      );
    }
    if (saved == true) await _load();
  }

  List<FlashcardModel> get _selectedCards =>
      _cards.where((c) => _selected.contains(c.id)).toList();

  Future<void> _showBulkActions() async {
    await CardBrowserBulkActions.showMenu(
      context,
      selectedCards: _selectedCards,
      decks: _decks,
      onComplete: () async {
        if (mounted) {
          setState(() {
            _selected.clear();
            _selectMode = false;
          });
        }
        await _load();
      },
    );
  }

  Future<void> _showSortSheet() async {
    final result = await CardBrowserOptionsMenu.showDisplayOrderSheet(
      context,
      currentField: _sortField,
      currentDir: _sortDir,
      fieldLabel: _sortFieldLabel,
    );
    if (result == null) return;
    setState(() {
      _sortField = result.field;
      _sortDir = result.dir;
    });
    if (_sortField == null || _sortDir == null) {
      await _load();
    } else {
      setState(() {
        _cards = sortBrowserCards(_cards, _sortField, _sortDir);
      });
    }
  }

  void _applySort(CardBrowserSortField field) {
    CardBrowserSortField? nextField = _sortField;
    CardBrowserSortDir? nextDir = _sortDir;

    if (_sortField == field && _sortDir != null) {
      if (_sortDir == CardBrowserSortDir.asc) {
        nextDir = CardBrowserSortDir.desc;
      } else {
        nextField = null;
        nextDir = null;
      }
    } else {
      nextField = field;
      nextDir = CardBrowserSortDir.asc;
    }

    setState(() {
      _sortField = nextField;
      _sortDir = nextDir;
    });

    if (nextField == null || nextDir == null) {
      unawaited(_load());
    } else {
      setState(() {
        _cards = sortBrowserCards(_cards, _sortField, _sortDir);
      });
    }
  }

  bool _isSortedOn(CardBrowserSortField field) =>
      _sortField == field && _sortDir != null;

  String? _sortArrowFor(CardBrowserSortField field) {
    if (!_isSortedOn(field) || _sortDir == null) return null;
    return _sortDir == CardBrowserSortDir.asc ? '↑' : '↓';
  }

  Widget _sortHeaderLabel(
    String label,
    CardBrowserSortField field, {
    required TextStyle style,
  }) {
    final arrow = _sortArrowFor(field);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            label,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (arrow != null)
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(arrow, style: style),
          ),
      ],
    );
  }

  String get _sortLabel {
    if (_sortField == null || _sortDir == null) return 'Default';
    final dir = _sortDir == CardBrowserSortDir.asc ? '↑' : '↓';
    return '${_sortFieldLabel(_sortField!)} $dir';
  }

  CardBrowserOptionsState get _optionsState => CardBrowserOptionsState(
    markedFilter: _markedFilter == true,
    suspendedFilter: _stateFilter == 'suspended',
    selectMode: _selectMode,
    flagFilter: _flagFilter,
    sortLabel: _sortLabel,
    visibleCount: _visibleCards.length,
  );

  void _toggleMarkedFilter() {
    setState(() => _markedFilter = _markedFilter == true ? null : true);
    _load();
  }

  void _toggleSuspendedFilter() {
    setState(() {
      _stateFilter = _stateFilter == 'suspended' ? 'all' : 'suspended';
    });
    _load();
  }

  Future<void> _filterByTagDialog() async {
    final ctrl = TextEditingController(text: _tagCtrl.text);
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Filter by tag'),
            content: TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                hintText: 'Tag name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Apply')),
            ],
          ),
    );
    if (ok != true) {
      ctrl.dispose();
      return;
    }
    _tagCtrl.text = ctrl.text.trim();
    ctrl.dispose();
    await _load();
  }

  Future<void> _applyFlagFilter(int? flag) async {
    setState(() => _flagFilter = flag);
    await _load();
  }

  Future<void> _previewFirstCard() async {
    if (_visibleCards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No cards to preview')),
      );
      return;
    }
    await CardPreviewSheet.show(context, _visibleCards.first);
  }

  void _selectAllAndEnterMode() {
    setState(() {
      _selectMode = true;
      _selected
        ..clear()
        ..addAll(_visibleCards.map((c) => c.id));
    });
  }

  void _clearAllFilters() {
    setState(() {
      _stateFilter = 'all';
      _markedFilter = null;
      _flagFilter = null;
      _searchCtrl.clear();
      _tagCtrl.clear();
    });
    _load();
  }

  Future<void> _showOptionsMenu() async {
    await CardBrowserOptionsMenu.show(
      context,
      state: _optionsState,
      onChangeDisplayOrder: _showSortSheet,
      onFilterMarked: _toggleMarkedFilter,
      onFilterSuspended: _toggleSuspendedFilter,
      onFilterByTag: _filterByTagDialog,
      onApplyFlagFilter: _applyFlagFilter,
      onPreview: _previewFirstCard,
      onSelectAll: _selectAllAndEnterMode,
      onToggleSelectMode: _toggleSelectMode,
      onCreateFilteredDeck: _saveAsFilteredDeck,
      onClearFilters: _clearAllFilters,
      onRefresh: _load,
    );
  }

  Map<String, dynamic> _currentFilterQuery() {
    final filter = <String, dynamic>{};
    final q = _searchCtrl.text.trim();
    final tag = _tagCtrl.text.trim();
    if (q.isNotEmpty) filter['q'] = q;
    if (tag.isNotEmpty) filter['tag'] = tag;
    if (_deckFilter != null) filter['sourceDeckId'] = _deckFilter;
    if (_stateFilter != 'all') filter['state'] = _stateFilter;
    if (_markedFilter != null) filter['marked'] = _markedFilter;
    if (_flagFilter != null) {
      filter['flag'] = _flagFilter == 0 ? 'none' : _flagFilter;
    }
    return filter;
  }

  Future<void> _saveAsFilteredDeck() async {
    final deck = await showFilteredDeckDialog(
      context,
      initialFilter: _currentFilterQuery(),
      decks: _decks,
    );
    if (deck != null && mounted) {
      await _loadDecks();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Created filtered deck "${deck.name}"')),
      );
    }
  }

  String _sortFieldLabel(CardBrowserSortField field) {
    switch (field) {
      case CardBrowserSortField.front:
        return 'Question';
      case CardBrowserSortField.due:
        return 'Due';
      case CardBrowserSortField.deck:
        return 'Deck';
      case CardBrowserSortField.type:
        return 'Card type';
    }
  }

  @override
  Widget build(BuildContext context) {
    final compactChrome =
        widget.embedInShell && MediaQuery.sizeOf(context).width < 560;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (compactChrome) _compactToolbar() else ...[
          _toolbar(),
          _filterBar(),
        ],
        Expanded(child: _buildBody()),
        if (_selectMode) _bulkBar(),
      ],
    );

    if (widget.embedInShell) {
      return AppPageBackground(child: body);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Card browser'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add note',
            onPressed: _addNote,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Options',
            onPressed: _showOptionsMenu,
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _compactToolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 2, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search cards…',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                prefixIcon: const Icon(Icons.search, size: 20),
                prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Refresh',
                  onPressed: _load,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.primaryPurple.withValues(alpha: 0.45)),
                ),
              ),
              onSubmitted: (_) => _load(),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Filters',
            onPressed: _showFiltersSheet,
            icon: Badge(
              isLabelVisible: _activeFilterCount > 0,
              label: Text('$_activeFilterCount'),
              child: const Icon(Icons.tune, size: 22),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.more_vert, size: 22),
            tooltip: 'Options',
            onPressed: _showOptionsMenu,
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add, size: 22, color: AppColors.primaryPurple),
            tooltip: 'Add note',
            onPressed: _addNote,
          ),
        ],
      ),
    );
  }

  Widget _toolbar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, widget.embedInShell ? 8 : 0, 16, 0),
      child: Column(
        children: [
          if (widget.embedInShell)
            Row(
              children: [
                Text(
                  '${_visibleCards.length} card${_visibleCards.length == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const Spacer(),
                const DecksContextualHelpButton(
                  helpSectionId: 'card-browser',
                  iconSize: 22,
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 22),
                  tooltip: 'Options',
                  onPressed: _showOptionsMenu,
                ),
                TextButton.icon(
                  onPressed: _addNote,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Add'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primaryPurple),
                ),
              ],
            ),
          if (!_fixedDeckScope && _decks.isNotEmpty) ...[
            _labeledDropdownField(
              label: 'Deck',
              child: DropdownButtonFormField<int?>(
                key: ValueKey(_safeDeckDropdownValue(_deckFilter)),
                value: _safeDeckDropdownValue(_deckFilter),
                isExpanded: true,
                decoration: _filledFieldDecoration(),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('All decks')),
                  ..._decks.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))),
                ],
                onChanged: (v) {
                  setState(() => _deckFilter = v);
                  _load();
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search cards…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: _load,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.primaryPurple.withValues(alpha: 0.45)),
              ),
            ),
            onSubmitted: (_) => _load(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _tagCtrl,
            decoration: InputDecoration(
              hintText: 'Filter by tag…',
              prefixIcon: const Icon(Icons.label_outline),
              filled: true,
              fillColor: AppPageColors.fieldBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (_) => _load(),
          ),
        ],
      ),
    );
  }

  Widget _filterBar() {
    const quickStates = ['all', 'new', 'learning', 'review'];
    final activeExtras = _extraFilterCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: quickStates.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final s = quickStates[index];
                  final selected = _stateFilter == s && activeExtras == 0;
                  return ChoiceChip(
                    label: Text(_stateFilterLabel(s)),
                    selected: selected,
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? AppColors.primaryPurple : Colors.grey.shade800,
                    ),
                    selectedColor: AppColors.primaryPurple.withValues(alpha: 0.12),
                    side: BorderSide(
                      color: selected ? AppColors.primaryPurple : Colors.grey.shade300,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _stateFilter = s;
                        _markedFilter = null;
                        _flagFilter = null;
                      });
                      _load();
                    },
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: activeExtras > 0
                ? AppColors.primaryPurple.withValues(alpha: 0.1)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _showFiltersSheet,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune,
                      size: 18,
                      color: activeExtras > 0 ? AppColors.primaryPurple : Colors.grey.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      activeExtras > 0 ? 'Filters ($activeExtras)' : 'Filters',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: activeExtras > 0 ? AppColors.primaryPurple : Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int get _activeFilterCount {
    var n = 0;
    if (_deckFilter != null) n++;
    if (_stateFilter != 'all') n++;
    if (_markedFilter == true) n++;
    if (_flagFilter != null) n++;
    if (_tagCtrl.text.trim().isNotEmpty) n++;
    return n;
  }

  int get _extraFilterCount {
    var n = 0;
    if (!['all', 'new', 'learning', 'review'].contains(_stateFilter)) n++;
    if (_markedFilter == true) n++;
    if (_flagFilter != null) n++;
    return n;
  }

  String _stateFilterLabel(String s) {
    if (s == 'all') return 'All';
    return s[0].toUpperCase() + s.substring(1);
  }

  Future<void> _showFiltersSheet() async {
    var deck = _deckFilter;
    var state = _stateFilter;
    var marked = _markedFilter == true;
    var flag = _flagFilter;
    var tag = _tagCtrl.text;

    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            InputDecoration filledDecoration() => InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF2F2F5),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            );

            TextStyle fieldLabelStyle = TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            );

            Widget labeledField(String label, Widget field) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: fieldLabelStyle),
                  const SizedBox(height: 8),
                  field,
                ],
              );
            }

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.72,
              minChildSize: 0.35,
              maxChildSize: 0.92,
              builder: (context, scrollController) {
                return Column(
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
                            onPressed: () => Navigator.pop(ctx, false),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Filters',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  '${_visibleCards.length} card${_visibleCards.length == 1 ? '' : 's'}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setSheetState(() {
                                deck = null;
                                state = 'all';
                                marked = false;
                                flag = null;
                                tag = '';
                              });
                            },
                            child: const Text('Clear all'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        children: [
                          labeledField(
                            'Deck',
                            DropdownButtonFormField<int?>(
                              value: _safeDeckDropdownValue(deck),
                              isExpanded: true,
                              decoration: filledDecoration(),
                              items: [
                                const DropdownMenuItem<int?>(value: null, child: Text('All decks')),
                                ..._decks.map(
                                  (d) => DropdownMenuItem(value: d.id, child: Text(d.name)),
                                ),
                              ],
                              onChanged: (v) => setSheetState(() => deck = v),
                            ),
                          ),
                          const SizedBox(height: 16),
                          labeledField(
                            'Tag',
                            TextFormField(
                              initialValue: tag,
                              decoration: filledDecoration(),
                              onChanged: (v) => tag = v,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Card state',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                [
                                  'all',
                                  'new',
                                  'learning',
                                  'review',
                                  'relearning',
                                  'suspended',
                                  'buried',
                                ].map(
                                  (s) => ChoiceChip(
                                    label: Text(_stateFilterLabel(s)),
                                    selected: state == s,
                                    showCheckmark: true,
                                    selectedColor: AppColors.primaryPurple.withValues(alpha: 0.12),
                                    checkmarkColor: AppColors.primaryPurple,
                                    onSelected: (_) => setSheetState(() => state = s),
                                  ),
                                ).toList(),
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Marked only'),
                            value: marked,
                            activeThumbColor: AppColors.primaryPurple,
                            onChanged: (v) => setSheetState(() => marked = v),
                          ),
                          const Divider(height: 1),
                          Text(
                            'Flag',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          RadioListTile<int?>(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            value: null,
                            groupValue: flag,
                            title: const Text('Any flag'),
                            activeColor: AppColors.primaryPurple,
                            onChanged: (_) => setSheetState(() => flag = null),
                          ),
                          RadioListTile<int?>(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            value: 0,
                            groupValue: flag,
                            title: const Text('No flag'),
                            activeColor: AppColors.primaryPurple,
                            onChanged: (_) => setSheetState(() => flag = 0),
                          ),
                          for (final e in flagColors.entries)
                            RadioListTile<int?>(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              value: e.key,
                              groupValue: flag,
                              title: Text('Flag ${e.key}'),
                              secondary: Icon(Icons.flag, color: e.value),
                              activeColor: AppColors.primaryPurple,
                              onChanged: (_) => setSheetState(() => flag = e.key),
                            ),
                          if (_selectMode)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.select_all),
                              title: const Text('Select all visible'),
                              onTap: () {
                                Navigator.pop(ctx, false);
                                _selectAll();
                              },
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
                        12 + MediaQuery.paddingOf(ctx).bottom,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Apply filters'),
                        ),
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

    if (applied == true && mounted) {
      setState(() {
        _deckFilter = deck;
        _stateFilter = state;
        _markedFilter = marked ? true : null;
        _flagFilter = flag;
        _tagCtrl.text = tag;
      });
      await _load();
    }
  }

  String _deckLabel(FlashcardModel card) {
    if (card.deckName != null && card.deckName!.isNotEmpty) return card.deckName!;
    for (final d in _decks) {
      if (d.id == card.deckId) return d.name;
    }
    return '—';
  }

  void _resizeColumn(String column, double delta) {
    setState(() {
      switch (column) {
        case 'question':
          _colQuestion = (_colQuestion + delta).clamp(_minColQuestion, 480).toDouble();
        case 'type':
          _colType = (_colType + delta).clamp(_minColType, 200).toDouble();
        case 'due':
          _colDue = (_colDue + delta).clamp(_minColDue, 160).toDouble();
        case 'deck':
          _colDeck = (_colDeck + delta).clamp(_minColDeck, 280).toDouble();
      }
    });
  }

  Widget _columnResizeHandle(String column) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: (d) => _resizeColumn(column, d.delta.dx),
        child: Container(
          width: 12,
          alignment: Alignment.center,
          child: Container(width: 2, height: 20, color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _bulkBar() {
    return Material(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Clear selection',
                onPressed: () => setState(() {
                  _selected.clear();
                  _selectMode = false;
                }),
              ),
              Text(
                '${_selected.length} selected',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _toggleSelectAllVisible,
                child: Text(_allVisibleSelected ? 'Deselect all' : 'Select all'),
              ),
              const Spacer(),
              FilledButton.tonal(
                onPressed: _showBulkActions,
                child: const Text('Actions'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const CardBrowserSkeleton();
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined, size: 40, color: Colors.grey.shade500),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_visibleCards.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'No cards match your filters',
                style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _addNote,
                icon: const Icon(Icons.add),
                label: const Text('Add note'),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 560;

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _mobileTableHeader(),
              Expanded(
                child: ListView.builder(
                  itemCount: _visibleCards.length,
                  itemBuilder: (context, index) => _wrapSwipeRow(
                    _visibleCards[index],
                    _mobileDenseRow(_visibleCards[index]),
                  ),
                ),
              ),
            ],
          );
        }

        final qWidth = _colQuestion;
        final typeWidth = _colType;
        final dueWidth = _colDue;
        final deckWidth = _colDeck;
        final tableWidth = 68 + qWidth + typeWidth + dueWidth + deckWidth + 40 + 48;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth.clamp(constraints.maxWidth, double.infinity),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _tableHeader(
                  narrow: false,
                  qWidth: qWidth,
                  typeWidth: typeWidth,
                  dueWidth: dueWidth,
                  deckWidth: deckWidth,
                  showResize: true,
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _visibleCards.length,
                    itemBuilder:
                        (context, index) => _wrapSwipeRow(
                          _visibleCards[index],
                          _tableRow(
                            _visibleCards[index],
                            narrow: false,
                            qWidth: qWidth,
                            typeWidth: typeWidth,
                            dueWidth: dueWidth,
                            deckWidth: deckWidth,
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _mobileTableHeader() {
    TextStyle headerStyle({bool active = false}) => TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: active ? AppColors.primaryPurple : Colors.grey.shade700,
    );

    Widget headerCell(String label, CardBrowserSortField field, {double? width}) {
      final active = _isSortedOn(field);
      final cell = InkWell(
        onTap: () => _applySort(field),
        child: _sortHeaderLabel(
          label,
          field,
          style: headerStyle(active: active),
        ),
      );
      if (width != null) {
        return SizedBox(width: width, child: cell);
      }
      return cell;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          if (_selectMode)
            SizedBox(
              width: 28,
              child: Checkbox(
                value: _selectAllCheckboxValue,
                tristate: true,
                activeColor: AppColors.primaryPurple,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                onChanged: (_) => _toggleSelectAllVisible(),
              ),
            ),
          const SizedBox(width: 20),
          Expanded(child: headerCell('Question', CardBrowserSortField.front)),
          headerCell('Type', CardBrowserSortField.type, width: 48),
          headerCell('Due', CardBrowserSortField.due, width: 44),
          headerCell('Deck', CardBrowserSortField.deck, width: 56),
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _mobileDenseRow(FlashcardModel card) {
    final selected = _selected.contains(card.id);
    final flagColor = flagColorFor(card.flag);

    return Material(
      color: selected ? AppColors.primaryPurple.withValues(alpha: 0.06) : null,
      child: InkWell(
        onTap: () {
          if (_selectMode) {
            _toggleSelected(card.id);
          } else {
            CardPreviewSheet.show(context, card);
          }
        },
        onLongPress: () {
          if (!_selectMode) {
            setState(() {
              _selectMode = true;
              _selected.add(card.id);
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              if (_selectMode)
                SizedBox(
                  width: 28,
                  child: Checkbox(
                    value: selected,
                    activeColor: AppColors.primaryPurple,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    onChanged: (_) => _toggleSelected(card.id),
                  ),
                ),
              SizedBox(
                width: 20,
                child:
                    flagColor != null
                        ? Icon(Icons.flag, size: 14, color: flagColor)
                        : card.noteMarked
                        ? Icon(Icons.bookmark, size: 14, color: Colors.amber.shade700)
                        : null,
              ),
              Expanded(
                child: Text(
                  stripHtml(card.displayFront),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  cardTypeLabel(card.cardType),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  formatDueLabel(card),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ),
              SizedBox(
                width: 56,
                child: Text(
                  _deckLabel(card),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ),
              SizedBox(
                width: 32,
                child: _CardRowMenu(
                  card: card,
                  decks: _decks,
                  noteTypes: _noteTypes,
                  onChanged: _load,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sortableHeader(String label, CardBrowserSortField field, {required double width}) {
    final active = _isSortedOn(field);
    final style = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: active ? AppColors.primaryPurple : Colors.grey.shade700,
    );

    return SizedBox(
      width: width,
      child: InkWell(
        onTap: () => _applySort(field),
        child: _sortHeaderLabel(label, field, style: style),
      ),
    );
  }

  Widget _tableHeader({
    required bool narrow,
    required double qWidth,
    required double typeWidth,
    required double dueWidth,
    required double deckWidth,
    required bool showResize,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: narrow ? 8 : 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          if (_selectMode)
            SizedBox(
              width: narrow ? 32 : 40,
              child: Checkbox(
                value: _selectAllCheckboxValue,
                tristate: true,
                activeColor: AppColors.primaryPurple,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                onChanged: (_) => _toggleSelectAllVisible(),
              ),
            ),
          SizedBox(width: narrow ? 24 : 28),
          _sortableHeader('Question', CardBrowserSortField.front, width: qWidth),
          if (showResize) _columnResizeHandle('question'),
          _sortableHeader('Type', CardBrowserSortField.type, width: typeWidth),
          if (showResize) _columnResizeHandle('type'),
          _sortableHeader('Due', CardBrowserSortField.due, width: dueWidth),
          if (showResize) _columnResizeHandle('due'),
          _sortableHeader('Deck', CardBrowserSortField.deck, width: deckWidth),
          if (showResize) _columnResizeHandle('deck'),
          SizedBox(width: narrow ? 32 : 40),
        ],
      ),
    );
  }

  Widget _tableRow(
    FlashcardModel card, {
    required bool narrow,
    required double qWidth,
    required double typeWidth,
    required double dueWidth,
    required double deckWidth,
  }) {
    final selected = _selected.contains(card.id);
    final flagColor = flagColorFor(card.flag);

    return Material(
      color: selected ? AppColors.primaryPurple.withValues(alpha: 0.06) : null,
      child: InkWell(
        onTap: () {
          if (_selectMode) {
            _toggleSelected(card.id);
          } else {
            CardPreviewSheet.show(context, card);
          }
        },
        onLongPress: () {
          if (!_selectMode) {
            setState(() {
              _selectMode = true;
              _selected.add(card.id);
            });
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: narrow ? 8 : 12, vertical: narrow ? 8 : 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              if (_selectMode)
                SizedBox(
                  width: narrow ? 32 : 40,
                  child: Checkbox(
                    value: selected,
                    activeColor: AppColors.primaryPurple,
                    onChanged: (_) => _toggleSelected(card.id),
                  ),
                ),
              SizedBox(
                width: narrow ? 24 : 28,
                child:
                    flagColor != null
                        ? Icon(Icons.flag, size: 18, color: flagColor)
                        : card.noteMarked
                        ? Icon(Icons.bookmark, size: 18, color: Colors.amber.shade700)
                        : null,
              ),
              SizedBox(
                width: qWidth,
                child: Text(
                  stripHtml(card.displayFront),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: narrow ? 13 : 14),
                ),
              ),
              if (!narrow) const SizedBox(width: 12),
              SizedBox(
                width: typeWidth,
                child: Text(
                  cardTypeLabel(card.cardType),
                  style: TextStyle(fontSize: narrow ? 11 : 12, color: Colors.grey.shade700),
                ),
              ),
              if (!narrow) const SizedBox(width: 12),
              SizedBox(
                width: dueWidth,
                child: Text(
                  formatDueLabel(card),
                  style: TextStyle(fontSize: narrow ? 11 : 12, color: Colors.grey.shade700),
                ),
              ),
              if (!narrow) const SizedBox(width: 12),
              SizedBox(
                width: deckWidth,
                child: Text(
                  _deckLabel(card),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: narrow ? 11 : 12, color: Colors.grey.shade700),
                ),
              ),
              _CardRowMenu(
                card: card,
                decks: _decks,
                noteTypes: _noteTypes,
                onChanged: _load,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardRowMenu extends StatefulWidget {
  const _CardRowMenu({
    required this.card,
    required this.decks,
    required this.noteTypes,
    required this.onChanged,
  });

  final FlashcardModel card;
  final List<FlashcardDeckModel> decks;
  final List<NoteTypeModel> noteTypes;
  final VoidCallback onChanged;

  @override
  State<_CardRowMenu> createState() => _CardRowMenuState();
}

class _CardRowMenuState extends State<_CardRowMenu> {
  bool _canUndoTag = false;

  @override
  void initState() {
    super.initState();
    _checkUndo();
  }

  Future<void> _checkUndo() async {
    final undo = await CardTagUndoStore.instance.load();
    if (!mounted) return;
    setState(() => _canUndoTag = undo?.noteId == widget.card.noteId);
  }

  @override
  Widget build(BuildContext context) {
    final actions = CardRowActions(
      context: context,
      card: widget.card,
      decks: widget.decks,
      noteTypes: widget.noteTypes,
      onChanged: widget.onChanged,
    );

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      onSelected: (value) async {
        await actions.handle(value);
        await _checkUndo();
      },
      itemBuilder: (_) => actions.buildMenuItems(canUndoTag: _canUndoTag),
    );
  }
}
