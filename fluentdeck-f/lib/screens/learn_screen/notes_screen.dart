import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/models/user_note_model.dart';
import 'package:fluentdeck/screens/learn_screen/note_edit_screen.dart';
import 'package:fluentdeck/services/note_service.dart';
import 'package:fluentdeck/widgets/swipe_action_backgrounds.dart';

enum _NoteSourceFilter { all, catalog, speaking, manual }

enum _NoteSort { wordAsc, wordDesc, newest, oldest }

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key, this.enableSwipeActions = false});

  /// When false, horizontal swipes change tabs instead of edit/delete on rows.
  final bool enableSwipeActions;

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  bool _loading = true;
  String? _error;
  String _query = '';
  List<UserNoteModel> _notes = const [];
  final _searchController = TextEditingController();
  _NoteSourceFilter _sourceFilter = _NoteSourceFilter.all;
  _NoteSort _sort = _NoteSort.newest;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserNoteModel> get _displayedNotes {
    var list = List<UserNoteModel>.from(_notes);

    switch (_sourceFilter) {
      case _NoteSourceFilter.catalog:
        list = list.where((n) => n.source == 'catalog').toList();
      case _NoteSourceFilter.speaking:
        list = list.where((n) => n.source == 'speaking').toList();
      case _NoteSourceFilter.manual:
        list = list.where((n) => n.source == 'manual').toList();
      case _NoteSourceFilter.all:
        break;
    }

    list.sort((a, b) {
      switch (_sort) {
        case _NoteSort.wordAsc:
          return a.word.toLowerCase().compareTo(b.word.toLowerCase());
        case _NoteSort.wordDesc:
          return b.word.toLowerCase().compareTo(a.word.toLowerCase());
        case _NoteSort.newest:
          final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
          final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
          return bTime.compareTo(aTime);
        case _NoteSort.oldest:
          final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
          final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
          return aTime.compareTo(bTime);
      }
    });

    return list;
  }

  int get _activeFilterCount => _sourceFilter == _NoteSourceFilter.all ? 0 : 1;

  String get _sortLabel {
    switch (_sort) {
      case _NoteSort.wordAsc:
        return 'A → Z';
      case _NoteSort.wordDesc:
        return 'Z → A';
      case _NoteSort.newest:
        return 'Newest';
      case _NoteSort.oldest:
        return 'Oldest';
    }
  }

  Future<void> _load({String? query}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final notes = await NoteService.instance.fetchNotes(query: query);
      if (!mounted) return;
      setState(() {
        _notes = notes;
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

  Future<void> _openCreate() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const NoteEditScreen()),
    );
    if (saved == true) await _load(query: _query.isEmpty ? null : _query);
  }

  Future<void> _openEdit(UserNoteModel note) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => NoteEditScreen(note: note)),
    );
    if (saved == true) await _load(query: _query.isEmpty ? null : _query);
  }

  Future<bool> _confirmDelete(UserNoteModel note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete note?'),
            content: Text('Remove "${note.word}" from your notes?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (confirmed != true) return false;

    final ok = await NoteService.instance.deleteNote(note.id);
    if (!mounted) return false;
    if (ok) {
      setState(() => _notes = _notes.where((n) => n.id != note.id).toList());
      return true;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not delete note')),
    );
    return false;
  }

  Future<void> _showFiltersSheet() async {
    var draftSource = _sourceFilter;

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
                  const Text('Source', style: fieldLabelStyle),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in const [
                        (_NoteSourceFilter.all, 'All'),
                        (_NoteSourceFilter.catalog, 'Word list'),
                        (_NoteSourceFilter.speaking, 'From speaking'),
                        (_NoteSourceFilter.manual, 'Manual'),
                      ])
                        FilterChip(
                          label: Text(option.$2),
                          selected: draftSource == option.$1,
                          showCheckmark: false,
                          labelStyle: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                draftSource == option.$1 ? FontWeight.w600 : FontWeight.w500,
                            color:
                                draftSource == option.$1
                                    ? AppColors.primaryPurple
                                    : Colors.grey.shade800,
                          ),
                          selectedColor: AppColors.primaryPurple.withValues(alpha: 0.12),
                          side: BorderSide(
                            color:
                                draftSource == option.$1
                                    ? AppColors.primaryPurple
                                    : Colors.grey.shade300,
                          ),
                          onSelected: (_) => setSheetState(() => draftSource = option.$1),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setSheetState(() => draftSource = _NoteSourceFilter.all);
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
    setState(() => _sourceFilter = draftSource);
  }

  Widget _filterToolbar({required int displayedCount}) {
    final filtersLabel =
        _activeFilterCount > 0 ? 'Filters ($_activeFilterCount)' : 'Filters';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '$displayedCount note${displayedCount == 1 ? '' : 's'}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1F),
              ),
            ),
            if (_activeFilterCount > 0) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (_sourceFilter != _NoteSourceFilter.all)
                    _activeFilterTag(
                      label: _sourceFilterLabel(_sourceFilter),
                      onClear: () => setState(() => _sourceFilter = _NoteSourceFilter.all),
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
                      (_NoteSort.newest, 'Newest first'),
                      (_NoteSort.oldest, 'Oldest first'),
                      (_NoteSort.wordAsc, 'Word A → Z'),
                      (_NoteSort.wordDesc, 'Word Z → A'),
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

  String _sourceFilterLabel(_NoteSourceFilter filter) {
    switch (filter) {
      case _NoteSourceFilter.catalog:
        return 'Word list';
      case _NoteSourceFilter.speaking:
        return 'From speaking';
      case _NoteSourceFilter.manual:
        return 'Manual';
      case _NoteSourceFilter.all:
        return 'All';
    }
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

  Widget _noteTile(UserNoteModel note) {
    final tile = Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => _openEdit(note),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            note.word,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          note.sourceLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    if (note.definition.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        note.definition,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!widget.enableSwipeActions)
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  onSelected: (action) async {
                    if (action == 'edit') {
                      await _openEdit(note);
                    } else if (action == 'delete') {
                      await _confirmDelete(note);
                    }
                  },
                  itemBuilder:
                      (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                ),
            ],
          ),
        ),
      ),
    );

    if (!widget.enableSwipeActions) return tile;

    return Dismissible(
      key: ValueKey('note-${note.id}'),
      direction: DismissDirection.horizontal,
      background: SwipeActionBackgrounds.edit(),
      secondaryBackground: SwipeActionBackgrounds.delete(),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await _openEdit(note);
          return false;
        }
        if (direction == DismissDirection.endToStart) {
          return _confirmDelete(note);
        }
        return false;
      },
      child: tile,
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayed = _displayedNotes;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search notes…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFF2F2F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
              ),
              onSubmitted: (value) {
                _query = value.trim();
                _load(query: _query.isEmpty ? null : _query);
              },
            ),
          ),
          if (!_loading && _error == null && _notes.isNotEmpty)
            _filterToolbar(displayedCount: displayed.length),
          Expanded(child: _buildBody(displayed)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        backgroundColor: AppColors.primaryPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody(List<UserNoteModel> displayed) {
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
              FilledButton(onPressed: () => _load(), child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_notes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No notes yet.\nTap + to add a word or phrase.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
      );
    }

    if (displayed.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No notes match your filters.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
      itemCount: displayed.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) => _noteTile(displayed[index]),
    );
  }
}
