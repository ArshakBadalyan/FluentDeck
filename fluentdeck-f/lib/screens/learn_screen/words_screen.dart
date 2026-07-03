import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/models/vocabulary_entry_model.dart';
import 'package:fluentdeck/screens/learn_screen/word_detail_screen.dart';
import 'package:fluentdeck/services/english_level_service.dart';
import 'package:fluentdeck/services/vocabulary_service.dart';

enum _SavedFilter { all, saved, unsaved }

enum _WordSort { wordAsc, wordDesc, levelAsc, levelDesc }

class WordsScreen extends StatefulWidget {
  const WordsScreen({super.key});

  @override
  State<WordsScreen> createState() => _WordsScreenState();
}

class _WordsScreenState extends State<WordsScreen> {
  static const _allLevels = 'All';

  bool _loading = true;
  String? _error;
  String _levelFilter = 'B1';
  _SavedFilter _savedFilter = _SavedFilter.all;
  _WordSort _sort = _WordSort.wordAsc;
  VocabularyCatalogStats? _stats;
  List<VocabularyEntryModel> _entries = const [];
  final Set<int> _togglingIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<VocabularyEntryModel> get _displayedEntries {
    var list = List<VocabularyEntryModel>.from(_entries);

    switch (_savedFilter) {
      case _SavedFilter.saved:
        list = list.where((e) => e.isSaved).toList();
      case _SavedFilter.unsaved:
        list = list.where((e) => !e.isSaved).toList();
      case _SavedFilter.all:
        break;
    }

    const levelOrder = {'A1': 0, 'A2': 1, 'B1': 2, 'B2': 3, 'C1': 4, 'C2': 5};

    list.sort((a, b) {
      int cmp;
      switch (_sort) {
        case _WordSort.levelAsc:
        case _WordSort.levelDesc:
          final la = levelOrder[a.cefrLevel ?? ''] ?? 99;
          final lb = levelOrder[b.cefrLevel ?? ''] ?? 99;
          cmp = la.compareTo(lb);
          if (cmp == 0) {
            cmp = a.word.toLowerCase().compareTo(b.word.toLowerCase());
          }
          if (_sort == _WordSort.levelDesc) cmp = -cmp;
        case _WordSort.wordAsc:
        case _WordSort.wordDesc:
          cmp = a.word.toLowerCase().compareTo(b.word.toLowerCase());
          if (_sort == _WordSort.wordDesc) cmp = -cmp;
      }
      return cmp;
    });

    return list;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final levelFilter = await EnglishLevelService.instance.resolveWordsTabLevelFilter(
        allLevelsLabel: _allLevels,
      );
      final catalogLevel = levelFilter == _allLevels ? null : levelFilter;
      final stats = await VocabularyService.instance.fetchCatalogStats();
      final entries = await VocabularyService.instance.fetchCatalog(
        level: catalogLevel,
        pageSize: catalogLevel == null ? 100 : 50,
      );
      if (!mounted) return;
      setState(() {
        _levelFilter = levelFilter;
        _stats = stats;
        _entries = entries;
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

  Future<void> _reloadCatalog() async {
    try {
      final level = _levelFilter == _allLevels ? null : _levelFilter;
      final entries = await VocabularyService.instance.fetchCatalog(
        level: level,
        pageSize: _levelFilter == _allLevels ? 100 : 50,
      );
      if (!mounted) return;
      setState(() => _entries = entries);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _toggleSaved(VocabularyEntryModel entry) async {
    if (entry.previewLimited || _togglingIds.contains(entry.id)) return;

    setState(() => _togglingIds.add(entry.id));
    try {
      if (entry.isSaved) {
        final result = await VocabularyService.instance.unsaveWord(entry.id);
        if (!mounted) return;
        if (!result.ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message ?? 'Could not unsave')),
          );
          return;
        }
      } else {
        final result = await VocabularyService.instance.saveWord(entry.id);
        if (!mounted) return;
        if (!result.ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message ?? 'Could not save')),
          );
          return;
        }
      }

      setState(() {
        _entries =
            _entries
                .map(
                  (e) => e.id == entry.id ? e.copyWith(isSaved: !e.isSaved) : e,
                )
                .toList();
      });

      await _refreshStats();
    } finally {
      if (mounted) setState(() => _togglingIds.remove(entry.id));
    }
  }

  Future<void> _onWordDetailSaved() async {
    await _reloadCatalog();
    await _refreshStats();
  }

  void _openWord(VocabularyEntryModel entry) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (_) => WordDetailScreen(
              entry: entry,
              onSaved: _onWordDetailSaved,
            ),
      ),
    );
  }

  String get _sortLabel {
    switch (_sort) {
      case _WordSort.wordAsc:
        return 'A → Z';
      case _WordSort.wordDesc:
        return 'Z → A';
      case _WordSort.levelAsc:
        return 'Level ↑';
      case _WordSort.levelDesc:
        return 'Level ↓';
    }
  }

  int get _activeFilterCount {
    var count = 0;
    if (_levelFilter != _allLevels) count++;
    if (_savedFilter != _SavedFilter.all) count++;
    return count;
  }

  Future<void> _persistLevelFilter(String level) async {
    await EnglishLevelService.instance.saveWordsTabLevelFilter(level);
  }

  Future<void> _refreshStats() async {
    final stats = await VocabularyService.instance.fetchCatalogStats();
    if (!mounted) return;
    setState(() => _stats = stats);
  }

  Future<void> _showFiltersSheet() async {
    var draftLevel = _levelFilter;
    var draftSaved = _savedFilter;

    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            const levelOptions = [_allLevels, ...EnglishLevelService.levels];
            const fieldLabelStyle = TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5C5C66),
            );

            return Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.paddingOf(ctx).bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(ctx, false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('CEFR level', style: fieldLabelStyle),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final level in levelOptions)
                        FilterChip(
                          label: Text(level),
                          selected: draftLevel == level,
                          showCheckmark: false,
                          labelStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: draftLevel == level ? FontWeight.w600 : FontWeight.w500,
                            color:
                                draftLevel == level
                                    ? AppColors.primaryPurple
                                    : Colors.grey.shade800,
                          ),
                          selectedColor: AppColors.primaryPurple.withValues(alpha: 0.12),
                          side: BorderSide(
                            color:
                                draftLevel == level
                                    ? AppColors.primaryPurple
                                    : Colors.grey.shade300,
                          ),
                          onSelected: (_) => setSheetState(() => draftLevel = level),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Show', style: fieldLabelStyle),
                  const SizedBox(height: 10),
                  SegmentedButton<_SavedFilter>(
                    segments: const [
                      ButtonSegment(value: _SavedFilter.all, label: Text('All')),
                      ButtonSegment(value: _SavedFilter.saved, label: Text('Saved')),
                      ButtonSegment(
                        value: _SavedFilter.unsaved,
                        label: Text('Not saved'),
                      ),
                    ],
                    selected: {draftSaved},
                    onSelectionChanged: (selection) {
                      setSheetState(() => draftSaved = selection.first);
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            draftLevel = _allLevels;
                            draftSaved = _SavedFilter.all;
                          });
                        },
                        child: const Text('Reset'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                        ),
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (applied != true || !mounted) return;

    final levelChanged = draftLevel != _levelFilter;
    setState(() {
      _levelFilter = draftLevel;
      _savedFilter = draftSaved;
    });
    await _persistLevelFilter(draftLevel);
    if (levelChanged) {
      await _reloadCatalog();
    }
  }

  Widget _filterToolbar({
    required int saved,
    required int? saveLimit,
    required int displayedCount,
    required bool showSaveLimit,
  }) {
    final filtersLabel =
        _activeFilterCount > 0 ? 'Filters ($_activeFilterCount)' : 'Filters';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    '$displayedCount word${displayedCount == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1F),
                    ),
                  ),
                ),
                if (showSaveLimit && saveLimit != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bookmark, size: 14, color: AppColors.primaryPurple),
                        const SizedBox(width: 4),
                        Text(
                          '$saved / $saveLimit saved',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (_activeFilterCount > 0) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (_levelFilter != _allLevels)
                    _activeFilterTag(
                      label: _levelFilter,
                      onClear: () async {
                        setState(() => _levelFilter = _allLevels);
                        await _persistLevelFilter(_allLevels);
                        await _reloadCatalog();
                      },
                    ),
                  if (_savedFilter == _SavedFilter.saved)
                    _activeFilterTag(
                      label: 'Saved',
                      onClear: () => setState(() => _savedFilter = _SavedFilter.all),
                    ),
                  if (_savedFilter == _SavedFilter.unsaved)
                    _activeFilterTag(
                      label: 'Not saved',
                      onClear: () => setState(() => _savedFilter = _SavedFilter.all),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showFiltersSheet,
                    icon: Icon(
                      Icons.tune,
                      size: 18,
                      color:
                          _activeFilterCount > 0
                              ? AppColors.primaryPurple
                              : Colors.grey.shade800,
                    ),
                    label: Text(filtersLabel),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          _activeFilterCount > 0
                              ? AppColors.primaryPurple
                              : Colors.grey.shade800,
                      side: BorderSide(
                        color:
                            _activeFilterCount > 0
                                ? AppColors.primaryPurple.withValues(alpha: 0.4)
                                : Colors.grey.shade300,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                MenuAnchor(
                  style: MenuStyle(
                    backgroundColor: WidgetStateProperty.all(Colors.white),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  builder: (context, controller, child) {
                    return OutlinedButton.icon(
                      onPressed: () {
                        if (controller.isOpen) {
                          controller.close();
                        } else {
                          controller.open();
                        }
                      },
                      icon: const Icon(Icons.sort, size: 18),
                      label: Text(_sortLabel),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade800,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    );
                  },
                  menuChildren: [
                    for (final option in const [
                      (_WordSort.wordAsc, 'Word A → Z'),
                      (_WordSort.wordDesc, 'Word Z → A'),
                      (_WordSort.levelAsc, 'Level low → high'),
                      (_WordSort.levelDesc, 'Level high → low'),
                    ])
                      MenuItemButton(
                        onPressed: () => setState(() => _sort = option.$1),
                        leadingIcon:
                            _sort == option.$1
                                ? const Icon(Icons.check, size: 18, color: AppColors.primaryPurple)
                                : const SizedBox(width: 18),
                        child: Text(option.$2),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _activeFilterTag({required String label, required VoidCallback onClear}) {
    return InputChip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onClear,
      labelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryPurple,
      ),
      backgroundColor: AppColors.primaryPurple.withValues(alpha: 0.08),
      side: BorderSide(color: AppColors.primaryPurple.withValues(alpha: 0.25)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final stats = _stats;
    final saved = stats?.savedCount ?? 0;
    final saveLimit = stats?.saveLimit;
    final displayed = _displayedEntries;
    final catalogEmpty = _entries.isEmpty;

    if (catalogEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'The vocabulary catalog is being prepared.\nWords will appear here once imported.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, height: 1.4),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _filterToolbar(
          saved: saved,
          saveLimit: saveLimit,
          displayedCount: displayed.length,
          showSaveLimit: true,
        ),
        Expanded(
          child:
              displayed.isEmpty
                  ? Center(
                    child: Text(
                      _savedFilter == _SavedFilter.saved
                          ? 'No saved words in this list.'
                          : _savedFilter == _SavedFilter.unsaved
                          ? 'All words here are already saved.'
                          : 'No words match your filters.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  )
                  : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: displayed.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final entry = displayed[index];
                      final toggling = _togglingIds.contains(entry.id);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.word,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            if (entry.previewLimited) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Preview',
                                  style: TextStyle(fontSize: 10),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: entry.isSaved ? 'Remove from saved' : 'Save word',
                              icon:
                                  toggling
                                      ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                      : Icon(
                                        entry.isSaved
                                            ? Icons.bookmark
                                            : Icons.bookmark_border,
                                        size: 22,
                                        color:
                                            entry.isSaved
                                                ? AppColors.primaryPurple
                                                : Colors.grey.shade500,
                                      ),
                              onPressed:
                                  entry.previewLimited
                                      ? null
                                      : () => _toggleSaved(entry),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          entry.previewLimited
                              ? 'Upgrade to see full definition'
                              : (entry.definition ?? ''),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing:
                            entry.entryType == 'phrase'
                                ? const Icon(Icons.short_text, size: 18)
                                : null,
                        onTap: () => _openWord(entry),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}
