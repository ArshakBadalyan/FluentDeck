import 'package:riovox/ui_elements/app_dialog.dart';
import 'package:riovox/ui_elements/modern_page_widgets.dart';
import 'package:riovox/ui_elements/app_toast.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:riovox/app_colors.dart';

import '../../models/conversation_training_session.dart';
import '../../models/speaking_session_context.dart';
import '../../models/user_note_model.dart';
import '../../screens/learn_screen/note_edit_screen.dart';
import '../../screens/speaking_hub/widgets/import_decks_to_notes_sheet.dart';
import '../../screens/speaking_hub/widgets/my_notes_filters_sheet.dart';
import '../../services/conversation_service.dart';
import '../../services/my_notes_linked_decks_store.dart';
import '../../services/note_service.dart';
import '../../ui_elements/app_skeletons.dart';
import '../../ui_elements/frosted_bottom_sheet.dart';
import '../../utils/learning_language_utils.dart';
import '../../widgets/speaking_hub_widgets.dart';
import 'package:riovox/ui_elements/app_motion.dart';
import 'package:riovox/widgets/rio_empty_state.dart';

class SpeakingNotesTab extends StatefulWidget {
  const SpeakingNotesTab({super.key, required this.onStart});

  final ValueChanged<SpeakingSessionContext> onStart;

  @override
  State<SpeakingNotesTab> createState() => _SpeakingNotesTabState();
}

class _SpeakingNotesTabState extends State<SpeakingNotesTab> {
  static const _levelFilters = [
    ('all', 'All levels'),
    ('A1', 'A1'),
    ('A2', 'A2'),
    ('B1', 'B1'),
    ('B2', 'B2'),
    ('C1', 'C1'),
    ('C2', 'C2'),
    ('none', 'No level'),
  ];

  int _sourceIndex = 1;
  int _levelIndex = 0;
  int _languageIndex = 0;
  String _topicFilter = 'all';
  List<LinkedMyNotesDeck> _linkedDecks = const [];
  List<MapEntry<String, String>> _languageFilters = const [
    MapEntry('all', 'All languages'),
  ];
  List<UserNoteModel> _notes = const [];
  final Set<int> _selectedIds = {};
  bool _loading = true;
  String? _error;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  List<String> _topicOptions = const [];

  String? get _effectiveLanguageCode {
    if (_languageIndex < 0 || _languageIndex >= _languageFilters.length) {
      return null;
    }
    final key = _languageFilters[_languageIndex].key;
    if (key == 'all') return null;
    return key;
  }

  List<LinkedMyNotesDeck> get _visibleLinkedDecks =>
      _linkedDecks.where((d) => !d.duplicatesSpeakingSource).toList();

  List<(String key, String label)> get _sourceFilters => [
    ('all', 'All'),
    ('speaking', 'From speaking'),
    ..._visibleLinkedDecks.map((d) => ('deck:${d.id}', d.name)),
  ];

  int get _speakingSourceIndex => 1;

  String get _sourceKey =>
      _sourceIndex >= 0 && _sourceIndex < _sourceFilters.length
          ? _sourceFilters[_sourceIndex].$1
          : 'all';

  String? get _activeDeckTopic {
    if (!_sourceKey.startsWith('deck:')) return null;
    final id = int.tryParse(_sourceKey.substring(5));
    if (id == null) return null;
    for (final deck in _linkedDecks) {
      if (deck.id == id) return deck.name;
    }
    return null;
  }

  Future<void> _init() async {
    final stored = await MyNotesLinkedDecksStore.instance.load();
    _linkedDecks = stored.where((d) => !d.duplicatesSpeakingSource).toList();
    if (stored.length != _linkedDecks.length) {
      await MyNotesLinkedDecksStore.instance.save(_linkedDecks);
    }
    if (mounted) {
      setState(() => _sourceIndex = _speakingSourceIndex);
    }
    await _loadLanguageOptions();
    await _load();
  }

  Future<void> _loadLanguageOptions() async {
    try {
      final all = await NoteService.instance.fetchNotes(source: 'all');
      if (!mounted) return;
      final codes =
          all
              .map((n) => n.languageCode.trim())
              .where((c) => c.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
      final options = <MapEntry<String, String>>[
        const MapEntry('all', 'All languages'),
        ...codes.map(
          (c) => MapEntry(c, LearningLanguageUtils.languageLabel(c)),
        ),
      ];
      var nextIndex = _languageIndex;
      if (nextIndex >= options.length) nextIndex = 0;
      setState(() => _languageFilters = options);
      if (nextIndex != _languageIndex) {
        setState(() => _languageIndex = nextIndex);
      }
    } catch (_) {}
  }

  String get _levelKey => _levelFilters[_levelIndex].$1;

  String get _sessionLabel {
    final parts = <String>['My notes'];
    if (_sourceKey == 'all') {
      // no extra source label
    } else if (_activeDeckTopic != null) {
      parts.add(_activeDeckTopic!);
    } else if (_sourceKey != 'all') {
      parts.add(_sourceFilters[_sourceIndex].$2);
    }
    if (_levelKey != 'all') {
      parts.add(_levelFilters[_levelIndex].$2);
    }
    if (_topicFilter != 'all') {
      parts.add(_topicFilter);
    }
    return parts.join(' · ');
  }

  Future<void> _loadTopics() async {
    try {
      final deckTopic = _activeDeckTopic;
      final all = await NoteService.instance.fetchNotes(
        source: deckTopic != null
            ? 'deck'
            : (_sourceKey == 'all' ? null : _sourceKey),
        topic: deckTopic,
      );
      if (!mounted) return;
      final topics =
          all
              .map((n) => n.topic?.trim())
              .whereType<String>()
              .where((t) => t.isNotEmpty)
              .toSet()
              .toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      setState(() {
        _topicOptions = topics;
        if (_topicFilter != 'all' && !topics.contains(_topicFilter)) {
          _topicFilter = 'all';
        }
      });
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final deckTopic = _activeDeckTopic;
      final notes = await NoteService.instance.fetchNotes(
        source: deckTopic != null
            ? 'deck'
            : (_sourceKey == 'all' ? null : _sourceKey),
        cefrLevel: _levelKey,
        topic: deckTopic ?? (_topicFilter == 'all' ? null : _topicFilter),
        languageCode: _effectiveLanguageCode,
      );
      if (!mounted) return;
      setState(() {
        _notes = notes;
        _selectedIds
          ..clear()
          ..addAll(notes.map((n) => n.id));
        _loading = false;
      });
      unawaited(_loadTopics());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onSourceSelected(int index) {
    if (index < 0 || index >= _sourceFilters.length) return;
    setState(() {
      _sourceIndex = index;
      if (_sourceFilters[index].$1.startsWith('deck:')) {
        _topicFilter = 'all';
      }
    });
    _load();
  }

  bool get _advancedFiltersEnabled => _activeDeckTopic == null;

  bool get _hasActiveAdvancedFilters =>
      _levelIndex != 0 || _languageIndex != 0 || _topicFilter != 'all';

  bool get _hasAnyFilters =>
      _sourceIndex != _speakingSourceIndex || _hasActiveAdvancedFilters;

  Future<void> _showAdvancedFiltersSheet() async {
    if (!_advancedFiltersEnabled) return;
    final result = await showMyNotesFiltersSheet(
      context,
      levelLabels: _levelFilters.map((f) => f.$2).toList(),
      levelIndex: _levelIndex,
      languageLabels: _languageFilters.map((f) {
        if (f.key == 'all') return f.value;
        return f.value;
      }).toList(),
      languageIndex: _languageIndex,
      topicOptions: _topicOptions,
      topicFilter: _topicFilter,
      enabled: _advancedFiltersEnabled,
    );
    if (result == null || !mounted) return;
    setState(() {
      _levelIndex = result.levelIndex;
      _languageIndex = result.languageIndex;
      _topicFilter = result.topicFilter;
    });
    _load();
  }

  void _clearAllFilters() {
    if (!_hasAnyFilters) return;
    setState(() {
      _sourceIndex = _speakingSourceIndex;
      _levelIndex = 0;
      _languageIndex = 0;
      _topicFilter = 'all';
    });
    _load();
  }

  Future<void> _openAddNote() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const NoteEditScreen()),
    );
    if (saved == true && mounted) {
      await _loadLanguageOptions();
      await _load();
    }
  }

  Future<void> _openImportDecks() async {
    final previousIds = _linkedDecks.map((d) => d.id).toSet();
    final result = await showImportDecksToNotesSheet(context);
    if (!mounted || result == null || !result.ok) return;
    // The sheet returns the full set of linked decks (added and removed).
    await MyNotesLinkedDecksStore.instance.save(result.linkedDecks);
    _linkedDecks =
        (await MyNotesLinkedDecksStore.instance.load())
            .where((d) => !d.duplicatesSpeakingSource)
            .toList();
    final addedDecks =
        _linkedDecks.where((d) => !previousIds.contains(d.id)).toList();
    final currentKey = _sourceKey;
    var nextIndex = _sourceFilters.indexWhere((f) => f.$1 == currentKey);
    if (addedDecks.isNotEmpty) {
      final target = addedDecks.last;
      final deckIndex = _sourceFilters.indexWhere((f) => f.$1 == 'deck:${target.id}');
      if (deckIndex >= 0) nextIndex = deckIndex;
    }
    setState(() {
      // The chip being viewed may have been removed — fall back to speaking.
      if (nextIndex < 0 || nextIndex >= _sourceFilters.length) {
        nextIndex = _speakingSourceIndex;
      }
      _sourceIndex = nextIndex;
      if (_sourceKey.startsWith('deck:')) {
        _topicFilter = 'all';
      }
    });
    await _loadLanguageOptions();
    await _load();
    if (!mounted) return;
    final parts = <String>[
      if (result.created > 0 || result.removed == 0)
        'Added ${result.created} note${result.created == 1 ? '' : 's'}'
            '${result.skipped > 0 ? ' (${result.skipped} skipped)' : ''}',
      if (result.removed > 0)
        'removed ${result.removed} note${result.removed == 1 ? '' : 's'} from My notes',
    ];
    var msg = parts.join(', ');
    msg = msg[0].toUpperCase() + msg.substring(1);
    if (result.limitReached) {
      msg += '. Note limit reached — upgrade for unlimited saves.';
    }
    AppToast.success(msg);
  }

  Widget _compactSourceChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected
          ? AppColors.brandPrimary.withValues(alpha: 0.1)
          : AppPageColors.fieldBgOf(context),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppPageColors.accentOf(context)
                  : AppPageColors.subtleBorderOf(context),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected
                  ? AppPageColors.accentOf(context)
                  : AppPageColors.subtitleOf(context),
              fontFamily: 'Rubik',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSourceFilterRow() {
    final filters = _sourceFilters;
    final activeCount =
        (_levelIndex != 0 ? 1 : 0) +
        (_languageIndex != 0 ? 1 : 0) +
        (_topicFilter != 'all' ? 1 : 0);

    // Chips scroll; the filter + clear buttons stay pinned at the end.
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 6, 16, 6),
      child: Row(
        children: [
          Expanded(child: _buildSourceChips(filters)),
          // Filters only make sense with notes — but keep them while a filter
          // is on, so an empty filtered list can still be changed/cleared.
          if (_notes.isNotEmpty || _hasActiveAdvancedFilters) ...[
            const SizedBox(width: 6),
            AppFilterButton(
              active: _hasActiveAdvancedFilters,
              count: activeCount,
              tooltip: _advancedFiltersEnabled
                  ? 'Level, language, topic'
                  : 'Filters locked for deck source',
              onPressed: _advancedFiltersEnabled ? _showAdvancedFiltersSheet : null,
            ),
          ],
          if (_hasAnyFilters) ...[
            const SizedBox(width: 6),
            AppClearFiltersButton(onPressed: _clearAllFilters),
          ],
        ],
      ),
    );
  }

  Widget _buildSourceChips(List<(String, String)> filters) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 16),
      child: Row(
        children: [
          for (int index = 0; index < filters.length; index++)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _compactSourceChip(
                label: filters[index].$2,
                selected: index == _sourceIndex,
                onTap: () => _onSourceSelected(index),
              ),
            ),
          Tooltip(
            message: 'Add decks to My notes',
            child: Material(
              color: AppColors.brandPrimary.withValues(alpha: 0.1),
              shape: CircleBorder(
                side: BorderSide(color: AppColors.brandPrimary.withValues(alpha: 0.35)),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _openImportDecks,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(7),
                  child: Icon(
                    Icons.note_add_outlined,
                    semanticLabel: 'Add decks to My notes',
                    size: 16,
                    color: AppColors.brandPrimary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: 'New note',
            child: Material(
              color: AppColors.brandPrimary.withValues(alpha: 0.1),
              shape: CircleBorder(
                side: BorderSide(color: AppColors.brandPrimary.withValues(alpha: 0.35)),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _openAddNote,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(7),
                  child: Icon(
                    Icons.add_rounded,
                    semanticLabel: 'New note',
                    size: 16,
                    color: AppColors.brandPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainBar() {
    final count = _selectedIds.length;
    return SpeakingStartButton(
      label: _starting
          ? 'Starting…'
          : count > 0
              ? 'Practice $count note${count == 1 ? '' : 's'}'
              : 'Select notes to practice',
      enabled: count > 0 && !_starting,
      onPressed: _startTraining,
    );
  }

  Future<void> _openEditNote(UserNoteModel note) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => NoteEditScreen(note: note)),
    );
    if (saved == true && mounted) {
      await _loadLanguageOptions();
      await _load();
    }
  }

  Future<void> _confirmDeleteNote(UserNoteModel note) async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete note?'),
        content: Text('Remove "${note.word}" from your saved notes?'),
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
    if (confirmed != true || !mounted) return;
    final ok = await NoteService.instance.deleteNote(note.id);
    if (!mounted) return;
    if (ok) {
      await _loadLanguageOptions();
      await _load();
    } else {
      AppToast.showSnackBar(context, 
        const SnackBar(content: Text('Could not delete note')),
      );
    }
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(bool value) {
    setState(() {
      if (value) {
        _selectedIds.addAll(_notes.map((n) => n.id));
      } else {
        _selectedIds.clear();
      }
    });
  }

  String _plainText(String raw) {
    return raw
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _noteSubtitle(UserNoteModel note) {
    final parts = <String>[];
    if (note.definition.trim().isNotEmpty) {
      parts.add(_plainText(note.definition));
    } else if (note.exampleSentence.trim().isNotEmpty) {
      parts.add(_plainText(note.exampleSentence));
    }
    if (note.sourceLabel.trim().isNotEmpty) parts.add('from ${note.sourceLabel.trim()}');
    return parts.join(' · ');
  }

  /// Edit / delete for one note (row menu or long-press).
  Future<void> _showNoteActions(UserNoteModel note) async {
    final action = await showFrostedBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit note'),
                onTap: () => Navigator.pop(ctx, 'edit'),
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: AppPageColors.tintOf(ctx, AppTint.danger).fg),
                title: Text('Delete note', style: TextStyle(color: AppPageColors.tintOf(ctx, AppTint.danger).fg)),
                onTap: () => Navigator.pop(ctx, 'delete'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'edit') await _openEditNote(note);
    if (action == 'delete') await _confirmDeleteNote(note);
  }

  Future<void> _startTraining() async {
    if (_starting) return;

    final selected =
        _notes.where((n) => _selectedIds.contains(n.id)).toList();
    if (selected.isEmpty) {
      AppToast.showSnackBar(context, 
        const SnackBar(content: Text('Select at least one note to practice.')),
      );
      return;
    }

    setState(() => _starting = true);
    try {
      final words =
          selected
              .take(20)
              .map((note) {
                final hintParts = <String>[];
                if (note.definition.trim().isNotEmpty) {
                  hintParts.add(note.definition.trim());
                }
                if (note.exampleSentence.trim().isNotEmpty) {
                  hintParts.add(note.exampleSentence.trim());
                }
                return ConversationTrainingWord(
                  word: note.word.trim(),
                  hint: hintParts.join('\n'),
                );
              })
              .where((w) => w.word.isNotEmpty)
              .toList();

      if (words.isEmpty) {
        if (!mounted) return;
        AppToast.showSnackBar(context, 
          const SnackBar(content: Text('No usable words in your selection.')),
        );
        return;
      }

      final label = _sessionLabel;
      ConversationService.instance.startNotesPractice(
        sessionLabel: label,
        words: words,
      );

      final vocabList = words.map((w) => w.word).toList();
      widget.onStart(
        SpeakingSessionContext(
          mode: SpeakingMode.chat,
          title: label,
          referenceKey: 'practice_my_notes',
          openingMessage:
              "Let's practice your saved notes (${words.length} word${words.length == 1 ? '' : 's'}). "
              "I'll help you recall meanings, use them in sentences, and quiz you. "
              'Ask for hints or examples anytime.',
          suggestedVocabulary: vocabList,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.showSnackBar(context, 
        SnackBar(content: Text('Could not start training: $e')),
      );
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Widget _buildList() {
    if (_loading) {
      return AppLoadingSwitcher(
      loading: true,
      child: const AppListSkeleton(),
    );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_notes.isEmpty) {
      return const RioEmptyState(
        title: 'No notes here yet',
        message: 'Save words from speaking chat, or tap + to add a deck.',
      );
    }

    final allSelected = _selectedIds.length == _notes.length;

    return AppLoadingSwitcher(
      loading: false,
      child: RefreshIndicator(
      onRefresh: _load,
      color: AppColors.brandPrimary,
      child: AppContentWidth(child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                TextButton(
                  onPressed: () => _selectAll(!allSelected),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    allSelected ? 'Clear' : 'Select all',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Rubik',
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${_selectedIds.length} of ${_notes.length} selected',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppPageColors.subtitleOf(context),
                    fontFamily: 'Rubik',
                  ),
                ),
              ],
            ),
          ),
          ..._notes.indexed.map((entry) {
            final (index, note) = entry;
            final selected = _selectedIds.contains(note.id);
            return AppStaggeredFadeIn(
              key: ValueKey('note-${note.id}'),
              index: index,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _NoteRow(
                  title: note.word,
                  subtitle: _noteSubtitle(note),
                  selected: selected,
                  onTap: () => _toggleSelection(note.id),
                  onMore: () => _showNoteActions(note),
                ),
              ),
            );
          }),
        ],
      )),
    ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSourceFilterRow(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(
            'Words and corrections Rio saved for you. Practice them in a conversation.',
            style: TextStyle(fontSize: 14, color: AppPageColors.subtitleOf(context)),
          ),
        ),
        Expanded(child: _buildList()),
        // Nothing to train on an empty list.
        if (_notes.isNotEmpty) _buildTrainBar(),
      ],
    );
  }
}

/// One saved note: checkbox, the phrase, and what it is / where it came from.
class _NoteRow extends StatelessWidget {
  const _NoteRow({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    required this.onMore,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final accent = AppPageColors.accentOf(context);
    return Material(
      color: AppPageColors.cardBgOf(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: selected
            ? BorderSide(color: accent, width: 2)
            : BorderSide(color: AppPageColors.subtleBorderOf(context)),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onMore,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 4, 14),
          child: Row(
            children: [
              Semantics(
                checked: selected,
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: selected,
                    onChanged: (_) => onTap(),
                    activeColor: accent,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppPageColors.textPrimaryOf(context),
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: AppPageColors.subtitleOf(context)),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Note options',
                icon: Icon(Icons.more_vert_rounded, size: 20, color: AppPageColors.mutedOf(context)),
                onPressed: onMore,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
