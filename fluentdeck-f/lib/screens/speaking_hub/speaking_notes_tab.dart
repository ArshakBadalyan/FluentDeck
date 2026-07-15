import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';

import '../../models/conversation_training_session.dart';
import '../../models/speaking_session_context.dart';
import '../../models/user_note_model.dart';
import '../../services/conversation_service.dart';
import '../../services/note_service.dart';
import '../../services/speaking_preferences_service.dart';
import '../../utils/learning_language_utils.dart';
import '../../widgets/speaking_hub_widgets.dart';

class SpeakingNotesTab extends StatefulWidget {
  const SpeakingNotesTab({super.key, required this.onStart});

  final ValueChanged<SpeakingSessionContext> onStart;

  @override
  State<SpeakingNotesTab> createState() => _SpeakingNotesTabState();
}

class _SpeakingNotesTabState extends State<SpeakingNotesTab> {
  static const _sourceFilters = [
    ('all', 'All'),
    ('speaking', 'From speaking'),
    ('manual', 'Manual'),
  ];

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

  int _sourceIndex = 0;
  int _levelIndex = 0;
  int _languageIndex = 0;
  String _topicFilter = 'all';
  String _practiceLanguage = 'en';
  bool _syncLearningLanguage = true;
  List<String> _topicOptions = const [];
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

  List<MapEntry<String, String>> get _languageFilters =>
      LearningLanguageUtils.filterOptions();

  String? get _effectiveLanguageCode => LearningLanguageUtils.effectiveFilterCode(
    syncLearningLanguage: _syncLearningLanguage,
    practiceLanguage: _practiceLanguage,
    manualFilter: _languageFilters[_languageIndex].key,
  );

  Future<void> _init() async {
    final prefs = await SpeakingPreferencesService.instance.load();
    if (!mounted) return;
    setState(() {
      _syncLearningLanguage = prefs.syncLearningLanguage;
      _practiceLanguage = prefs.practiceLanguage;
      if (prefs.syncLearningLanguage) {
        _languageIndex = _languageFilters.indexWhere(
          (e) => e.key == prefs.practiceLanguage,
        );
        if (_languageIndex < 0) _languageIndex = 0;
      }
    });
    await _load();
  }

  String get _sourceKey => _sourceFilters[_sourceIndex].$1;
  String get _levelKey => _levelFilters[_levelIndex].$1;

  String get _sessionLabel {
    final parts = <String>['My notes'];
    if (_sourceKey != 'all') {
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
      final all = await NoteService.instance.fetchNotes(source: _sourceKey);
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
      final notes = await NoteService.instance.fetchNotes(
        source: _sourceKey,
        cefrLevel: _levelKey,
        topic: _topicFilter,
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
    setState(() => _sourceIndex = index);
    _load();
  }

  void _onLevelSelected(int index) {
    setState(() => _levelIndex = index);
    _load();
  }

  void _onLanguageSelected(int index) {
    if (_syncLearningLanguage) return;
    setState(() => _languageIndex = index);
    _load();
  }

  Future<void> _pickTopic() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  'Topic',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Rubik',
                  ),
                ),
              ),
              ListTile(
                title: const Text('All topics'),
                trailing: _topicFilter == 'all'
                    ? const Icon(Icons.check, color: AppColors.primaryPurple)
                    : null,
                onTap: () => Navigator.pop(ctx, 'all'),
              ),
              for (final topic in _topicOptions)
                ListTile(
                  title: Text(topic),
                  trailing: _topicFilter == topic
                      ? const Icon(Icons.check, color: AppColors.primaryPurple)
                      : null,
                  onTap: () => Navigator.pop(ctx, topic),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() => _topicFilter = picked);
    _load();
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

  String _noteSubtitle(UserNoteModel note) {
    final parts = <String>[note.sourceLabel];
    if (note.cefrLevel != null && note.cefrLevel!.isNotEmpty) {
      parts.add(note.cefrLevel!);
    }
    if (note.topic != null && note.topic!.isNotEmpty) {
      parts.add(note.topic!);
    }
    if (note.definition.trim().isNotEmpty) {
      parts.add(note.definition.trim());
    } else if (note.exampleSentence.trim().isNotEmpty) {
      parts.add(note.exampleSentence.trim());
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
            'Save words from speaking chat, or add notes manually.',
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
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        children: [
          Row(
            children: [
              Checkbox(
                value: allSelected,
                tristate: true,
                onChanged: (value) => _selectAll(value ?? false),
                activeColor: AppColors.primaryPurple,
              ),
              Text(
                '${_selectedIds.length} of ${_notes.length} selected',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontFamily: 'Rubik',
                ),
              ),
            ],
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
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topicLabel =
        _topicFilter == 'all' ? 'All topics' : _topicFilter;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(
            'Practice words you saved as notes. Filter by level, source, or topic, '
            'then train with the AI tutor on your list.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.grey.shade700,
              fontFamily: 'Rubik',
            ),
          ),
        ),
        SpeakingFilterChips(
          labels: _sourceFilters.map((f) => f.$2).toList(),
          selectedIndex: _sourceIndex,
          onSelected: _onSourceSelected,
        ),
        SpeakingFilterChips(
          labels: _levelFilters.map((f) => f.$2).toList(),
          selectedIndex: _levelIndex,
          onSelected: _onLevelSelected,
        ),
        if (_syncLearningLanguage)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilterChip(
                label: Text(
                  'Language: ${LearningLanguageUtils.languageLabel(_practiceLanguage)}',
                ),
                selected: true,
                onSelected: null,
                selectedColor: AppColors.primaryPurple.withValues(alpha: 0.12),
                checkmarkColor: AppColors.primaryPurple,
                labelStyle: const TextStyle(
                  color: AppColors.primaryPurple,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Rubik',
                ),
                side: const BorderSide(color: AppColors.primaryPurple),
              ),
            ),
          )
        else
          SpeakingFilterChips(
            labels: _languageFilters.map((f) => f.value).toList(),
            selectedIndex: _languageIndex,
            onSelected: _onLanguageSelected,
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FilterChip(
              label: Text('Topic: $topicLabel'),
              selected: _topicFilter != 'all',
              onSelected: (_) => _pickTopic(),
              selectedColor: AppColors.primaryPurple.withValues(alpha: 0.12),
              checkmarkColor: AppColors.primaryPurple,
              labelStyle: TextStyle(
                color: _topicFilter != 'all'
                    ? AppColors.primaryPurple
                    : const Color(0xFF777481),
                fontWeight: FontWeight.w500,
                fontFamily: 'Rubik',
              ),
              side: BorderSide(
                color: _topicFilter != 'all'
                    ? AppColors.primaryPurple
                    : Colors.grey.shade300,
              ),
            ),
          ),
        ),
        Expanded(child: _buildList()),
        SpeakingStartButton(
          label: _starting ? 'Starting…' : 'Train with AI tutor',
          enabled: _selectedIds.isNotEmpty && !_starting,
          onPressed: _starting ? null : _startTraining,
        ),
      ],
    );
  }
}
