import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';

import '../../models/conversation_training_session.dart';
import '../../models/flashcard_model.dart';
import '../../models/speaking_session_context.dart';
import '../../services/conversation_service.dart';
import '../../services/flashcard_service.dart';
import '../../services/speaking_preferences_service.dart';
import '../../widgets/speaking_hub_widgets.dart';

class SpeakingPracticeTab extends StatefulWidget {
  const SpeakingPracticeTab({super.key, required this.onStart});

  final ValueChanged<SpeakingSessionContext> onStart;

  @override
  State<SpeakingPracticeTab> createState() => _SpeakingPracticeTabState();
}

class _SpeakingPracticeTabState extends State<SpeakingPracticeTab> {
  static const _filters = [
    ('all', 'All'),
    ('saved_words', 'Saved words'),
    ('from_speaking', 'From speaking'),
    ('custom', 'My decks'),
  ];

  int _filterIndex = 0;
  List<FlashcardDeckModel> _allDecks = [];
  List<FlashcardDeckModel> _decks = [];
  FlashcardDeckModel? _selected;
  bool _loading = true;
  String? _error;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final decks = await FlashcardService.instance.fetchDecksWithCache();
      if (!mounted) return;
      setState(() {
        _allDecks = decks;
        _loading = false;
      });
      _applyFilter();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _applyFilter() {
    final key = _filters[_filterIndex].$1;
    List<FlashcardDeckModel> filtered;
    switch (key) {
      case 'saved_words':
        filtered =
            _allDecks.where((d) => d.deckSlug == 'saved_words').toList();
      case 'from_speaking':
        filtered =
            _allDecks.where((d) => d.deckSlug == 'from_speaking').toList();
      case 'custom':
        filtered =
            _allDecks
                .where((d) => !d.isDefault && !d.isFiltered)
                .toList();
      default:
        filtered = List<FlashcardDeckModel>.from(_allDecks);
    }

    setState(() {
      _decks = filtered;
      _selected =
          filtered.any((d) => d.id == _selected?.id)
              ? _selected
              : (filtered.isNotEmpty ? filtered.first : null);
    });
  }

  String _deckSubtitle(FlashcardDeckModel deck) {
    final parts = <String>[];
    if (deck.total > 0) {
      parts.add('${deck.total} cards');
    } else {
      parts.add('No cards yet');
    }
    if (deck.dueCount > 0) {
      parts.add('${deck.dueCount} due');
    }
    if (deck.description.trim().isNotEmpty) {
      parts.add(deck.description.trim());
    }
    return parts.join(' · ');
  }

  Future<void> _startPractice() async {
    final deck = _selected;
    if (deck == null || _starting) return;

    setState(() => _starting = true);
    try {
      final detail = await FlashcardService.instance.fetchDeckDetail(deck.id);
      final prefs = await SpeakingPreferencesService.instance.load();
      var cards = detail.cards;
      if (prefs.syncLearningLanguage) {
        cards =
            cards
                .where((c) => c.languageCode == prefs.practiceLanguage)
                .toList();
      }
      if (cards.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Add cards to "${deck.name}" before practicing.'),
          ),
        );
        return;
      }

      final words =
          cards
              .take(12)
              .map(
                (card) => ConversationTrainingWord(
                  word: card.front.trim(),
                  hint: card.back.trim(),
                ),
              )
              .where((w) => w.word.isNotEmpty)
              .toList();

      if (words.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No usable words found in this deck.')),
        );
        return;
      }

      final sourceKey =
          deck.deckSlug.isNotEmpty ? deck.deckSlug : 'deck_${deck.id}';
      ConversationService.instance.startDeckPractice(
        deckName: deck.name,
        sourceKey: sourceKey,
        deckId: deck.id,
        words: words,
      );
      widget.onStart(
        SpeakingSessionContext(
          mode: SpeakingMode.chat,
          title: deck.name,
          referenceKey: 'practice_$sourceKey',
          openingMessage:
              "Let's practice your \"${deck.name}\" deck. "
              "I'll help you use these words naturally - ask me to quiz you anytime, "
              'or say "save this to my deck" to add new notes.',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start practice: $e')),
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
    if (_decks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _filters[_filterIndex].$1 == 'custom'
                ? 'No custom decks yet.\nCreate one in the Decks tab first.'
                : 'No decks in this category.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primaryPurple,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _decks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final deck = _decks[index];
          return SpeakingSelectionCard(
            title: deck.name,
            subtitle: _deckSubtitle(deck),
            icon: Icons.style_outlined,
            selected: _selected?.id == deck.id,
            onTap: () => setState(() => _selected = deck),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(
            'Practice words and expressions from your decks. '
            'During chat you can ask the tutor to save new notes to a deck.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.grey.shade700,
              fontFamily: 'Rubik',
            ),
          ),
        ),
        SpeakingFilterChips(
          labels: _filters.map((f) => f.$2).toList(),
          selectedIndex: _filterIndex,
          onSelected: (index) {
            setState(() => _filterIndex = index);
            _applyFilter();
          },
        ),
        Expanded(child: _buildList()),
        SpeakingStartButton(
          label: _starting ? 'Loading deck…' : 'Start Deck Practice',
          enabled: _selected != null && !_starting,
          onPressed: _starting ? null : _startPractice,
        ),
      ],
    );
  }
}
