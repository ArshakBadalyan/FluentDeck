import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:speakstack/app_colors.dart';
import 'package:speakstack/data/flashcard_offline_store.dart';
import 'package:speakstack/models/flashcard_model.dart';
import 'package:speakstack/services/flashcard_service.dart';
import 'package:speakstack/services/flashcard_sync_service.dart';
import 'package:speakstack/utils/sm2_preview.dart';
import 'package:speakstack/utils/card_browser_utils.dart';
import 'package:speakstack/utils/html_text_utils.dart';
import 'package:speakstack/models/occlusion_model.dart';
import 'package:speakstack/screens/learn_screen/decks_settings_screen.dart';
import 'package:speakstack/services/review_settings_store.dart';
import 'package:speakstack/utils/review_queue_order.dart';
import 'package:speakstack/utils/type_answer_utils.dart';
import 'package:speakstack/widgets/image_occlusion_review.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ReviewSessionScreen extends StatefulWidget {
  const ReviewSessionScreen({super.key, this.deckId});

  final int? deckId;

  @override
  State<ReviewSessionScreen> createState() => _ReviewSessionScreenState();
}

class _ReviewSessionScreenState extends State<ReviewSessionScreen> {
  bool _loading = true;
  bool _startedEmpty = false;
  String? _error;
  List<FlashcardModel> _queue = const [];
  int _index = 0;
  bool _revealed = false;
  bool _submitting = false;
  bool _answerChecked = false;
  bool? _answerCorrect;
  DateTime? _cardShownAt;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _typeAnswerCtrl = TextEditingController();
  ReviewSettings _settings = const ReviewSettings();
  Offset? _panStart;
  Timer? _elapsedTimer;
  Map<int, DeckOptionsModel> _deckOptionsById = const {};

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    WakelockPlus.disable();
    _audioPlayer.dispose();
    _typeAnswerCtrl.dispose();
    super.dispose();
  }

  void _applyWakelock() {
    if (_settings.keepScreenOn) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  bool _isTypeAnswer(FlashcardModel card) => card.cardType == 'type_answer';
  bool _isCloze(FlashcardModel card) => card.cardType == 'cloze';
  bool _isImageOcclusion(FlashcardModel card) => card.isImageOcclusion;

  void _resetCardState() {
    _revealed = false;
    _answerChecked = false;
    _answerCorrect = null;
    _typeAnswerCtrl.clear();
  }

  DeckOptionsModel _deckOptionsFor(FlashcardModel card) {
    if (card.deckId > 0) {
      return _deckOptionsById[card.deckId] ?? const DeckOptionsModel();
    }
    return const DeckOptionsModel();
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  String _elapsedLabel() {
    if (_cardShownAt == null) return '0:00';
    final total = DateTime.now().difference(_cardShownAt!).inSeconds;
    final minutes = total ~/ 60;
    final seconds = total % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _advanceAfterAction() async {
    if (!mounted) return;
    final nextIndex = _index + 1;
    setState(() {
      _index = nextIndex;
      _resetCardState();
    });
    if (nextIndex < _queue.length) {
      _cardShownAt = DateTime.now();
      _startElapsedTimer();
      await _maybeAutoplayAudio(_queue[nextIndex]);
    }
  }

  Future<void> _playMedia(String url) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(url));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not play media')),
      );
    }
  }

  Future<void> _maybeAutoplayAudio(FlashcardModel card) async {
    final url = card.mediaUrl?.trim();
    if (url == null || url.isEmpty) return;
    final lower = url.toLowerCase();
    final isAudio =
        lower.endsWith('.mp3') ||
        lower.endsWith('.wav') ||
        lower.endsWith('.m4a') ||
        lower.endsWith('.ogg') ||
        (!lower.endsWith('.png') &&
            !lower.endsWith('.jpg') &&
            !lower.endsWith('.jpeg') &&
            !lower.endsWith('.gif') &&
            !lower.endsWith('.webp'));
    if (isAudio) await _playMedia(url);
  }

  Widget _mediaWidget(FlashcardModel card) {
    final url = card.mediaUrl?.trim();
    if (url == null || url.isEmpty) return const SizedBox.shrink();

    final lower = url.toLowerCase();
    final isImage =
        lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp');

    if (isImage) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(url, height: 160, fit: BoxFit.cover),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: OutlinedButton.icon(
        onPressed: () => _playMedia(url),
        icon: const Icon(Icons.volume_up),
        label: const Text('Play audio'),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    ReviewSettingsStore.instance.load().then((settings) {
      if (mounted) {
        setState(() => _settings = settings);
        _applyWakelock();
      }
    });
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      List<FlashcardModel> queue;
      try {
        final decks = await FlashcardService.instance.fetchDecks();
        _deckOptionsById = {
          for (final d in decks)
            d.id: d.deckOptions ?? const DeckOptionsModel(),
        };
        queue = await FlashcardService.instance.fetchReviewQueue(
          deckId: widget.deckId,
          newCardOrder: _settings.newCardPosition,
          learnAheadMinutes: _settings.learnAheadMinutes,
        );
        await FlashcardService.instance.cacheReviewQueue(
          queue: queue,
          deckId: widget.deckId,
        );
      } catch (_) {
        final cached = await FlashcardOfflineStore.instance.loadSnapshot();
        _deckOptionsById = {
          for (final d in cached.decks)
            d.id: d.deckOptions ?? const DeckOptionsModel(),
        };
        queue = await FlashcardService.instance.loadCachedReviewQueue(
          deckId: widget.deckId,
        );
        if (queue.isEmpty) {
          queue =
              cached.cards.where((c) {
                if (widget.deckId != null && c.deckId != widget.deckId) {
                  return false;
                }
                return c.reviewState?.isDue ?? true;
              }).toList();
        }
      }

      if (!mounted) return;
      final ordered = applyNewCardPosition(queue, _settings.newCardPosition);
      setState(() {
        _queue = ordered;
        _startedEmpty = ordered.isEmpty;
        _loading = false;
      });

      if (ordered.isNotEmpty) {
        _cardShownAt = DateTime.now();
        _startElapsedTimer();
        await _maybeAutoplayAudio(ordered.first);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _answer(String rating) async {
    if (_submitting || _index >= _queue.length) return;
    final card = _queue[_index];
    setState(() => _submitting = true);

    try {
      final durationMs =
          _cardShownAt != null
              ? DateTime.now().difference(_cardShownAt!).inMilliseconds
              : null;
      try {
        final result = await FlashcardService.instance.submitReview(
          flashcardId: card.id,
          rating: rating,
          durationMs: durationMs,
        );
        if (result.leechSuspended && _settings.leechAutoSuspend && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Leech — card auto-suspended due to too many lapses'),
            ),
          );
        }
      } catch (_) {
        final reviewedAt = DateTime.now();
        await FlashcardOfflineStore.instance.queueReview(
          flashcardId: card.id,
          rating: rating,
          reviewedAt: reviewedAt,
        );
        final nextState = previewAfterRating(
          card.reviewState ?? const CardReviewStateModel(),
          rating,
          now: reviewedAt,
          deckOptions: _deckOptionsFor(card),
        );
        await FlashcardOfflineStore.instance.updateCachedCard(
          FlashcardModel(
            id: card.id,
            deckId: card.deckId,
            noteId: card.noteId,
            front: card.front,
            back: card.back,
            cardType: card.cardType,
            clozeText: card.clozeText,
            clozeIndex: card.clozeIndex,
            templateName: card.templateName,
            templateOrdinal: card.templateOrdinal,
            tags: card.tags,
            mediaUrl: card.mediaUrl,
            flag: card.flag,
            deckName: card.deckName,
            noteMarked: card.noteMarked,
            reviewState: nextState,
            occlusionData: card.occlusionData,
          ),
        );
        FlashcardSyncService.instance.markPending();
      }

      if (!mounted) return;
      final nextIndex = _index + 1;
      setState(() {
        _submitting = false;
        _index = nextIndex;
        _resetCardState();
      });

      if (nextIndex < _queue.length) {
        _cardShownAt = DateTime.now();
        _startElapsedTimer();
        await _maybeAutoplayAudio(_queue[nextIndex]);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _undo() async {
    if (_index == 0) return;
    try {
      final card = await FlashcardService.instance.undoReview();
      if (card == null || !mounted) return;
      setState(() {
        _index -= 1;
        final updated = List<FlashcardModel>.from(_queue);
        updated[_index] = card;
        _queue = updated;
        _resetCardState();
      });
      _cardShownAt = DateTime.now();
      _startElapsedTimer();
      await _maybeAutoplayAudio(card);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _setFlag(int flag) async {
    if (_index >= _queue.length) return;
    final card = _queue[_index];
    try {
      final updated = await FlashcardService.instance.setCardFlag(card.id, flag);
      if (updated == null || !mounted) return;
      setState(() {
        final list = List<FlashcardModel>.from(_queue);
        list[_index] = updated;
        _queue = list;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _toggleMarked() async {
    if (_index >= _queue.length) return;
    final card = _queue[_index];
    final noteId = card.noteId;
    if (noteId == null) return;
    final next = !card.noteMarked;
    try {
      await FlashcardService.instance.setNoteMarked(noteId, next);
      if (!mounted) return;
      setState(() {
        final list = List<FlashcardModel>.from(_queue);
        list[_index] = FlashcardModel(
          id: card.id,
          deckId: card.deckId,
          noteId: card.noteId,
          front: card.front,
          back: card.back,
          cardType: card.cardType,
          clozeText: card.clozeText,
          clozeIndex: card.clozeIndex,
          templateName: card.templateName,
          templateOrdinal: card.templateOrdinal,
          tags: card.tags,
          mediaUrl: card.mediaUrl,
          flag: card.flag,
          deckName: card.deckName,
          noteMarked: next,
          reviewState: card.reviewState,
          occlusionData: card.occlusionData,
        );
        _queue = list;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _unburyCard() async {
    if (_index >= _queue.length) return;
    final card = _queue[_index];
    try {
      await FlashcardService.instance.unburyCard(card.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Card unburied')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _buryCurrentCard() async {
    if (_index >= _queue.length) return;
    final card = _queue[_index];
    try {
      await FlashcardService.instance.buryCard(card.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Card buried until tomorrow')),
      );
      await _advanceAfterAction();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _toggleSuspend() async {
    if (_index >= _queue.length) return;
    final card = _queue[_index];
    final suspended = card.reviewState?.suspended == true;
    try {
      final updated =
          suspended
              ? await FlashcardService.instance.unsuspendCard(card.id)
              : await FlashcardService.instance.suspendCard(card.id);
      if (updated == null || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(suspended ? 'Card unsuspended' : 'Card suspended'),
        ),
      );
      if (!suspended) {
        await _advanceAfterAction();
        return;
      }
      setState(() {
        final list = List<FlashcardModel>.from(_queue);
        list[_index] = updated;
        _queue = list;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _burySiblings() async {
    if (_index >= _queue.length) return;
    final card = _queue[_index];
    try {
      final buried = await FlashcardService.instance.burySiblings(card.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            buried > 0
                ? 'Buried $buried sibling card${buried == 1 ? '' : 's'}'
                : 'No sibling cards to bury',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _checkTypeAnswer(FlashcardModel card) {
    final correct = isTypeAnswerCorrect(_typeAnswerCtrl.text, card.back);
    setState(() {
      _answerChecked = true;
      _answerCorrect = correct;
      _revealed = true;
    });
  }

  void _revealCard() {
    if (_isTypeAnswer(_queue[_index]) && !_answerChecked) return;
    setState(() => _revealed = true);
  }

  void _handleGestureAction(ReviewGestureAction action) {
    switch (action) {
      case ReviewGestureAction.none:
        return;
      case ReviewGestureAction.reveal:
        _revealCard();
      case ReviewGestureAction.again:
        if (_revealed) _answer('again');
      case ReviewGestureAction.hard:
        if (_revealed) _answer('hard');
      case ReviewGestureAction.good:
        if (_revealed) _answer('good');
      case ReviewGestureAction.easy:
        if (_revealed) _answer('easy');
    }
  }

  void _onPanEnd(DragEndDetails details, Size areaSize) {
    if (!_settings.gesturesEnabled || _panStart == null) return;
    final velocity = details.velocity.pixelsPerSecond;
    if (velocity.dx.abs() < 120 && velocity.dy.abs() < 120) return;

    if (velocity.dx.abs() > velocity.dy.abs()) {
      _handleGestureAction(
        velocity.dx < 0
            ? _settings.gestures.swipeLeft
            : _settings.gestures.swipeRight,
      );
    } else {
      _handleGestureAction(
        velocity.dy < 0
            ? _settings.gestures.swipeUp
            : _settings.gestures.swipeDown,
      );
    }
    _panStart = null;
  }

  OcclusionData _occlusionForCard(FlashcardModel card) {
    if (card.occlusionData != null && card.occlusionData!.imageUrl.isNotEmpty) {
      return card.occlusionData!;
    }
    return OcclusionData(
      imageUrl: card.front,
      activeIndex: card.clozeIndex ?? 0,
      regions: parseOcclusionField(''),
    );
  }

  String _frontHtml(FlashcardModel card) {
    if (_isTypeAnswer(card)) {
      return typeAnswerQuestionHtml(card.front);
    }
    if (_isCloze(card)) {
      return card.clozeText?.isNotEmpty == true ? card.clozeText! : card.displayFront;
    }
    return card.front;
  }

  String _backHtml(FlashcardModel card) => card.back;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Review'),
            if (_settings.showDueCountInStudy && _queue.isNotEmpty && _index < _queue.length)
              Text(
                'Card ${_index + 1} of ${_queue.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
        actions: [
          if (_index > 0 && _index <= _queue.length)
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Undo',
              onPressed: _submitting ? null : _undo,
            ),
          if (_index < _queue.length)
            PopupMenuButton<int>(
              icon: Icon(
                Icons.flag,
                color: flagColorFor(_queue[_index].flag) ?? Colors.black54,
              ),
              tooltip: 'Flag',
              onSelected: _setFlag,
              itemBuilder:
                  (ctx) => [
                    const PopupMenuItem(value: 0, child: Text('No flag')),
                    for (final e in flagColors.entries)
                      PopupMenuItem(
                        value: e.key,
                        child: Row(
                          children: [
                            Icon(Icons.flag, color: e.value, size: 18),
                            const SizedBox(width: 8),
                            Text('Flag ${e.key}'),
                          ],
                        ),
                      ),
                  ],
            ),
          if (_index < _queue.length && _queue[_index].noteId != null)
            IconButton(
              icon: Icon(
                _queue[_index].noteMarked ? Icons.star : Icons.star_border,
                color: _queue[_index].noteMarked ? AppColors.primaryYellow : null,
              ),
              tooltip: 'Mark note',
              onPressed: _toggleMarked,
            ),
          if (_index < _queue.length)
            IconButton(
              icon: Icon(
                _queue[_index].reviewState?.suspended == true
                    ? Icons.play_circle_outline
                    : Icons.pause_circle_outline,
              ),
              tooltip:
                  _queue[_index].reviewState?.suspended == true
                      ? 'Unsuspend'
                      : 'Suspend',
              onPressed: _toggleSuspend,
            ),
          if (_index < _queue.length)
            IconButton(
              icon: const Icon(Icons.visibility_off_outlined),
              tooltip: 'Bury card',
              onPressed: _buryCurrentCard,
            ),
          if (_index < _queue.length)
            IconButton(
              icon: const Icon(Icons.layers_outlined),
              tooltip: 'Bury siblings',
              onPressed: _burySiblings,
            ),
          if (_index < _queue.length)
            IconButton(
              icon: const Icon(Icons.layers_clear_outlined),
              tooltip: 'Unbury card',
              onPressed: _unburyCard,
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Review settings',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const DecksSettingsScreen()),
              );
              final settings = await ReviewSettingsStore.instance.load();
              if (mounted) {
                setState(() => _settings = settings);
                _applyWakelock();
              }
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading || _submitting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_index >= _queue.length) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _startedEmpty ? Icons.inbox_outlined : Icons.check_circle,
                size: 64,
                color: _startedEmpty ? Colors.grey : AppColors.greenCorrect,
              ),
              const SizedBox(height: 16),
              Text(
                _startedEmpty ? 'No cards due' : 'Session complete',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                _startedEmpty
                    ? 'Add notes to this deck or study another deck.'
                    : 'You reviewed ${_queue.length} card${_queue.length == 1 ? '' : 's'}.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      );
    }

    final card = _queue[_index];
    final typeAnswer = _isTypeAnswer(card);
    final imageOcclusion = _isImageOcclusion(card);
    final deckOpts = _deckOptionsFor(card);
    final previewsMap = intervalPreviewsForCard(card, deckOptions: deckOpts);
    final isLeech = (card.reviewState?.lapses ?? 0) >= _settings.leechThreshold;
    final textScale = _settings.cardTextScale;
    String? preview(String key) =>
        _settings.showIntervalPreviews ? previewsMap[key] : null;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Card ${_index + 1} of ${_queue.length}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const Spacer(),
              Text(
                _elapsedLabel(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              if (_isCloze(card) && card.clozeIndex != null) ...[
                const SizedBox(width: 8),
                Text(
                  '· Cloze c${card.clozeIndex}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
              if (imageOcclusion) ...[
                const SizedBox(width: 8),
                Text(
                  '· IO mask ${(card.clozeIndex ?? 0) + 1}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ],
          ),
          if (isLeech) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.redWrong.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Leech — this card has many lapses. Consider editing or suspending it.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
          const Spacer(),
          if (!imageOcclusion) _mediaWidget(card),
          GestureDetector(
            onDoubleTap:
                _settings.gesturesEnabled
                    ? () => _handleGestureAction(_settings.gestures.doubleTap)
                    : null,
            onPanStart:
                _settings.gesturesEnabled
                    ? (d) => _panStart = d.localPosition
                    : null,
            onPanEnd:
                _settings.gesturesEnabled
                    ? (d) => _onPanEnd(d, const Size(300, 300))
                    : null,
            onTap:
                typeAnswer || imageOcclusion
                    ? null
                    : (_settings.tapToReveal ? _revealCard : null),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(imageOcclusion ? 8 : 24),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryPurple.withValues(alpha: 0.2)),
              ),
              child:
                  imageOcclusion
                      ? ImageOcclusionReview(
                        data: _occlusionForCard(card),
                        revealed: _revealed,
                        textScale: textScale,
                        onTap:
                            _settings.tapToReveal && !_revealed
                                ? _revealCard
                                : null,
                      )
                      : BasicHtmlText(
                        html: _revealed ? _backHtml(card) : _frontHtml(card),
                        style: TextStyle(
                          fontSize: 22 * textScale,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                        textAlign: TextAlign.center,
                      ),
            ),
          ),
          if (typeAnswer && !_revealed) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _typeAnswerCtrl,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _checkTypeAnswer(card),
              decoration: InputDecoration(
                hintText: 'Type your answer…',
                filled: true,
                fillColor: const Color(0xFFF2F2F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => _checkTypeAnswer(card),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Check answer'),
            ),
          ],
          if (typeAnswer && _answerChecked) ...[
            const SizedBox(height: 8),
            Text(
              _answerCorrect == true ? 'Correct!' : 'Incorrect — compare with the answer above',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _answerCorrect == true ? AppColors.greenCorrect : AppColors.redWrong,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            typeAnswer
                ? (_revealed ? 'Rate how well you knew it' : 'Type your answer, then check')
                : imageOcclusion
                ? (_revealed ? 'Tap to hide · swipe to rate' : 'Tap the hidden region to reveal')
                : (_revealed ? 'Tap to hide answer' : 'Tap to reveal answer'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          if (_settings.gesturesEnabled && !typeAnswer)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Gestures: ← Again · → Good · ↑ Reveal',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
          if (!typeAnswer && _revealed && !imageOcclusion)
            TextButton(
              onPressed: () => setState(() => _revealed = false),
              child: const Text('Hide answer'),
            ),
          if (imageOcclusion && _revealed)
            TextButton(
              onPressed: () => setState(() => _revealed = false),
              child: const Text('Hide answer'),
            ),
          const Spacer(),
          if (_revealed) ...[
            _ratingButton(
              _settings.labelAgain,
              AppColors.redWrong,
              'again',
              preview('again'),
            ),
            const SizedBox(height: 8),
            if (_settings.showHardButton) ...[
              _ratingButton(
                _settings.labelHard,
                Colors.orange,
                'hard',
                preview('hard'),
              ),
              const SizedBox(height: 8),
            ],
            _ratingButton(
              _settings.labelGood,
              AppColors.primaryYellow,
              'good',
              preview('good'),
            ),
            const SizedBox(height: 8),
            _ratingButton(
              _settings.labelEasy,
              AppColors.greenCorrect,
              'easy',
              preview('easy'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _ratingButton(String label, Color color, String rating, String? interval) {
    final scale = _settings.reviewButtonScale;
    return Transform.scale(
      scale: scale,
      alignment: Alignment.center,
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: () => _answer(rating),
          style: FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.black,
            padding: EdgeInsets.symmetric(vertical: 14 * scale),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (_settings.showIntervalPreviews && interval != null) ...[
                const SizedBox(width: 8),
                Text(
                  interval,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
