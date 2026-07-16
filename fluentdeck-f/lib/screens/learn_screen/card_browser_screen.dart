import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/data/decks_help_content.dart';
import 'package:fluentdeck/models/flashcard_note_model.dart';
import 'package:fluentdeck/models/flashcard_model.dart';
import 'package:fluentdeck/screens/learn_screen/card_edit_screen.dart';
import 'package:fluentdeck/services/flashcard_service.dart';
import 'package:fluentdeck/services/speaking_preferences_service.dart';
import 'package:fluentdeck/utils/card_browser_utils.dart';
import 'package:fluentdeck/utils/learning_language_utils.dart';
import 'package:fluentdeck/utils/html_text_utils.dart';
import 'package:fluentdeck/screens/learn_screen/widgets/filtered_deck_dialog.dart';
import 'package:fluentdeck/screens/learn_screen/widgets/card_browser_options_menu.dart';
import 'package:fluentdeck/screens/learn_screen/widgets/card_browser_bulk_actions.dart';
import 'package:fluentdeck/screens/learn_screen/widgets/card_row_actions.dart';
import 'package:fluentdeck/screens/learn_screen/widgets/decks_contextual_help.dart';
import 'package:fluentdeck/services/card_browser_order_store.dart';
import 'package:fluentdeck/services/card_tag_undo_store.dart';
import 'package:fluentdeck/services/decks_help_hints_store.dart';
import 'package:fluentdeck/widgets/card_preview_sheet.dart';
import 'package:fluentdeck/widgets/synced_learning_language_hint.dart';
import 'package:fluentdeck/widgets/swipe_action_backgrounds.dart';
import 'package:fluentdeck/ui_elements/app_skeletons.dart';
import 'package:fluentdeck/ui_elements/frosted_bottom_sheet.dart';
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
  Timer? _searchDebounce;
  bool _suppressSearchDebounce = false;

  int? _deckFilter;
  String _stateFilter = 'all';
  String _languageFilter = 'all';
  String _cefrFilter = 'all';
  bool _syncLearningLanguage = true;
  String _practiceLanguage = 'en';
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
  static const _dragColumnWidth = 32.0;
  static const _searchDebounceDuration = Duration(milliseconds: 500);

  String get _orderScopeKey => CardBrowserOrderStore.scopeKey(
    deckId: _deckFilter,
    stateFilter: _stateFilter,
    languageCode: _effectiveLanguageCode,
    search: _searchCtrl.text,
    tag: _tagCtrl.text,
  );

  double _tableContentWidth({
    required bool narrow,
    required double qWidth,
    required double typeWidth,
    required double dueWidth,
    required double deckWidth,
  }) {
    if (narrow) return MediaQuery.sizeOf(context).width;
    return _dragColumnWidth +
        68 +
        qWidth +
        typeWidth +
        dueWidth +
        deckWidth +
        40 +
        48;
  }

  Widget _reorderProxyDecorator(
    Widget child,
    int index,
    Animation<double> animation, {
    double? fixedWidth,
  }) {
    Widget content = child;
    if (fixedWidth != null) {
      content = SizedBox(width: fixedWidth, child: child);
    }

    return Material(
      elevation: 3,
      color: Colors.white,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: content,
    );
  }

  List<FlashcardModel> _finalizeLoadedCards(
    List<FlashcardModel> cards,
    List<int> storedOrder,
  ) {
    if (_sortField != null && _sortDir != null) {
      return sortBrowserCards(cards, _sortField, _sortDir);
    }
    return CardBrowserOrderStore.applyOrder(cards, storedOrder);
  }

  Future<void> _persistCardOrder() async {
    final ids = _cards.map((c) => c.id).toList();
    await CardBrowserOrderStore.instance.save(_orderScopeKey, ids);
  }

  void _applyCardOrderMutation(int oldIndex, int targetIndex) {
    setState(() {
      final moved = _cards.removeAt(oldIndex);
      _cards.insert(targetIndex, moved);
      _sortField = null;
      _sortDir = null;
    });
  }

  /// ReorderableListView drag callback.
  void _onReorder(int oldIndex, int newIndex) {
    if (_selectMode || oldIndex == newIndex) return;
    var target = newIndex;
    if (target > oldIndex) target -= 1;
    _scheduleCardOrderMutation(oldIndex, target);
  }

  void _scheduleCardOrderMutation(int oldIndex, int targetIndex) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (oldIndex < 0 ||
          targetIndex < 0 ||
          oldIndex >= _cards.length ||
          targetIndex >= _cards.length ||
          oldIndex == targetIndex) {
        return;
      }
      _applyCardOrderMutation(oldIndex, targetIndex);
      await _persistCardOrder();
    });
  }

  /// Menu-driven move — deferred to avoid layout mutation during popup close.
  Future<void> _moveCardInList(int fromIndex, int toIndex) {
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        completer.complete();
        return;
      }
      if (fromIndex < 0 ||
          toIndex < 0 ||
          fromIndex >= _cards.length ||
          toIndex >= _cards.length ||
          fromIndex == toIndex) {
        completer.complete();
        return;
      }
      _applyCardOrderMutation(fromIndex, toIndex);
      unawaited(_persistCardOrder().then((_) {
        completer.complete();
      }));
    });
    return completer.future;
  }

  void _showListEdgeSnack(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    });
  }

  Future<bool> _repositionInBrowserList(int cardId, {required bool down}) async {
    final index = _cards.indexWhere((c) => c.id == cardId);
    if (index < 0) return false;

    if (down) {
      if (index >= _cards.length - 1) {
        _showListEdgeSnack('Already at the bottom of the list');
        return false;
      }
      await _moveCardInList(index, index + 1);
      return true;
    }

    if (index <= 0) {
      _showListEdgeSnack('Already at the top of the list');
      return false;
    }
    await _moveCardInList(index, index - 1);
    return true;
  }

  Widget _dragHandle(int index) {
    final icon = Icon(
      Icons.drag_indicator_rounded,
      size: 20,
      color: _selectMode ? Colors.grey.shade300 : Colors.grey.shade500,
    );

    if (_selectMode) {
      return SizedBox(
        width: _dragColumnWidth,
        child: Center(child: icon),
      );
    }

    return SizedBox(
      width: _dragColumnWidth,
      child: ReorderableDragStartListener(
        index: index,
        child: Tooltip(
          message: 'Drag to reorder',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Center(child: icon),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _deckFilter = widget.deckId;
    _searchCtrl.addListener(_onSearchTextChanged);
    _init();
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
    _searchDebounce?.cancel();
    _searchCtrl.removeListener(_onSearchTextChanged);
    _searchCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    if (_suppressSearchDebounce) return;
    _scheduleDebouncedSearch();
  }

  void _scheduleDebouncedSearch() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_searchDebounceDuration, () {
      if (!mounted) return;
      _load(showFullLoading: false);
    });
  }

  void _triggerSearchNow() {
    _searchDebounce?.cancel();
    _load(showFullLoading: false);
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
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
    );
  }

  Future<void> _init() async {
    await _loadLanguagePrefs();
    unawaited(_loadDecks());
    unawaited(_loadNoteTypes());
    await _load();
  }

  Future<void> _loadLanguagePrefs() async {
    final prefs = await SpeakingPreferencesService.instance.load();
    if (!mounted) return;
    setState(() {
      _syncLearningLanguage = prefs.syncLearningLanguage;
      _practiceLanguage = prefs.practiceLanguage;
      if (prefs.syncLearningLanguage) {
        _languageFilter = prefs.practiceLanguage;
      }
    });
  }

  String? get _effectiveLanguageCode => LearningLanguageUtils.effectiveFilterCode(
    syncLearningLanguage: _syncLearningLanguage,
    practiceLanguage: _practiceLanguage,
    manualFilter: _languageFilter,
  );

  List<MapEntry<String, String>> get _languageFilterOptions =>
      LearningLanguageUtils.filterOptions();

  static const _cefrFilterOptions = [
    ('all', 'All levels'),
    ('A1', 'A1'),
    ('A2', 'A2'),
    ('B1', 'B1'),
    ('B2', 'B2'),
    ('C1', 'C1'),
    ('C2', 'C2'),
    ('none', 'No level'),
  ];

  String? get _effectiveCefrLevel =>
      _cefrFilter == 'all' ? null : _cefrFilter;

  Future<void> _load({bool showFullLoading = true}) async {
    if (showFullLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _error = null);
    }
    try {
      final cards = await FlashcardService.instance.browseCards(
        deckId: _deckFilter,
        query: _searchCtrl.text,
        tag: _tagCtrl.text.trim().isEmpty ? null : _tagCtrl.text.trim(),
        state: _stateFilter == 'all' ? null : _stateFilter,
        marked: _markedFilter,
        flag: _flagFilter,
        languageCode: _effectiveLanguageCode,
        cefrLevel: _effectiveCefrLevel,
      );
      final storedOrder = await CardBrowserOrderStore.instance.load(_orderScopeKey);
      if (!mounted) return;
      setState(() {
        _cards = _finalizeLoadedCards(cards, storedOrder);
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
          (ctx) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.sell_outlined,
                          color: AppColors.primaryPurple,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Filter by tag',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ctrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'e.g. verbs',
                      prefixIcon: const Icon(Icons.tag_rounded, size: 20),
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
                    ),
                    onSubmitted: (_) => Navigator.pop(ctx, true),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
      _cefrFilter = 'all';
      _suppressSearchDebounce = true;
      _searchCtrl.clear();
      _tagCtrl.clear();
      _suppressSearchDebounce = false;
      if (_syncLearningLanguage) {
        _languageFilter = _practiceLanguage;
      } else {
        _languageFilter = 'all';
      }
    });
    _searchDebounce?.cancel();
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
    final lang = _effectiveLanguageCode;
    if (lang != null) filter['languageCode'] = lang;
    if (_cefrFilter != 'all') filter['cefrLevel'] = _cefrFilter;
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
              onSubmitted: (_) => _triggerSearchNow(),
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
          if (_hasAnyFilters)
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Clear all filters',
              onPressed: _clearAllFilters,
              icon: const Icon(
                Icons.filter_alt_off_outlined,
                size: 20,
                color: AppColors.primaryPurple,
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
            AppSelectField<int?>(
              label: 'Deck',
              value: _safeDeckDropdownValue(_deckFilter),
              options: [
                const AppSelectOption<int?>(value: null, label: 'All decks'),
                ..._decks.map(
                  (d) => AppSelectOption<int?>(value: d.id, label: d.name),
                ),
              ],
              onChanged: (v) {
                setState(() => _deckFilter = v);
                _load();
              },
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
            onSubmitted: (_) => _triggerSearchNow(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _tagCtrl,
            decoration: _filledFieldDecoration().copyWith(
              hintText: 'Filter by tag…',
              prefixIcon: const Icon(Icons.label_outline),
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
          if (_hasAnyFilters) ...[
            const SizedBox(width: 6),
            _clearFiltersIconButton(),
          ],
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
    if (_cefrFilter != 'all') n++;
    if (!_syncLearningLanguage && _languageFilter != 'all') n++;
    return n;
  }

  int get _extraFilterCount {
    var n = 0;
    if (!['all', 'new', 'learning', 'review'].contains(_stateFilter)) n++;
    if (_markedFilter == true) n++;
    if (_flagFilter != null) n++;
    if (_cefrFilter != 'all') n++;
    if (!_syncLearningLanguage && _languageFilter != 'all') n++;
    return n;
  }

  bool get _hasAnyFilters =>
      _activeFilterCount > 0 || _searchCtrl.text.trim().isNotEmpty;

  Widget _clearFiltersIconButton({double size = 38}) {
    return Material(
      color: AppColors.primaryPurple.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _clearAllFilters,
        borderRadius: BorderRadius.circular(12),
        child: Tooltip(
          message: 'Clear all filters',
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryPurple.withValues(alpha: 0.35),
              ),
            ),
            child: Icon(
              Icons.filter_alt_off_outlined,
              size: size >= 38 ? 18 : 20,
              color: AppColors.primaryPurple,
            ),
          ),
        ),
      ),
    );
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
    var language = _languageFilter;
    var cefr = _cefrFilter;

    final applied = await showFrostedBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
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

            Widget flagChip({
              required String label,
              required int? value,
              Color? color,
            }) {
              final selected = flag == value;
              return FilterChip(
                label: Text(label),
                avatar: color == null ? null : Icon(Icons.flag_rounded, size: 16, color: color),
                selected: selected,
                showCheckmark: true,
                selectedColor: AppColors.primaryPurple.withValues(alpha: 0.12),
                checkmarkColor: AppColors.primaryPurple,
                onSelected: (_) => setSheetState(() => flag = value),
              );
            }

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.72,
              minChildSize: 0.35,
              maxChildSize: 0.92,
              builder: (context, scrollController) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AppSheetHandle(),
                    AppSheetHeader(
                      title: 'Filters',
                      subtitle:
                          '${_visibleCards.length} card${_visibleCards.length == 1 ? '' : 's'}',
                      icon: Icons.filter_list_rounded,
                    ),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        children: [
                          AppSelectField<int?>(
                            label: 'Deck',
                            value: _safeDeckDropdownValue(deck),
                            options: [
                              const AppSelectOption<int?>(value: null, label: 'All decks'),
                              ..._decks.map(
                                (d) => AppSelectOption<int?>(value: d.id, label: d.name),
                              ),
                            ],
                            onChanged: (v) => setSheetState(() => deck = v),
                          ),
                          const SizedBox(height: 16),
                          AppSelectField<String>(
                            label: 'Language',
                            value: language,
                            enabled: !_syncLearningLanguage,
                            options:
                                _languageFilterOptions
                                    .map(
                                      (e) => AppSelectOption(
                                        value: e.key,
                                        label: e.value,
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                _syncLearningLanguage
                                    ? null
                                    : (v) => setSheetState(() => language = v),
                          ),
                          if (_syncLearningLanguage)
                            const SyncedLearningLanguageHint(),
                          const SizedBox(height: 16),
                          Text('CEFR level', style: fieldLabelStyle),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                _cefrFilterOptions.map((option) {
                                  final selected = cefr == option.$1;
                                  return FilterChip(
                                    label: Text(option.$2),
                                    selected: selected,
                                    showCheckmark: true,
                                    selectedColor: AppColors.primaryPurple.withValues(alpha: 0.12),
                                    checkmarkColor: AppColors.primaryPurple,
                                    onSelected: (_) => setSheetState(() => cefr = option.$1),
                                  );
                                }).toList(),
                          ),
                          const SizedBox(height: 16),
                          labeledField(
                            'Tag',
                            TextFormField(
                              initialValue: tag,
                              decoration: appSheetFieldDecoration(hint: 'Filter by tag'),
                              onChanged: (v) => tag = v,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('Card state', style: fieldLabelStyle),
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
                          const SizedBox(height: 12),
                          AppToggleRow(
                            title: 'Marked only',
                            value: marked,
                            onChanged: (v) => setSheetState(() => marked = v),
                          ),
                          const SizedBox(height: 12),
                          Text('Flag', style: fieldLabelStyle),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              flagChip(label: 'Any flag', value: null),
                              flagChip(label: 'No flag', value: 0),
                              for (final e in flagColors.entries)
                                flagChip(label: 'Flag ${e.key}', value: e.key, color: e.value),
                            ],
                          ),
                          if (_selectMode) ...[
                            const SizedBox(height: 12),
                            AppSheetActionTile(
                              icon: Icons.select_all_rounded,
                              title: 'Select all visible',
                              showChevron: false,
                              onTap: () {
                                Navigator.pop(ctx, false);
                                _selectAll();
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: AppPageColors.cardBgOf(ctx),
                        border: Border(top: BorderSide(color: AppPageColors.subtleBorderOf(ctx))),
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
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryPurple,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
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
        _languageFilter = language;
        _cefrFilter = cefr;
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

    final maxWidth = MediaQuery.sizeOf(context).width;
    final narrow = maxWidth < 560;

    if (narrow) {
      const tableInset = 12.0;
      final viewportWidth = MediaQuery.sizeOf(context).width;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(tableInset, 0, tableInset, 8),
            child: _mobileTableHeader(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: tableInset),
              child: ReorderableListView.builder(
                padding: const EdgeInsets.only(bottom: 12),
                buildDefaultDragHandles: false,
                itemCount: _visibleCards.length,
                onReorder: _onReorder,
                proxyDecorator: (child, index, animation) {
                  return _reorderProxyDecorator(
                    child,
                    index,
                    animation,
                    fixedWidth: viewportWidth - (tableInset * 2),
                  );
                },
                itemBuilder: (context, index) {
                  final card = _visibleCards[index];
                  return KeyedSubtree(
                    key: ValueKey('browser-row-${card.id}'),
                    child: SizedBox(
                      width: double.infinity,
                      child: _wrapSwipeRow(
                        card,
                        _mobileDenseRow(card, index),
                      ),
                    ),
                  );
                },
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
    const tableInset = 12.0;
    final contentWidth = _tableContentWidth(
      narrow: false,
      qWidth: qWidth,
      typeWidth: typeWidth,
      dueWidth: dueWidth,
      deckWidth: deckWidth,
    );
    final availableWidth = maxWidth - (tableInset * 2);
    final needsHorizontalScroll = contentWidth > availableWidth;

    Widget buildTableList({double? itemWidth}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _tableHeader(
              narrow: false,
              qWidth: qWidth,
              typeWidth: typeWidth,
              dueWidth: dueWidth,
              deckWidth: deckWidth,
              showResize: true,
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.only(bottom: 12),
              buildDefaultDragHandles: false,
              itemCount: _visibleCards.length,
              onReorder: _onReorder,
              proxyDecorator: (child, index, animation) {
                return _reorderProxyDecorator(
                  child,
                  index,
                  animation,
                  fixedWidth: itemWidth ?? availableWidth,
                );
              },
              itemBuilder: (context, index) {
                final card = _visibleCards[index];
                final row = SizedBox(
                  width: double.infinity,
                  child: _wrapSwipeRow(
                    card,
                    _tableRow(
                      card,
                      index: index,
                      narrow: false,
                      qWidth: qWidth,
                      typeWidth: typeWidth,
                      dueWidth: dueWidth,
                      deckWidth: deckWidth,
                    ),
                  ),
                );
                return KeyedSubtree(
                  key: ValueKey('browser-row-${card.id}'),
                  child: itemWidth != null ? SizedBox(width: itemWidth, child: row) : row,
                );
              },
            ),
          ),
        ],
      );
    }

    if (!needsHorizontalScroll) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: tableInset),
        child: buildTableList(),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: tableInset),
        child: SizedBox(
          width: contentWidth,
          child: buildTableList(itemWidth: contentWidth),
        ),
      ),
    );
  }

  BoxDecoration _browserHeaderDecoration() {
    return BoxDecoration(
      color: AppColors.primaryPurple.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.14)),
    );
  }

  BoxDecoration _browserRowDecoration({required bool selected}) {
    return BoxDecoration(
      color:
          selected
              ? AppColors.primaryPurple.withValues(alpha: 0.08)
              : AppPageColors.cardBgOf(context),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color:
            selected
                ? AppColors.primaryPurple.withValues(alpha: 0.22)
                : AppPageColors.subtleBorderOf(context),
      ),
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
      decoration: _browserHeaderDecoration(),
      child: Row(
        children: [
          SizedBox(
            width: _dragColumnWidth,
            child: Icon(
              Icons.drag_indicator_rounded,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ),
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

  Widget _mobileDenseRow(FlashcardModel card, int index) {
    final selected = _selected.contains(card.id);
    final flagColor = flagColorFor(card.flag);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
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
          child: Ink(
            decoration: _browserRowDecoration(selected: selected),
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
            children: [
              _dragHandle(index),
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
                width: 56,
                child: CardDueLabel(card: card, width: 56),
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
                  onBrowserReposition:
                      ({required bool down}) =>
                          _repositionInBrowserList(card.id, down: down),
                ),
              ),
            ],
              ),
            ),
          ),
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
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: narrow ? 8 : 10),
      decoration: _browserHeaderDecoration(),
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
          SizedBox(
            width: _dragColumnWidth,
            child: Icon(
              Icons.drag_indicator_rounded,
              size: narrow ? 16 : 18,
              color: Colors.grey.shade400,
            ),
          ),
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
    required int index,
    required bool narrow,
    required double qWidth,
    required double typeWidth,
    required double dueWidth,
    required double deckWidth,
  }) {
    final selected = _selected.contains(card.id);
    final flagColor = flagColorFor(card.flag);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
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
          child: Ink(
            decoration: _browserRowDecoration(selected: selected),
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: narrow ? 10 : 12, vertical: narrow ? 8 : 10),
                child: Row(
                  children: [
              _dragHandle(index),
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
                child: CardDueLabel(card: card, width: dueWidth),
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
                onBrowserReposition:
                    ({required bool down}) =>
                        _repositionInBrowserList(card.id, down: down),
              ),
                ],
              ),
            ),
          ),
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
    required this.onBrowserReposition,
  });

  final FlashcardModel card;
  final List<FlashcardDeckModel> decks;
  final List<NoteTypeModel> noteTypes;
  final VoidCallback onChanged;
  final Future<bool> Function({required bool down}) onBrowserReposition;

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
      onBrowserReposition: widget.onBrowserReposition,
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
