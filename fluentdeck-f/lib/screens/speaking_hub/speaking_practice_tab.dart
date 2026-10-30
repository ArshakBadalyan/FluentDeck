import 'package:riovox/ui_elements/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:riovox/app_colors.dart';

import '../../models/conversation_training_session.dart';
import '../../models/flashcard_model.dart';
import '../../models/speaking_session_context.dart';
import '../../services/conversation_service.dart';
import '../../services/flashcard_service.dart';
import '../../services/speaking_preferences_service.dart';
import '../../ui_elements/app_skeletons.dart';
import '../../ui_elements/modern_page_widgets.dart';
import '../../utils/deck_visuals.dart';
import '../../widgets/speaking_hub_widgets.dart';
import 'package:riovox/ui_elements/app_motion.dart';

class SpeakingPracticeTab extends StatefulWidget {
  const SpeakingPracticeTab({super.key, required this.onStart});

  final ValueChanged<SpeakingSessionContext> onStart;

  @override
  State<SpeakingPracticeTab> createState() => _SpeakingPracticeTabState();
}

class _SpeakingPracticeTabState extends State<SpeakingPracticeTab> {
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
        _decks = decks;
        _selected =
            _selected != null && decks.any((d) => d.id == _selected!.id)
                ? _selected
                : (decks.isNotEmpty ? decks.first : null);
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

  /// "42 words · 6 due today", or the deck's description when nothing is due.
  String _deckSubtitle(FlashcardDeckModel deck) {
    final parts = <String>[
      deck.total > 0 ? '${deck.total} word${deck.total == 1 ? '' : 's'}' : 'No words yet',
    ];
    if (deck.dueCount > 0) {
      parts.add('${deck.dueCount} due today');
    } else if (deck.description.trim().isNotEmpty) {
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
        AppToast.showSnackBar(context, 
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
        AppToast.showSnackBar(context, 
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
      AppToast.showSnackBar(context, 
        SnackBar(content: Text('Could not start practice: $e')),
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
    if (_decks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No decks yet.\nCreate one in the Decks tab first.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return AppLoadingSwitcher(
      loading: false,
      child: RefreshIndicator(
      onRefresh: _load,
      color: AppColors.brandPrimary,
      child: AppContentWidth(child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
        itemCount: _decks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final deck = _decks[index];
          return SpeakingSelectionCard(
            title: deck.name,
            subtitle: _deckSubtitle(deck),
            icon: deckIcon(deck.name),
            iconTint: deckTint(deck.name),
            selected: _selected?.id == deck.id,
            trailing: _selected?.id == deck.id
                ? Icon(Icons.check_circle_rounded, color: AppPageColors.accentOf(context))
                : null,
            onTap: () => setState(() => _selected = deck),
          );
        },
      )),
    ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Text(
            'Pick a deck. Rio will build a conversation that uses its words.',
            style: TextStyle(fontSize: 14, color: AppPageColors.subtitleOf(context)),
          ),
        ),
        Expanded(child: _buildList()),
        SpeakingStartButton(
          label: _starting
              ? 'Loading deck…'
              : _selected == null
              ? 'Pick a deck to practice'
              : 'Practice “${_selected!.name}”',
          enabled: _selected != null && !_starting,
          onPressed: _starting ? null : _startPractice,
        ),
      ],
    );
  }
}
