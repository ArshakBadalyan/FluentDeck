import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';

import '../../models/conversation_training_session.dart';
import '../../models/speaking_session_context.dart';
import '../../models/user_note_model.dart';
import '../../screens/learn_screen/note_edit_screen.dart';
import '../../screens/speaking_hub/widgets/import_decks_to_notes_sheet.dart';
import '../../screens/speaking_hub/widgets/my_notes_filters_sheet.dart';
import '../../services/conversation_service.dart';
import '../../services/my_notes_linked_decks_store.dart';
import '../../services/note_service.dart';
import '../../utils/learning_language_utils.dart';
import '../../widgets/speaking_hub_widgets.dart';

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

  String get _filtersSummary {
    final parts = <String>[];
    if (_levelIndex != 0) {
      parts.add(_levelFilters[_levelIndex].$2);
    }
    if (_languageIndex != 0 && _languageIndex < _languageFilters.length) {
      parts.add(_languageFilters[_languageIndex].value);
    }
    if (_topicFilter != 'all') {
      parts.add(_topicFilter);
    }
    return parts.isEmpty ? 'Level, language, topic' : parts.join(' · ');
  }

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
    final result = await showImportDecksToNotesSheet(context);
    if (!mounted || result == null || !result.ok) return;
    _linkedDecks = await MyNotesLinkedDecksStore.instance.merge(result.linkedDecks);
    final addedDecks =
        result.linkedDecks.where((d) => !d.duplicatesSpeakingSource).toList();
    var nextIndex = _sourceIndex;
    if (addedDecks.isNotEmpty) {
      final target = addedDecks.last;
      final deckIndex = _sourceFilters.indexWhere((f) => f.$1 == 'deck:${target.id}');
      if (deckIndex >= 0) nextIndex = deckIndex;
    }
    setState(() {
      if (nextIndex >= _sourceFilters.length) nextIndex = _speakingSourceIndex;
      _sourceIndex = nextIndex;
      if (_sourceKey.startsWith('deck:')) {
        _topicFilter = 'all';
      }
    });
    await _loadLanguageOptions();
    await _load();
    final msg = StringBuffer('Added ${result.created} note${result.created == 1 ? '' : 's'}');
    if (result.skipped > 0) {
      msg.write(' (${result.skipped} skipped)');
    }
    if (result.limitReached) {
      msg.write('. Note limit reached — upgrade for unlimited saves.');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg.toString())),
    );
  }

  Widget _compactSourceChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected
          ? AppColors.primaryPurple.withValues(alpha: 0.1)
          : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.primaryPurple : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? AppColors.primaryPurple : const Color(0xFF777481),
              fontFamily: 'Rubik',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSourceFilterRow() {
    final filters = _sourceFilters;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
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
          Material(
            color: AppColors.primaryPurple.withValues(alpha: 0.1),
            shape: CircleBorder(
              side: BorderSide(color: AppColors.primaryPurple.withValues(alpha: 0.35)),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _openAddNote,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(7),
                child: Icon(
                  Icons.note_add_outlined,
                  size: 16,
                  color: AppColors.primaryPurple,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Material(
            color: AppColors.primaryPurple.withValues(alpha: 0.1),
            shape: CircleBorder(
              side: BorderSide(color: AppColors.primaryPurple.withValues(alpha: 0.35)),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _openImportDecks,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(7),
                child: Icon(
                  Icons.add_rounded,
                  size: 16,
                  color: AppColors.primaryPurple,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreFiltersBar() {
    final enabled = _advancedFiltersEnabled;
    final active = _hasActiveAdvancedFilters;
    final hasAnyFilters = _hasAnyFilters;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              elevation: 0,
              child: InkWell(
                onTap: enabled ? _showAdvancedFiltersSheet : null,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: active ? AppColors.primaryPurple : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 16,
                        color: enabled ? AppColors.primaryPurple : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          enabled ? _filtersSummary : 'Filters locked for deck source',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                            color: enabled
                                ? (active ? AppColors.primaryPurple : const Color(0xFF777481))
                                : Colors.grey.shade500,
                            fontFamily: 'Rubik',
                          ),
                        ),
                      ),
                      if (active)
                        Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPurple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryPurple,
                              fontFamily: 'Rubik',
                            ),
                          ),
                        ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: enabled ? Colors.grey.shade500 : Colors.grey.shade300,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (hasAnyFilters) ...[
            const SizedBox(width: 6),
            Material(
              color: AppColors.primaryPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _clearAllFilters,
                borderRadius: BorderRadius.circular(12),
                child: Tooltip(
                  message: 'Clear all filters',
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryPurple.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Icon(
                      Icons.filter_alt_off_outlined,
                      size: 18,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrainBar() {
    final count = _selectedIds.length;
    final enabled = count > 0 && !_starting;

    return DecoratedBox(
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
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SizedBox(
            width: double.infinity,
            height: 42,
            child: FilledButton.icon(
              onPressed: enabled ? _startTraining : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                disabledBackgroundColor: AppColors.greySkipped.withValues(alpha: 0.35),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(
                _starting ? Icons.hourglass_top_rounded : Icons.record_voice_over_rounded,
                size: 18,
              ),
              label: Text(
                _starting
                    ? 'Starting…'
                    : count > 0
                        ? 'Train with AI tutor ($count)'
                        : 'Select notes to train',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Rubik',
                ),
              ),
            ),
          ),
        ),
      ),
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
    final confirmed = await showDialog<bool>(
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
      ScaffoldMessenger.of(context).showSnackBar(
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
    final parts = <String>[note.sourceLabel];
    if (note.languageCode.isNotEmpty) {
      parts.add(LearningLanguageUtils.languageLabel(note.languageCode));
    }
    if (note.cefrLevel != null && note.cefrLevel!.isNotEmpty) {
      parts.add(note.cefrLevel!);
    }
    if (note.topic != null && note.topic!.isNotEmpty) {
      parts.add(note.topic!);
    }
    if (note.definition.trim().isNotEmpty) {
      parts.add(_plainText(note.definition));
    } else if (note.exampleSentence.trim().isNotEmpty) {
      parts.add(_plainText(note.exampleSentence));
    }
    return parts.join(' · ');
  }

  Future<void> _startTraining() async {
    if (_starting) return;

    final selected =
        _notes.where((n) => _selectedIds.contains(n.id)).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
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
        ScaffoldMessenger.of(context).showSnackBar(
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start training: $e')),
      );
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No saved notes match these filters.\n'
            'Save words from speaking chat, or tap + to add a deck.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, height: 1.4),
          ),
        ),
      );
    }

    final allSelected = _selectedIds.length == _notes.length;

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primaryPurple,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: allSelected,
                    tristate: true,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    onChanged: (value) => _selectAll(value ?? false),
                    activeColor: AppColors.primaryPurple,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${_selectedIds.length} of ${_notes.length} selected',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontFamily: 'Rubik',
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _selectAll(!allSelected),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
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
              ],
            ),
          ),
          ..._notes.map((note) {
            final selected = _selectedIds.contains(note.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SpeakingSelectionCard(
                title: note.word,
                subtitle: _noteSubtitle(note),
                icon: Icons.menu_book_outlined,
                selected: selected,
                onTap: () => _toggleSelection(note.id),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      tooltip: 'Edit note',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _openEditNote(note),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 20, color: Colors.grey.shade600),
                      tooltip: 'Delete note',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _confirmDeleteNote(note),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSourceFilterRow(),
        _buildMoreFiltersBar(),
        Expanded(child: _buildList()),
        _buildTrainBar(),
      ],
    );
  }
}
