import 'package:fluentdeck/ui_elements/app_toast.dart';
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';
import 'package:fluentdeck/services/admob_service.dart';
import 'package:fluentdeck/services/subscription_service.dart';
import 'package:fluentdeck/widgets/cached_strapi_image.dart';
import 'package:fluentdeck/data/flashcard_offline_store.dart';
import 'package:fluentdeck/models/card_style_preset.dart';
import 'package:fluentdeck/models/flashcard_model.dart';
import 'package:fluentdeck/services/flashcard_service.dart';
import 'package:fluentdeck/services/flashcard_sync_service.dart';
import 'package:fluentdeck/services/deck_scheduling_defaults.dart';
import 'package:fluentdeck/utils/sm2_preview.dart';
import 'package:fluentdeck/utils/card_browser_utils.dart';
import 'package:fluentdeck/utils/html_text_utils.dart';
import 'package:fluentdeck/models/occlusion_model.dart';
import 'package:fluentdeck/screens/learn_screen/decks_settings_screen.dart';
import 'package:fluentdeck/services/review_settings_store.dart';
import 'package:fluentdeck/models/speaking_preferences.dart';
import 'package:fluentdeck/services/note_service.dart';
import 'package:fluentdeck/services/speaking_preferences_service.dart';
import 'package:fluentdeck/ui_elements/app_skeletons.dart';
import 'package:fluentdeck/utils/review_queue_order.dart';
import 'package:fluentdeck/utils/type_answer_utils.dart';
import 'package:fluentdeck/widgets/image_occlusion_review.dart';
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

  /// Translation language from Settings → AI speaking ('none' hides the button).
  String _translationLanguage = 'none';
  final Map<int, String> _cardTranslations = {};
  int? _translationVisibleFor;
  int? _translatingCardId;
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
  Map<String, CardStylePreset> _themeByNoteTypeId = const {};
  final InterstitialAdManager _adManager = InterstitialAdManager();

  CardStylePreset? _themeForCard(FlashcardModel card) =>
      card.noteTypeId != null ? _themeByNoteTypeId[card.noteTypeId] : null;

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    WakelockPlus.disable();
    _audioPlayer.dispose();
    _typeAnswerCtrl.dispose();
    _adManager.dispose();
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
      return _deckOptionsById[card.deckId] ?? DeckSchedulingDefaults.deckOptions;
    }
    return DeckSchedulingDefaults.deckOptions;
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
      AppToast.showSnackBar(context, 
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
        child: CachedStrapiImage(
          url: url,
          height: 160,
          fit: BoxFit.cover,
          borderRadius: BorderRadius.circular(12),
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
    SpeakingPreferencesService.instance.load().then((prefs) {
      if (mounted) setState(() => _translationLanguage = prefs.translationLanguage);
    });
    _loadQueue();
    if (!SubscriptionService.instance.cachedStatus.isPremium) {
      _adManager.load();
    }
  }

  /// Free users see an interstitial after finishing a review session — a
  /// natural break point, not shown for an empty ("no cards due") session.
  Future<void> _maybeShowAdOnComplete() async {
    final status = await SubscriptionService.instance.fetchStatus();
    if (status.isPremium || !mounted) return;
    _adManager.show();
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
            d.id: d.deckOptions ?? DeckSchedulingDefaults.deckOptions,
        };
        try {
          final noteTypes = await FlashcardService.instance.fetchNoteTypesWithCache();
          _themeByNoteTypeId = {
            for (final t in noteTypes)
              t.id: CardStylePreset.byId(t.themeId),
          };
        } catch (_) {
          // Card theming is cosmetic — never block review over it.
        }
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
            d.id: d.deckOptions ?? DeckSchedulingDefaults.deckOptions,
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
          AppToast.showSnackBar(context, 
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
      } else if (!_startedEmpty) {
        unawaited(_maybeShowAdOnComplete());
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      AppToast.showSnackBar(context, 
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
      AppToast.showSnackBar(context, 
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
      AppToast.success(flag == 0 ? 'Flag removed' : 'Flagged $flag');
    } catch (e) {
      if (!mounted) return;
      AppToast.showSnackBar(context, 
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
          noteTypeId: card.noteTypeId,
          front: card.front,
          back: card.back,
          translation: card.translation,
          example: card.example,
          cardType: card.cardType,
          clozeText: card.clozeText,
          clozeIndex: card.clozeIndex,
          templateName: card.templateName,
          templateOrdinal: card.templateOrdinal,
          siblingCardCount: card.siblingCardCount,
          tags: card.tags,
          mediaUrl: card.mediaUrl,
          flag: card.flag,
          languageCode: card.languageCode,
          deckName: card.deckName,
          noteMarked: next,
          reviewState: card.reviewState,
          occlusionData: card.occlusionData,
        );
        _queue = list;
      });
      AppToast.success(next ? 'Note marked' : 'Note unmarked');
    } catch (e) {
      if (!mounted) return;
      AppToast.showSnackBar(context, 
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
      AppToast.showSnackBar(context, 
        const SnackBar(content: Text('Card unburied')),
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.showSnackBar(context, 
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
      final cardIndex = _index;
      _showUndoToast(
        'Card buried until tomorrow',
        () => _undoRemoval(cardIndex, () => FlashcardService.instance.unburyCard(card.id)),
      );
      await _advanceAfterAction();
    } catch (e) {
      if (!mounted) return;
      AppToast.showSnackBar(context, 
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
      if (!suspended) {
        final cardIndex = _index;
        _showUndoToast(
          'Card suspended',
          () => _undoRemoval(cardIndex, () => FlashcardService.instance.unsuspendCard(card.id)),
        );
        await _advanceAfterAction();
        return;
      }
      AppToast.success('Card unsuspended');
      setState(() {
        final list = List<FlashcardModel>.from(_queue);
        list[_index] = updated;
        _queue = list;
      });
    } catch (e) {
      if (!mounted) return;
      AppToast.showSnackBar(context, 
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _showUndoToast(String message, Future<void> Function() onUndo) {
    AppToast.showSnackBar(
      context,
      SnackBar(
        content: Text(message),
        action: SnackBarAction(label: 'Undo', onPressed: () => onUndo()),
      ),
    );
  }

  /// Reverses a bury/suspend: restores the card on the server and shows it again.
  Future<void> _undoRemoval(
    int cardIndex,
    Future<FlashcardModel?> Function() restore,
  ) async {
    try {
      final restored = await restore();
      if (!mounted || cardIndex >= _queue.length) return;
      setState(() {
        if (restored != null) {
          final list = List<FlashcardModel>.from(_queue);
          list[cardIndex] = restored;
          _queue = list;
        }
        _index = cardIndex;
        _resetCardState();
      });
      _cardShownAt = DateTime.now();
      _startElapsedTimer();
      AppToast.success('Card restored');
    } catch (e) {
      if (!mounted) return;
      AppToast.error('Could not undo: $e');
    }
  }

  Future<void> _burySiblings() async {
    if (_index >= _queue.length) return;
    final card = _queue[_index];
    try {
      final buried = await FlashcardService.instance.burySiblings(card.id);
      if (!mounted) return;
      AppToast.showSnackBar(context, 
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
      AppToast.showSnackBar(context, 
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

  String _backHtml(FlashcardModel card) => _answerParts(card).definition;

  /// Splits the answer into definition + example. Older cards stored the
  /// example inside Back as "…\n\nExample: …", so fall back to parsing that.
  ({String definition, String example}) _answerParts(FlashcardModel card) {
    if (card.example.trim().isNotEmpty) {
      return (definition: card.back, example: card.example.trim());
    }
    final match = RegExp(r'(?:^|\n\s*\n)Example:\s*(.+)$', dotAll: true).firstMatch(card.back);
    if (match == null) return (definition: card.back, example: '');
    return (
      definition: card.back.substring(0, match.start).trim(),
      example: match.group(1)!.trim(),
    );
  }

  Future<void> _toggleTranslation(FlashcardModel card) async {
    if (_translationVisibleFor == card.id) {
      setState(() => _translationVisibleFor = null);
      return;
    }
    if (_savedTranslation(card) == null) {
      setState(() => _translatingCardId = card.id);
      final translated = await NoteService.instance.translateWithGlossary(
        word: stripHtml(_frontHtml(card)),
        text: [
          stripHtml(_backHtml(card)),
          _answerParts(card).example,
        ].where((part) => part.trim().isNotEmpty).join('\n\n'),
        targetLanguage: _translationLanguage,
      );
      if (!mounted) return;
      setState(() => _translatingCardId = null);
      if (translated == null) {
        AppToast.showSnackBar(context, 
          const SnackBar(content: Text("Couldn't translate this card. Try again.")),
        );
        return;
      }
      _cardTranslations[card.id] = translated;
      // Keep it so the next review of this card shows it without re-translating.
      FlashcardService.instance.saveCardTranslation(card.id, translated);
    }
    setState(() => _translationVisibleFor = card.id);
  }

  /// Translation saved on the card (from its note or an earlier review), or
  /// one generated earlier in this session.
  String? _savedTranslation(FlashcardModel card) {
    final local = _cardTranslations[card.id];
    if (local != null) return local;
    final saved = card.translation.trim();
    return saved.isEmpty ? null : saved;
  }

  bool _showsTranslationPanel(FlashcardModel card) =>
      _translationLanguage != 'none' || _savedTranslation(card) != null;

  /// "Translate to …" button under the revealed answer, with the result below.
  Widget _translationPanel(FlashcardModel card) {
    final visible = _translationVisibleFor == card.id;
    final loading = _translatingCardId == card.id;
    final translation = _savedTranslation(card);
    final languageName =
        SpeakingPreferences.translationLanguageOptions[_translationLanguage] ??
        _translationLanguage;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 6),
        TextButton.icon(
          onPressed: loading ? null : () => _toggleTranslation(card),
          icon:
              loading
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.translate_rounded, size: 18),
          label: Text(
            visible
                ? 'Hide translation'
                : translation != null
                ? 'Show translation'
                : 'Translate to $languageName',
          ),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.brandPrimary,
            visualDensity: VisualDensity.compact,
          ),
        ),
        if (visible && translation != null) ...[
          const SizedBox(height: 10),
          _translationBox(translation),
        ],
      ],
    );
  }

  /// Translation text, then a "word — meaning" list for the glossary lines
  /// ("• term — meaning") saved with it.
  Widget _translationBox(String stored) {
    final main = <String>[];
    final glossary = <(String, String)>[];
    (String, String)? word;
    for (final line in stored.split('\n')) {
      final trimmed = line.trim();
      final sep = trimmed.indexOf(' — ');
      if (trimmed.startsWith('» ') && sep > 2 && word == null) {
        word = (trimmed.substring(2, sep).trim(), trimmed.substring(sep + 3).trim());
      } else if (trimmed.startsWith('• ') && sep > 2) {
        glossary.add((trimmed.substring(2, sep).trim(), trimmed.substring(sep + 3).trim()));
      } else {
        main.add(line);
      }
    }
    final mainText = main.join('\n').trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.15)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (word != null) ...[
            Text(
              word.$1,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppPageColors.subtitleOf(context)),
            ),
            const SizedBox(height: 2),
            Text(
              word.$2,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.brandPrimary,
                height: 1.3,
              ),
            ),
            if (mainText.isNotEmpty) const SizedBox(height: 10),
          ],
          if (mainText.isNotEmpty)
            Text(
              mainText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
          if (glossary.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Divider(
                height: 1,
                color: AppColors.brandPrimary.withValues(alpha: 0.15),
              ),
            ),
            for (final (term, meaning) in glossary)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: term,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.brandPrimary,
                        ),
                      ),
                      TextSpan(
                        text: ' — $meaning',
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ),
          ],
        ],
      ),
    );
  }

  bool get _isWide => MediaQuery.sizeOf(context).width >= 600;

  bool get _hasCardOnScreen => _queue.isNotEmpty && _index < _queue.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPageColors.pageBgOf(context),
      appBar: AppBar(
        // Same dark brand bar as the main app header; white text and icons.
        backgroundColor: AppColors.brandPrimaryDeep,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        elevation: 0,
        centerTitle: false,
        // Card timer, centred on the screen's top edge.
        flexibleSpace:
            _hasCardOnScreen && !_loading
                ? SafeArea(
                  child: Center(
                    child: Text(
                      _elapsedLabel(),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                )
                : null,
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
                  color: Colors.white.withValues(alpha: 0.75),
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
          // Tablet / web: card tools sit in the bar, left of the gear.
          if (_isWide && _hasCardOnScreen && !_loading) ..._cardTools(),
          // Phones: one "more" button opening labelled card actions.
          if (!_isWide && _hasCardOnScreen && !_loading)
            IconButton(
              icon: Badge(
                smallSize: 8,
                backgroundColor: const Color(0xFFFFC857),
                isLabelVisible: _hasCardState(_queue[_index]),
                child: const Icon(Icons.more_horiz_rounded),
              ),
              tooltip: 'Card actions',
              onPressed: _showCardActionsSheet,
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

  /// Flag, mark, suspend and bury actions for the card on screen.
  List<Widget> _cardTools() {
    return [
      PopupMenuButton<int>(
        icon: Icon(
          Icons.flag,
          color: flagColorFor(_queue[_index].flag) ?? Colors.white,
        ),
        tooltip: 'Flag',
        onSelected: _setFlag,
        itemBuilder: (ctx) => [
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
      if (_queue[_index].noteId != null)
        IconButton(
          icon: Icon(
            _queue[_index].noteMarked ? Icons.star : Icons.star_border,
            color: _queue[_index].noteMarked ? AppColors.primaryYellow : null,
          ),
          tooltip: 'Mark note',
          onPressed: _toggleMarked,
        ),
      IconButton(
        icon: Icon(
          _queue[_index].reviewState?.suspended == true
              ? Icons.play_circle_outline
              : Icons.pause_circle_outline,
        ),
        tooltip: _queue[_index].reviewState?.suspended == true
            ? 'Unsuspend'
            : 'Suspend',
        onPressed: _toggleSuspend,
      ),
      IconButton(
        icon: const Icon(Icons.visibility_off_outlined),
        tooltip: 'Bury card',
        onPressed: _buryCurrentCard,
      ),
      IconButton(
        icon: const Icon(Icons.layers_outlined),
        tooltip: 'Bury siblings',
        onPressed: _burySiblings,
      ),
      IconButton(
        icon: const Icon(Icons.layers_clear_outlined),
        tooltip: 'Unbury card',
        onPressed: _unburyCard,
      ),
    ];
  }
  bool _hasCardState(FlashcardModel card) => card.flag != 0 || card.noteMarked;

  /// Flag / marked chips above the card; tapping one changes it.
  Widget _cardStateChips(FlashcardModel card) {
    if (!_hasCardState(card)) return const SizedBox.shrink();
    final flagColor = flagColorFor(card.flag) ?? AppColors.redWrong;
    Widget chip({
      required IconData icon,
      required String label,
      required Color color,
      required String tooltip,
      required VoidCallback onTap,
    }) {
      return Tooltip(
        message: tooltip,
        child: Material(
          color: color.withValues(alpha: 0.12),
          shape: StadiumBorder(side: BorderSide(color: color.withValues(alpha: 0.45))),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 15, color: color),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 6,
        children: [
          if (card.flag != 0)
            chip(
              icon: Icons.flag_rounded,
              label: 'Flag ${card.flag}',
              color: flagColor,
              tooltip: 'Change or remove flag',
              onTap: () => _showFlagSheet(card.flag),
            ),
          if (card.noteMarked)
            chip(
              icon: Icons.star_rounded,
              label: 'Marked',
              color: const Color(0xFFB7791F),
              tooltip: 'Unmark note',
              onTap: _toggleMarked,
            ),
        ],
      ),
    );
  }

  /// Phones: labelled card actions in a bottom sheet (opened from ⋯ in the
  /// app bar). Tablet / web show the same actions as icons in the bar.
  Future<void> _showCardActionsSheet() async {
    if (!_hasCardOnScreen) return;
    final card = _queue[_index];
    final suspended = card.reviewState?.suspended == true;
    final buried = card.reviewState?.buriedUntil?.isAfter(DateTime.now()) == true;
    final flagColor = flagColorFor(card.flag);
    const onMark = Icon(Icons.check_circle_rounded, color: AppColors.brandPrimary, size: 20);

    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppSheetHandle(),
              const AppSheetHeader(
                title: 'Card actions',
                subtitle: 'Apply to the card you are reviewing',
                icon: Icons.more_horiz_rounded,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    AppSheetActionTile(
                      icon: Icons.flag_outlined,
                      iconColor: flagColor,
                      title: 'Flag card',
                      subtitle: card.flag == 0
                          ? 'Colour-code it to find later in the browser'
                          : 'Flag ${card.flag} is on · tap to change or clear',
                      trailing: card.flag != 0 ? onMark : null,
                      onTap: () => Navigator.pop(ctx, 'flag'),
                    ),
                    if (card.noteId != null)
                      AppSheetActionTile(
                        icon: card.noteMarked ? Icons.star_rounded : Icons.star_border_rounded,
                        iconColor: card.noteMarked ? AppColors.primaryYellow : null,
                        title: card.noteMarked ? 'Unmark note' : 'Mark note',
                        subtitle: card.noteMarked
                            ? 'Marked · tap to remove the star'
                            : 'Star the note so you can filter for it later',
                        trailing: card.noteMarked ? onMark : null,
                        onTap: () => Navigator.pop(ctx, 'mark'),
                      ),
                    AppSheetActionTile(
                      icon: suspended ? Icons.play_circle_outline : Icons.pause_circle_outline,
                      title: suspended ? 'Unsuspend card' : 'Suspend card',
                      subtitle: suspended
                          ? 'Put it back into your reviews'
                          : 'Stop showing it in reviews until you unsuspend it',
                      onTap: () => Navigator.pop(ctx, 'suspend'),
                    ),
                    AppSheetActionTile(
                      icon: Icons.visibility_off_outlined,
                      title: 'Bury card',
                      subtitle: 'Hide it until tomorrow',
                      onTap: () => Navigator.pop(ctx, 'bury'),
                    ),
                    AppSheetActionTile(
                      icon: Icons.layers_outlined,
                      title: 'Bury siblings',
                      subtitle: 'Hide the other cards of this note until tomorrow',
                      onTap: () => Navigator.pop(ctx, 'bury-siblings'),
                    ),
                    if (buried)
                      AppSheetActionTile(
                        icon: Icons.layers_clear_outlined,
                        title: 'Unbury card',
                      subtitle: 'Bring a buried card back today',
                      onTap: () => Navigator.pop(ctx, 'unbury'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || action == null) return;

    switch (action) {
      case 'flag':
        await _showFlagSheet(card.flag);
      case 'mark':
        await _toggleMarked();
      case 'suspend':
        await _toggleSuspend();
      case 'bury':
        await _buryCurrentCard();
      case 'bury-siblings':
        await _burySiblings();
      case 'unbury':
        await _unburyCard();
    }
  }

  Future<void> _showFlagSheet(int current) async {
    final flag = await showModalBottomSheet<int>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppSheetHandle(),
            const AppSheetHeader(
              title: 'Flag card',
              icon: Icons.flag_outlined,
            ),
            ListTile(
              leading: const Icon(Icons.outlined_flag_rounded),
              title: const Text('No flag'),
              trailing: current == 0 ? const Icon(Icons.check_rounded) : null,
              onTap: () => Navigator.pop(ctx, 0),
            ),
            for (final e in flagColors.entries)
              ListTile(
                leading: Icon(Icons.flag_rounded, color: e.value),
                title: Text('Flag ${e.key}'),
                trailing: current == e.key ? const Icon(Icons.check_rounded) : null,
                onTap: () => Navigator.pop(ctx, e.key),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (flag != null && mounted) await _setFlag(flag);
  }

  Widget _buildBody() {
    if (_loading) {
      return const AppListSkeleton(count: 1, itemHeight: 420);
    }
    if (_submitting) {
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
                color: _startedEmpty
                    ? AppPageColors.subtitleOf(context)
                    : AppColors.greenCorrect,
              ),
              const SizedBox(height: 16),
              Text(
                _startedEmpty ? 'No cards due' : 'Session complete',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _startedEmpty
                    ? 'Add notes to this deck or study another deck.'
                    : 'You reviewed ${_queue.length} card${_queue.length == 1 ? '' : 's'}.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppPageColors.subtitleOf(context)),
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
    final cardTheme = _themeForCard(card);
    String? preview(String key) =>
        _settings.showIntervalPreviews ? previewsMap[key] : null;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (_isCloze(card) && card.clozeIndex != null)
                Text(
                  'Cloze c${card.clozeIndex}',
                  style: TextStyle(fontSize: 12, color: AppPageColors.subtitleOf(context)),
                ),
              if (imageOcclusion)
                Text(
                  'IO mask ${(card.clozeIndex ?? 0) + 1}',
                  style: TextStyle(fontSize: 12, color: AppPageColors.subtitleOf(context)),
                ),
              const Spacer(),
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
          // Card + translation scroll when they don't fit; the rating buttons
          // stay pinned below so long answers never overflow them.
          Expanded(
            child: LayoutBuilder(
              builder:
                  (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                      _cardStateChips(card),
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
                            color: cardTheme?.backgroundColor ?? AppPageColors.fieldBgOf(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: card.flag != 0
                                  ? (flagColorFor(card.flag) ?? AppColors.redWrong)
                                  : (cardTheme?.accentColor ?? AppColors.brandPrimary)
                                      .withValues(alpha: 0.2),
                              width: card.flag != 0 ? 2 : 1,
                            ),
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
                                  : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      BasicHtmlText(
                                        html: _revealed ? _backHtml(card) : _frontHtml(card),
                                        style: TextStyle(
                                          fontSize: (cardTheme?.fontSize ?? 22) * textScale,
                                          fontWeight: cardTheme?.fontWeight ?? FontWeight.w600,
                                          color: cardTheme?.textColor ??
                                              Theme.of(context).textTheme.bodyLarge?.color,
                                          height: 1.35,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      if (_revealed && _answerParts(card).example.isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        Text(
                                          'e.g. ${_answerParts(card).example}',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 15 * textScale,
                                            fontStyle: FontStyle.italic,
                                            color: (cardTheme?.textColor ??
                                                    Theme.of(context).textTheme.bodyLarge?.color ??
                                                    Colors.black87)
                                                .withValues(alpha: 0.6),
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                        ),
                      ),
                      if (_revealed && !imageOcclusion && _showsTranslationPanel(card))
                        _translationPanel(card),
                      if (typeAnswer && !_revealed) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _typeAnswerCtrl,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _checkTypeAnswer(card),
                          decoration: InputDecoration(
                            hintText: 'Type your answer…',
                            filled: true,
                            fillColor: AppPageColors.fieldBgOf(context),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppPageColors.subtleBorderOf(context)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: () => _checkTypeAnswer(card),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.brandPrimary,
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
                        style: TextStyle(fontSize: 13, color: AppPageColors.subtitleOf(context)),
                      ),
                      if (_settings.gesturesEnabled && !typeAnswer)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Gestures: ← Again · → Good · ↑ Reveal',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, color: AppPageColors.subtitleOf(context)),
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
                        ],
                      ),
                    ),
                  ),
            ),
          ),
          if (_revealed) ...[
            const SizedBox(height: 12),
            _ratingButton(
              _settings.labelAgain,
              AppColors.redWrong,
              'again',
              preview('again'),
              icon: Icons.replay_rounded,
              lightText: true,
            ),
            const SizedBox(height: 8),
            if (_settings.showHardButton) ...[
              _ratingButton(
                _settings.labelHard,
                AppColors.orangeHard,
                'hard',
                preview('hard'),
                icon: Icons.trending_down_rounded,
              ),
              const SizedBox(height: 8),
            ],
            _ratingButton(
              _settings.labelGood,
              AppColors.primaryYellow,
              'good',
              preview('good'),
              icon: Icons.check_rounded,
            ),
            const SizedBox(height: 8),
            _ratingButton(
              _settings.labelEasy,
              AppColors.greenCorrect,
              'easy',
              preview('easy'),
              icon: Icons.bolt_rounded,
            ),
          ],
        ],
      ),
    );
  }

  Widget _ratingButton(
    String label,
    Color color,
    String rating,
    String? interval, {
    IconData? icon,
    bool lightText = false,
  }) {
    final scale = _settings.reviewButtonScale;
    final textColor = lightText ? Colors.white : Colors.black87;
    return Transform.scale(
      scale: scale,
      alignment: Alignment.center,
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: () => _answer(rating),
          style: FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: textColor,
            padding: EdgeInsets.symmetric(vertical: 14 * scale),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: textColor),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(fontWeight: FontWeight.w700, color: textColor),
              ),
              if (_settings.showIntervalPreviews && interval != null) ...[
                const SizedBox(width: 8),
                Text(
                  interval,
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor.withValues(alpha: 0.75),
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
