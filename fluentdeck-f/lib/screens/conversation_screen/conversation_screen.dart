import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/models/speaking_preferences.dart';
import 'package:fluentdeck/models/conversation_turn_model.dart';
import 'package:fluentdeck/models/grammar_correction.dart';
import 'package:fluentdeck/models/speaking_session_context.dart';
import 'package:fluentdeck/services/conversation_limit_service.dart';
import 'package:fluentdeck/services/conversation_service.dart';
import 'package:fluentdeck/services/note_service.dart';
import 'package:fluentdeck/services/speaking_preferences_service.dart';
import 'package:fluentdeck/services/speaking_scores_service.dart';
import 'package:fluentdeck/services/speaking_session_service.dart';
import 'package:fluentdeck/utils/correction_text_utils.dart';
import 'package:fluentdeck/utils/vocabulary_highlight_utils.dart';
import 'package:fluentdeck/widgets/ai_daily_usage_bar.dart';

import 'conversation_chat_settings_sheet.dart';
import 'save_word_meaning_sheet.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key, this.embedInShell = false});

  final bool embedInShell;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final ConversationService _service = ConversationService.instance;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  ConversationUsageStatus? _usage;
  String _translationLanguage = 'none';

  bool get _hasTranslationHelper =>
      _translationLanguage != 'none' &&
      SpeakingPreferences.translationLanguageOptions.containsKey(
        _translationLanguage,
      );

  String get _translationHelperLabel =>
      SpeakingPreferences.translationLanguageOptions[_translationLanguage] ??
      _translationLanguage;

  @override
  void initState() {
    super.initState();
    _service.onStateChanged = _onServiceUpdate;
    unawaited(_loadSpeakingPrefs());
    unawaited(_service.refreshSpeakingSettings());
    _loadUsage();
  }

  Future<void> _loadSpeakingPrefs() async {
    final prefs = await SpeakingPreferencesService.instance.load();
    if (!mounted) return;
    setState(() => _translationLanguage = prefs.translationLanguage);
  }

  Future<String?> _translateTurn(int turnIndex, String text) async {
    final translation = await _service.fetchMessageTranslation(text);
    if (translation != null && translation.isNotEmpty) {
      _service.setTurnTranslation(turnIndex, translation);
    }
    return translation;
  }

  Future<void> _loadUsage() async {
    final usage = await ConversationLimitService.instance.getStatus(
      forceRefresh: true,
    );
    if (!mounted) return;
    setState(() => _usage = usage);
  }

  @override
  void dispose() {
    if (_service.isChatActive) {
      unawaited(_service.leaveChat());
    }
    if (_service.onStateChanged == _onServiceUpdate) {
      _service.onStateChanged = null;
    }
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onServiceUpdate() {
    if (!mounted) return;
    setState(() {});
    unawaited(_loadSpeakingPrefs());
    unawaited(_loadUsage());
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _onMicTap() async {
    if (_service.isProcessing) return;
    if (_service.isRecording) {
      await _service.stopRecordingAndSend();
      return;
    }
    await _service.startRecording();
  }

  Future<void> _onSendText() async {
    final text = _textController.text;
    _textController.clear();
    await _service.sendTextMessage(text);
  }

  Future<void> _saveChatSelection(String selected, String sourceSentence) async {
    final trimmed = selected.trim();
    if (trimmed.isEmpty) return;

    final sheetResult = await showSaveWordMeaningSheet(
      context: context,
      selectedText: trimmed,
      sourceSentence: sourceSentence,
    );
    if (sheetResult == null || !mounted) return;

    final result = await NoteService.instance.saveChatHighlight(
      selectedText: sheetResult.phrase,
      sourceSentence: sourceSentence,
      meaning: sheetResult.meaning,
      exampleSentence: sheetResult.example,
    );

    if (!mounted) return;
    if (result.ok) {
      final msg =
          result.flashcardCreated
              ? 'Saved to notes and From speaking deck'
              : 'Saved to notes';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Could not save')),
      );
    }
  }

  String _sessionBannerLabel() {
    final ctx = _service.sessionContext;
    if (ctx.isFreeChat) return '';
    switch (ctx.mode) {
      case SpeakingMode.rolePlay:
        return 'Role-Play: ${ctx.title}';
      case SpeakingMode.topic:
        return 'Topic: ${ctx.title}';
      case SpeakingMode.game:
        return 'Game: ${ctx.title}';
      case SpeakingMode.lesson:
        return 'Lesson: ${ctx.title}';
      case SpeakingMode.chat:
        return '';
    }
  }

  String? _compactStatusLine() {
    final parts = <String>[];
    final sessionLabel = _sessionBannerLabel();
    if (sessionLabel.isNotEmpty) {
      parts.add(sessionLabel);
    } else if (_service.trainingSession.isActive) {
      parts.add(
        'Training: ${_service.trainingSession.sourceLabel} '
        '(${_service.trainingSession.words.length} words)',
      );
    }
    if (_service.autoConversationEnabled) {
      parts.add('Hands-free on');
    }
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  Future<void> _endSession() async {
    final result = await _service.evaluateCurrentSession();
    if (!mounted) return;
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not evaluate this session yet.')),
      );
      return;
    }

    final ctx = _service.sessionContext;
    SpeakingSessionCompleteResult? saved;
    try {
      saved = await SpeakingSessionService.instance.completeSession(
        context: ctx,
        score: result.score,
        feedback: result.feedback,
        summary: result.summary,
        turnCount: _service.turns.length,
        startedAt:
            _service.sessionStartedAt ??
            _service.turns.firstOrNull?.timestamp ??
            DateTime.now(),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Score saved locally. Sync failed: $e')),
      );
      if (ctx.referenceKey != null && ctx.referenceKey!.isNotEmpty) {
        await SpeakingScoresService.instance.saveScore(
          referenceKey: ctx.referenceKey!,
          score: result.score,
          title: ctx.title,
          mode: ctx.mode,
        );
      }
    }

    if (!mounted) return;
    final streakNote =
        saved != null && saved.streakDays > 0
            ? '\n\n${saved.streakDays} day speaking streak!'
            : '';
    await showDialog<void>(
      context: context,
      builder:
          (dialogCtx) => AlertDialog(
            title: Text('Score: ${result.score} / 10'),
            content: Text('${result.feedback}$streakNote'),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Done'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusLine = _compactStatusLine();
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar:
          widget.embedInShell
              ? null
              : AppBar(
                title: const Text('English Practice'),
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
                elevation: 0,
                actions: [
                  IconButton(
                    onPressed: () => showConversationChatSettingsSheet(context),
                    icon: const Icon(Icons.tune_rounded),
                    tooltip: 'Chat settings',
                  ),
                ],
              ),
      body: Column(
        children: [
          if (_usage != null && _usage!.hasMeter) AiDailyUsageBar(usage: _usage!),
          if (statusLine != null || _service.canEvaluateSession)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              color: AppColors.primaryPurple.withValues(alpha: 0.06),
              child: Row(
                children: [
                  if (statusLine != null)
                    Expanded(
                      child: Text(
                        statusLine,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  else
                    const Spacer(),
                  if (_service.canEvaluateSession)
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed:
                          _service.isEvaluatingSession ? null : _endSession,
                      child:
                          _service.isEvaluatingSession
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                              : const Text('End & score'),
                    ),
                ],
              ),
            ),
          if (_service.errorMessage != null)
            MaterialBanner(
              content: Text(_service.errorMessage!),
              backgroundColor: AppColors.redWrong.withValues(alpha: 0.12),
              actions: [
                TextButton(
                  onPressed: () {
                    _service.errorMessage = null;
                    _onServiceUpdate();
                  },
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _service.turns.length,
              itemBuilder: (context, index) {
                final turn = _service.turns[index];
                final isPlayingAi =
                    _service.isPlayingTts && index == _service.ttsTurnIndex;
                return _TurnBubble(
                  turnIndex: index,
                  turn: turn,
                  translationLanguage:
                      _hasTranslationHelper ? _translationLanguage : null,
                  translationHelperLabel:
                      _hasTranslationHelper ? _translationHelperLabel : null,
                  onTranslateTurn: _hasTranslationHelper ? _translateTurn : null,
                  vocabularyHighlights:
                      turn.isUser
                          ? const []
                          : _service.sessionContext.suggestedVocabulary,
                  onPlayAi:
                      turn.isUser
                          ? null
                          : () => _service.playAiText(turn.text, turnIndex: index),
                  isPlayingAi: isPlayingAi,
                  onSaveSelection: _saveChatSelection,
                );
              },
            ),
          ),
          _ProcessingIndicator(
            isProcessing: _service.isProcessing,
            stage: _service.stage,
            onCancel:
                (_service.isProcessing || _service.isRecording)
                    ? () => _service.cancelActiveOperation()
                    : null,
          ),
          _InputBar(
            isRecording: _service.isRecording,
            isProcessing: _service.isProcessing,
            recordingDurationLabel:
                _service.isRecording ? _service.recordingDurationLabel : null,
            textController: _textController,
            onMicTap: _onMicTap,
            onSendText: _onSendText,
            typeMessagesEnabled: _service.typeMessagesEnabled,
            onCancel:
                (_service.isProcessing || _service.isRecording)
                    ? () => _service.cancelActiveOperation()
                    : null,
          ),
        ],
      ),
    );
  }
}

class _TurnBubble extends StatefulWidget {
  const _TurnBubble({
    required this.turnIndex,
    required this.turn,
    this.translationLanguage,
    this.translationHelperLabel,
    this.onTranslateTurn,
    this.vocabularyHighlights = const [],
    this.onPlayAi,
    this.isPlayingAi = false,
    this.onSaveSelection,
  });

  final int turnIndex;
  final ConversationTurnModel turn;
  final String? translationLanguage;
  final String? translationHelperLabel;
  final Future<String?> Function(int turnIndex, String text)? onTranslateTurn;
  final List<String> vocabularyHighlights;
  final VoidCallback? onPlayAi;
  final bool isPlayingAi;
  final void Function(String selected, String sourceSentence)? onSaveSelection;

  @override
  State<_TurnBubble> createState() => _TurnBubbleState();
}

class _TurnBubbleState extends State<_TurnBubble> {
  String? _selectedText;
  bool _showTranslation = false;
  bool _loadingTranslation = false;

  ConversationTurnModel get turn => widget.turn;
  bool get isUser => turn.isUser;

  bool get _hasTranslateAction =>
      !isUser &&
      widget.translationLanguage != null &&
      widget.translationLanguage != 'none' &&
      widget.onTranslateTurn != null;

  Future<void> _onTranslateTap() async {
    if (_showTranslation) {
      setState(() => _showTranslation = false);
      return;
    }

    final existing = turn.translation?.trim();
    if (existing != null && existing.isNotEmpty) {
      setState(() => _showTranslation = true);
      return;
    }

    final onTranslate = widget.onTranslateTurn;
    if (onTranslate == null) return;

    setState(() => _loadingTranslation = true);
    final fetched = await onTranslate(widget.turnIndex, turn.text);
    if (!mounted) return;

    setState(() {
      _loadingTranslation = false;
      _showTranslation = fetched != null && fetched.isNotEmpty;
    });
  }

  void _onSelectionChanged(
    TextSelection selection,
    SelectionChangedCause? cause,
  ) {
    if (!selection.isValid || selection.isCollapsed) {
      if (_selectedText != null) {
        setState(() => _selectedText = null);
      }
      return;
    }

    final text = turn.text;
    final end = selection.end.clamp(0, text.length);
    final start = selection.start.clamp(0, end);
    final selected = text.substring(start, end).trim();
    final next = selected.isEmpty ? null : selected;
    if (next != _selectedText) {
      setState(() => _selectedText = next);
    }
  }

  void _openSaveSheet(String phrase) {
    widget.onSaveSelection?.call(phrase, turn.text);
    setState(() => _selectedText = null);
  }

  @override
  Widget build(BuildContext context) {
    final cardCorrections =
        turn.corrections.where((correction) => correction.showsCard).toList();
    final showInstantOkBadge =
        isUser &&
        turn.corrections.isEmpty &&
        turn.text.trim().isNotEmpty;
    final translation =
        !isUser && _showTranslation ? turn.translation?.trim() : null;
    final actionIconCount =
        (_hasTranslateAction ? 1 : 0) +
        (widget.onSaveSelection != null ? 1 : 0);
    final actionPadding = actionIconCount * 28.0;
    final baseStyle = TextStyle(
      color: isUser ? Colors.white : Colors.black87,
      fontSize: 15,
      height: 1.35,
    );
    final messageSpans =
        isUser && turn.corrections.any((c) => c.showsInline)
            ? buildCorrectedMessageSpans(
              text: turn.text,
              corrections: turn.corrections,
              baseStyle: baseStyle,
              errorColor:
                  isUser ? const Color(0xFFFF8A80) : AppColors.redWrong,
              correctionColor:
                  isUser ? const Color(0xFF69F0AE) : AppColors.greenCorrect,
            )
            : !isUser && widget.vocabularyHighlights.isNotEmpty
            ? buildVocabularyHighlightSpans(
              text: turn.text,
              vocabulary: widget.vocabularyHighlights,
              baseStyle: baseStyle,
            )
            : [TextSpan(text: turn.text, style: baseStyle)];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isUser)
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primaryPurple,
                  child: Icon(Icons.school, size: 16, color: Colors.white),
                ),
              if (!isUser) const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.primaryPurple : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          right: actionPadding,
                        ),
                        child: SelectableText.rich(
                          TextSpan(children: messageSpans),
                          style: baseStyle,
                          onSelectionChanged: _onSelectionChanged,
                          contextMenuBuilder: (context, editableTextState) {
                            final value = editableTextState.textEditingValue;
                            final selection = value.selection;
                            final selectedText =
                                selection.isValid && !selection.isCollapsed
                                    ? value.text
                                        .substring(selection.start, selection.end)
                                        .trim()
                                    : '';

                            final items = <ContextMenuButtonItem>[
                              ...editableTextState.contextMenuButtonItems,
                            ];
                            if (selectedText.isNotEmpty &&
                                widget.onSaveSelection != null) {
                              items.add(
                                ContextMenuButtonItem(
                                  onPressed: () {
                                    ContextMenuController.removeAny();
                                    _openSaveSheet(selectedText);
                                  },
                                  label: 'Save to deck',
                                ),
                              );
                            }

                            return AdaptiveTextSelectionToolbar.buttonItems(
                              anchors: editableTextState.contextMenuAnchors,
                              buttonItems: items,
                            );
                          },
                        ),
                      ),
                      if (_hasTranslateAction || widget.onSaveSelection != null)
                        Positioned(
                          top: -6,
                          right: -6,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_hasTranslateAction)
                                Material(
                                  color: Colors.transparent,
                                  child: IconButton(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    tooltip:
                                        _showTranslation
                                            ? 'Hide ${widget.translationHelperLabel ?? 'translation'}'
                                            : 'Show ${widget.translationHelperLabel ?? 'translation'}',
                                    icon:
                                        _loadingTranslation
                                            ? SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color:
                                                    isUser
                                                        ? Colors.white
                                                            .withValues(alpha: 0.9)
                                                        : AppColors.primaryPurple,
                                              ),
                                            )
                                            : Icon(
                                              _showTranslation
                                                  ? Icons.translate
                                                  : Icons.translate_outlined,
                                              size: 20,
                                              color:
                                                  isUser
                                                      ? Colors.white.withValues(
                                                        alpha: 0.9,
                                                      )
                                                      : AppColors.primaryPurple,
                                            ),
                                    onPressed:
                                        _loadingTranslation
                                            ? null
                                            : _onTranslateTap,
                                  ),
                                ),
                              if (widget.onSaveSelection != null)
                                Material(
                                  color: Colors.transparent,
                                  child: IconButton(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                    tooltip: 'Save to deck',
                                    icon: Icon(
                                      Icons.bookmark_add_outlined,
                                      size: 20,
                                      color:
                                          isUser
                                              ? Colors.white.withValues(alpha: 0.9)
                                              : AppColors.primaryPurple,
                                    ),
                                    onPressed: () => _openSaveSheet(turn.text.trim()),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (showInstantOkBadge) ...[
                const SizedBox(width: 6),
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.greenCorrect.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.greenCorrect, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: AppColors.greenCorrect,
                  ),
                ),
              ],
            ],
          ),
          if (_selectedText != null && widget.onSaveSelection != null)
            Padding(
              padding: EdgeInsets.only(
                left: isUser ? 0 : 44,
                top: 6,
                right: isUser ? 0 : 8,
              ),
              child: Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: () => _openSaveSheet(_selectedText!),
                  icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                  label: Text('Save "$_selectedText"'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple.withValues(
                      alpha: 0.12,
                    ),
                    foregroundColor: AppColors.primaryPurple,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
            ),
          if (translation != null && translation.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                left: isUser ? 0 : 44,
                top: 4,
                right: isUser ? 0 : 8,
              ),
              child: Align(
                alignment:
                    isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Text(
                  translation,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          if (!isUser && widget.onPlayAi != null)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 4),
              child: TextButton.icon(
                onPressed: widget.isPlayingAi ? null : widget.onPlayAi,
                icon: Icon(
                  widget.isPlayingAi ? Icons.volume_up : Icons.play_arrow_rounded,
                  size: 18,
                ),
                label: Text(widget.isPlayingAi ? 'Speaking…' : 'Play'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryPurple,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          if (isUser && cardCorrections.isNotEmpty)
            ...cardCorrections.map((c) => _CorrectionCard(correction: c)),
        ],
      ),
    );
  }
}

class _CorrectionCard extends StatefulWidget {
  const _CorrectionCard({required this.correction});

  final GrammarCorrection correction;

  @override
  State<_CorrectionCard> createState() => _CorrectionCardState();
}

class _CorrectionCardState extends State<_CorrectionCard> {
  bool _expanded = false;
  bool _saving = false;
  bool _saved = false;

  bool get _isSaved => _saved || widget.correction.autoSaved;

  Future<void> _saveToNotes() async {
    if (_saving || _isSaved) return;
    setState(() => _saving = true);
    try {
      final result = await NoteService.instance.saveFromCorrection(
        correctedText: widget.correction.correctedText,
        originalText: widget.correction.originalText,
        explanation: widget.correction.explanation,
        errorType: widget.correction.errorType,
      );
      if (!mounted) return;
      if (result.ok) {
        setState(() => _saved = true);
        final msg =
            result.flashcardCreated
                ? 'Saved to notes and From speaking deck'
                : 'Saved to notes';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Could not save')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryYellow.withValues(alpha: 0.8),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isSaved
                              ? Icons.bookmark_added_rounded
                              : Icons.auto_fix_high,
                          size: 16,
                          color: AppColors.primaryPurple,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.correction.correctedText,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryPurple,
                            ),
                          ),
                        ),
                        if (_isSaved) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryYellow.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppColors.primaryYellow.withValues(
                                  alpha: 0.85,
                                ),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.bookmark_added_rounded,
                                  size: 13,
                                  color: AppColors.primaryPurple,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Saved',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryPurple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Icon(
                          _expanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          size: 18,
                        ),
                      ],
                    ),
                    if (_expanded) ...[
                      const SizedBox(height: 8),
                      Text(
                        'You said: ${widget.correction.originalText}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.correction.explanation,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      if (!_isSaved) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _saving ? null : _saveToNotes,
                            icon: Icon(
                              _saving
                                  ? Icons.hourglass_top_rounded
                                  : Icons.bookmark_add_outlined,
                              size: 16,
                            ),
                            label: Text(_saving ? 'Saving…' : 'Save to notes'),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        Text(
                          'Added to your From speaking deck',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProcessingIndicator extends StatelessWidget {
  const _ProcessingIndicator({
    required this.isProcessing,
    required this.stage,
    this.onCancel,
  });

  final bool isProcessing;
  final ConversationProcessingStage stage;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    if (!isProcessing || stage == ConversationProcessingStage.speaking) {
      return const SizedBox.shrink();
    }

    final label = switch (stage) {
      ConversationProcessingStage.transcribing => 'Listening…',
      ConversationProcessingStage.thinking => 'Thinking…',
      ConversationProcessingStage.speaking => 'Speaking…',
      ConversationProcessingStage.idle => '',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: TextStyle(color: Colors.grey.shade700)),
          ),
          if (onCancel != null)
            TextButton(onPressed: onCancel, child: const Text('Cancel')),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.isRecording,
    required this.isProcessing,
    required this.textController,
    required this.onMicTap,
    required this.onSendText,
    this.recordingDurationLabel,
    this.typeMessagesEnabled = false,
    this.onCancel,
  });

  final bool isRecording;
  final bool isProcessing;
  final String? recordingDurationLabel;
  final TextEditingController textController;
  final VoidCallback onMicTap;
  final VoidCallback onSendText;
  final bool typeMessagesEnabled;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final showTextInput = typeMessagesEnabled || (kIsWeb && kDebugMode);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            if (showTextInput)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: textController,
                        enabled: !isProcessing && !isRecording,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => onSendText(),
                        decoration: InputDecoration(
                          hintText: 'Type your message…',
                          filled: true,
                          fillColor: const Color(0xFFF2F2F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed:
                          isProcessing || isRecording ? null : onSendText,
                      icon: const Icon(Icons.send),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            if (!showTextInput || kIsWeb)
              Text(
                isRecording
                    ? 'Recording ${recordingDurationLabel ?? '00:00'} — tap to stop'
                    : 'Tap the mic to speak',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            if (onCancel != null) ...[
              const SizedBox(height: 6),
              TextButton(onPressed: onCancel, child: const Text('Cancel')),
            ],
            if (!showTextInput || kIsWeb) const SizedBox(height: 10),
            if (!showTextInput || kIsWeb)
              GestureDetector(
                onTap: isProcessing ? null : onMicTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isRecording
                            ? AppColors.redWrong
                            : AppColors.primaryPurple,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryPurple.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    isRecording ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
