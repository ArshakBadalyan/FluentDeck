import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/models/flashcard_model.dart';
import 'package:fluentdeck/screens/learn_screen/card_browser_screen.dart';
import 'package:fluentdeck/screens/learn_screen/card_edit_screen.dart';
import 'package:fluentdeck/screens/learn_screen/review_session_screen.dart';
import 'package:fluentdeck/services/flashcard_service.dart';
import 'package:fluentdeck/widgets/swipe_action_backgrounds.dart';

class DeckDetailScreen extends StatefulWidget {
  const DeckDetailScreen({super.key, required this.deckId});

  final int deckId;

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  bool _loading = true;
  String? _error;
  bool _changed = false;
  FlashcardDeckModel? _deck;
  List<FlashcardModel> _cards = const [];

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
      final result = await FlashcardService.instance.fetchDeckDetail(widget.deckId);
      if (!mounted) return;
      setState(() {
        _deck = result.deck;
        _cards = result.cards;
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

  Future<void> _addNote() async {
    final saved = await CardEditScreen.showAddSheet(context, deckId: widget.deckId);
    if (!mounted) return;
    if (saved == true) {
      _changed = true;
      await _load();
    }
  }

  Future<void> _openBrowser() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CardBrowserScreen(deckId: widget.deckId),
      ),
    );
    if (mounted) {
      _changed = true;
      await _load();
    }
  }

  Future<void> _editCard(FlashcardModel card) async {
    if (card.noteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This card has no linked note to edit')),
      );
      return;
    }

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder:
            (_) => CardEditScreen(
              deckId: widget.deckId,
              noteId: card.noteId,
            ),
      ),
    );
    if (saved == true) {
      _changed = true;
      await _load();
    }
  }

  Future<void> _deleteCard(FlashcardModel card) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete card?'),
            content: Text('Remove "${card.displayFront}" from this deck?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (ok != true || !mounted) return;

    await FlashcardService.instance.deleteCard(card.id);
    _changed = true;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: BackButton(
          onPressed: () => Navigator.pop(context, _changed ? true : null),
        ),
        title: Text(_deck?.name ?? 'Deck'),
        actions: [
          IconButton(
            icon: const Icon(Icons.manage_search),
            tooltip: 'Browse cards',
            onPressed: _openBrowser,
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed:
                () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder:
                        (_) => ReviewSessionScreen(deckId: widget.deckId),
                  ),
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        tooltip: 'Add note',
        child: const Icon(Icons.add),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_cards.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No cards in this deck yet.\nTap + to add a note.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _cards.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final card = _cards[index];
        return Dismissible(
          key: ValueKey('card-${card.id}'),
          direction: DismissDirection.horizontal,
          background: SwipeActionBackgrounds.edit(),
          secondaryBackground: SwipeActionBackgrounds.delete(),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              await _editCard(card);
            } else if (direction == DismissDirection.endToStart) {
              await _deleteCard(card);
            }
            return false;
          },
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
              ),
              child: ListTile(
                title: Text(
                  card.displayFront,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  [
                    card.templateName,
                    card.reviewState?.state ?? 'new',
                  ].join(' · '),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
