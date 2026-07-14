import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/conversation_session_model.dart';
import '../models/conversation_turn_model.dart';
import '../models/conversation_training_session.dart';
import '../models/grammar_correction.dart';
import '../models/speaking_session_context.dart';
import 'api_service.dart';
import 'user_progress_service.dart';
import 'conversation_limit_service.dart';
import 'conversation_history_service.dart';
import 'speaking_preferences_service.dart';
import 'tts_cache_service.dart';
enum ConversationProcessingStage {
  idle,
  transcribing,
  thinking,
  speaking,
}

class ConversationService {
  ConversationService._();
  static final ConversationService instance = ConversationService._();

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _ttsPlayer = AudioPlayer();

  final List<ConversationTurnModel> turns = [];
  bool isRecording = false;
  bool isProcessing = false;
  ConversationProcessingStage stage = ConversationProcessingStage.idle;
  String? errorMessage;
  int? activeHistorySessionId;
  ConversationTrainingSession trainingSession = const ConversationTrainingSession(
    sourceKey: '',
    sourceLabel: '',
    words: [],
  );
  SpeakingSessionContext sessionContext = SpeakingSessionContext.freeChat();
  bool isEvaluatingSession = false;
  bool isPlayingTts = false;
  int? ttsTurnIndex;
  bool autoPlayVoiceEnabled = true;
  bool autoConversationEnabled = false;
  bool soundOnEnabled = true;
  bool typeMessagesEnabled = false;
  bool autoStartRecordingEnabled = false;
  /// Seconds to wait after tutor audio (or text) before auto-opening the mic.
  int autoStartRecordingDelaySeconds = 2;
  String practiceLanguage = 'en';
  String? englishLevel;
  DateTime? sessionStartedAt;
  DateTime? _recordingStartedAt;
  Timer? _recordingTimer;
  String _webUploadFilename = 'recording.webm';
  bool _chatActive = false;
  int _chatSessionEpoch = 0;

  bool get isChatActive => _chatActive;

  Duration get recordingDuration {
    final started = _recordingStartedAt;
    if (started == null || !isRecording) return Duration.zero;
    return DateTime.now().difference(started);
  }

  String get recordingDurationLabel {
    final totalSeconds = recordingDuration.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  VoidCallback? onStateChanged;

  void _notify() => onStateChanged?.call();

  // #region agent log
  void _agentDebugLog(
    String hypothesisId,
    String location,
    String message, [
    Map<String, Object?> data = const {},
  ]) {
    final payload = <String, Object?>{
      'sessionId': 'fcee54',
      'runId': 'post-fix',
      'hypothesisId': hypothesisId,
      'location': location,
      'message': message,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    unawaited(
      http
          .post(
            Uri.parse(
              'http://127.0.0.1:7337/ingest/ea2fc602-e0ad-43b0-b0a8-176383aba938',
            ),
            headers: {
              'Content-Type': 'application/json',
              'X-Debug-Session-Id': 'fcee54',
            },
            body: jsonEncode(payload),
          )
          .catchError((_) => http.Response('', 500)),
    );
  }
  // #endregion

  Future<void> refreshSpeakingSettings() async {
    final prefs = await SpeakingPreferencesService.instance.load(forceRefresh: true);
    autoPlayVoiceEnabled = prefs.autoPlayVoice;
    autoConversationEnabled = prefs.autoConversation;
    soundOnEnabled = prefs.soundOn;
    typeMessagesEnabled = prefs.typeMessagesEnabled;
    autoStartRecordingEnabled = prefs.autoStartRecording;
    autoStartRecordingDelaySeconds = prefs.autoStartRecordingDelaySeconds;
    practiceLanguage = prefs.practiceLanguage;
    englishLevel = prefs.englishLevel;
    _notify();
  }

  void startDeckPractice({
    required String deckName,
    required String sourceKey,
    required int deckId,
    required List<ConversationTrainingWord> words,
  }) {
    trainingSession = ConversationTrainingSession(
      sourceKey: sourceKey,
      sourceLabel: deckName,
      words: words,
      deckId: deckId,
    );
  }

  void startNotesPractice({
    required String sessionLabel,
    required List<ConversationTrainingWord> words,
  }) {
    trainingSession = ConversationTrainingSession(
      sourceKey: 'my_notes',
      sourceLabel: sessionLabel,
      words: words,
    );
  }

  Future<void> cancelActiveOperation() async {
    await _stopChatAudioOnly(clearError: true);
    _notify();
  }

  /// Stops tutor voice, recording, and in-flight chat work when the user leaves chat.
  Future<void> leaveChat() async {
    _chatSessionEpoch++;
    _chatActive = false;
    await _stopChatAudioOnly();
    _notify();
  }

  Future<void> _stopChatAudioOnly({bool clearError = false}) async {
    if (isRecording) {
      try {
        await _recorder.stop();
      } catch (_) {}
      isRecording = false;
      _stopRecordingTimer();
      if (kIsWeb) {
        await WakelockPlus.disable();
      }
    }
    try {
      await _ttsPlayer.stop();
    } catch (_) {}
    isPlayingTts = false;
    ttsTurnIndex = null;
    isProcessing = false;
    stage = ConversationProcessingStage.idle;
    if (clearError) {
      errorMessage = null;
    }
  }

  Future<void> playAiText(String text, {int? turnIndex}) async {
    if (turnIndex != null) {
      await speakAiTurns([turnIndex]);
      return;
    }
    if (!_chatActive || text.trim().isEmpty) return;
    final index = turns.lastIndexWhere((turn) => !turn.isUser && turn.text == text);
    if (index >= 0) {
      await speakAiTurns([index]);
    }
  }

  /// Speaks every listed AI turn in order (main reply, notices, etc.).
  ///
  /// [isAutomatic] marks a call that's triggered automatically after the tutor
  /// replies (vs. the user explicitly tapping to replay a turn) — only those
  /// calls are gated by [autoPlayVoiceEnabled].
  Future<void> speakAiTurns(
    List<int> turnIndices, {
    bool startMicAfter = false,
    bool isAutomatic = false,
  }) async {
    if (!_chatActive || turnIndices.isEmpty) return;

    final sessionEpoch = _chatSessionEpoch;
    final audioEnabled = soundOnEnabled && (!isAutomatic || autoPlayVoiceEnabled);

    // #region agent log
    _agentDebugLog('A,B,E', 'conversation_service.dart:speakAiTurns:entry', 'speakAiTurns started', {
      'startMicAfter': startMicAfter,
      'isAutomatic': isAutomatic,
      'audioEnabled': audioEnabled,
      'soundOnEnabled': soundOnEnabled,
      'autoPlayVoiceEnabled': autoPlayVoiceEnabled,
      'autoStartRecordingEnabled': autoStartRecordingEnabled,
      'autoConversationEnabled': autoConversationEnabled,
      'isPlayingTts': isPlayingTts,
      'playerState': _ttsPlayer.state.name,
      'turnCount': turnIndices.length,
    });
    // #endregion

    if (audioEnabled) {
      for (final index in turnIndices) {
        if (sessionEpoch != _chatSessionEpoch || !_chatActive) return;
        if (index < 0 || index >= turns.length) continue;
        final turn = turns[index];
        if (turn.isUser || turn.text.trim().isEmpty) continue;
        await _playAiTextAtTurn(index, sessionEpoch: sessionEpoch);
      }
    }

    if (sessionEpoch != _chatSessionEpoch || !_chatActive) return;
    final shouldStartMic =
        startMicAfter &&
        (autoConversationEnabled || autoStartRecordingEnabled) &&
        !isRecording;
    // #region agent log
    _agentDebugLog('A,B,D', 'conversation_service.dart:speakAiTurns:beforeMic', 'evaluating mic start after speak', {
      'shouldStartMic': shouldStartMic,
      'audioEnabled': audioEnabled,
      'isPlayingTts': isPlayingTts,
      'playerState': _ttsPlayer.state.name,
      'isRecording': isRecording,
      'delaySeconds': autoStartRecordingDelaySeconds,
    });
    // #endregion
    if (!shouldStartMic) return;

    // Give the user a beat to read (no audio) or finish listening (after TTS).
    await _delayBeforeAutoMic(sessionEpoch);
    if (sessionEpoch != _chatSessionEpoch || !_chatActive || isRecording) return;

    // #region agent log
    _agentDebugLog('A,D', 'conversation_service.dart:speakAiTurns:micGo', 'starting mic after TTS+delay', {
      'playerState': _ttsPlayer.state.name,
      'isPlayingTts': isPlayingTts,
      'delaySeconds': autoStartRecordingDelaySeconds,
      'audioEnabled': audioEnabled,
    });
    // #endregion
    await startRecording();
  }

  Future<void> _delayBeforeAutoMic(int sessionEpoch) async {
    final seconds = autoStartRecordingDelaySeconds.clamp(0, 10);
    if (seconds <= 0) return;
    final end = DateTime.now().add(Duration(seconds: seconds));
    while (DateTime.now().isBefore(end)) {
      if (sessionEpoch != _chatSessionEpoch || !_chatActive) return;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> _playAiTextAtTurn(
    int turnIndex, {
    required int sessionEpoch,
  }) async {
    if (sessionEpoch != _chatSessionEpoch || !_chatActive) return;
    if (turnIndex < 0 || turnIndex >= turns.length) return;
    final text = turns[turnIndex].text;
    if (text.trim().isEmpty) return;

    isPlayingTts = true;
    ttsTurnIndex = turnIndex;
    stage = ConversationProcessingStage.speaking;
    _notify();
    try {
      await _playTutorReply(text, sessionEpoch: sessionEpoch)
          .timeout(const Duration(seconds: 90));
    } on TimeoutException {
      try {
        await _ttsPlayer.stop();
      } catch (_) {}
    } finally {
      if (sessionEpoch != _chatSessionEpoch || !_chatActive) {
        try {
          await _ttsPlayer.stop();
        } catch (_) {}
        isPlayingTts = false;
        ttsTurnIndex = null;
        stage = ConversationProcessingStage.idle;
        _notify();
        return;
      }
      isPlayingTts = false;
      ttsTurnIndex = null;
      stage = ConversationProcessingStage.idle;
      _notify();
    }
  }

  /// Clears the active chat without saving to history.
  Future<void> resetConversation() async {
    turns.clear();
    errorMessage = null;
    isRecording = false;
    isProcessing = false;
    stage = ConversationProcessingStage.idle;
    activeHistorySessionId = null;
    trainingSession = const ConversationTrainingSession(
      sourceKey: '',
      sourceLabel: '',
      words: [],
    );
    sessionContext = SpeakingSessionContext.freeChat();
    isEvaluatingSession = false;
    sessionStartedAt = null;
    _notify();
  }

  /// Saves the current chat to history (when long enough), then starts fresh.
  Future<void> archiveAndStartNew() async {
    if (turns.length >= 2) {
      activeHistorySessionId ??= DateTime.now().millisecondsSinceEpoch;
      await ConversationHistoryService.instance.saveCurrentSession(
        turns,
        sessionId: activeHistorySessionId,
      );
    }
    activeHistorySessionId = null;
    await resetConversation();
  }

  /// Clears history storage and the active chat.
  Future<void> clearAllHistoryAndReset() async {
    await ConversationHistoryService.instance.clearAll();
    activeHistorySessionId = null;
    await resetConversation();
  }

  /// Clears the Speak tab when a deleted history entry matches the active chat.
  Future<void> clearIfSessionDeleted(ConversationSessionModel session) async {
    final matchesId =
        session.id != null && activeHistorySessionId == session.id;
    final matchesTranscript = _transcriptsMatch(turns, session.transcript);
    if (!matchesId && !matchesTranscript) return;
    activeHistorySessionId = null;
    await resetConversation();
  }

  bool _transcriptsMatch(
    List<ConversationTurnModel> a,
    List<ConversationTurnModel> b,
  ) {
    if (a.isEmpty || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].text.trim() != b[i].text.trim() || a[i].isUser != b[i].isUser) {
        return false;
      }
    }
    return true;
  }

  /// Restores a saved session into the active Speak chat so the user can continue.
  Future<void> loadSession(ConversationSessionModel session) async {
    _chatSessionEpoch++;
    _chatActive = true;
    turns
      ..clear()
      ..addAll(
        session.transcript.map(
          (t) => ConversationTurnModel(
            speaker: t.speaker,
            text: t.text,
            audioUrl: t.audioUrl,
            translation: t.translation,
            corrections: List<GrammarCorrection>.from(t.corrections),
            timestamp: t.timestamp,
          ),
        ),
      );
    activeHistorySessionId = session.id;
    sessionContext = SpeakingSessionContext.freeChat();
    sessionStartedAt = session.startedAt;
    errorMessage = null;
    isRecording = false;
    isProcessing = false;
    stage = ConversationProcessingStage.idle;
    // #region agent log
    _agentDebugLog('H1', 'conversation_service.dart:loadSession', 'session loaded', {
      'sessionId': session.id,
      'turnCount': turns.length,
      'chatActive': _chatActive,
      'title': sessionContext.title,
    });
    // #endregion
    _notify();
  }

  Future<void> _persistActiveSession() async {
    if (turns.length < 2) return;
    activeHistorySessionId ??= DateTime.now().millisecondsSinceEpoch;
    await ConversationHistoryService.instance.saveCurrentSession(
      turns,
      sessionId: activeHistorySessionId,
    );
  }

  /// Clears chat and seeds the tutor with a lesson speaking prompt.
  void startFromPrompt(String prompt) {
    startSession(
      SpeakingSessionContext.freeChat(),
      openingMessage: "Let's practice! $prompt",
    );
  }

  void startSession(
    SpeakingSessionContext context, {
    String? openingMessage,
  }) {
    _chatSessionEpoch++;
    _chatActive = true;
    activeHistorySessionId = null;
    sessionContext = context;
    sessionStartedAt = DateTime.now();
    turns.clear();

    unawaited(_bootstrapSessionOpening(openingMessageOverride: openingMessage));

    errorMessage = null;
    isEvaluatingSession = false;
    _notify();
  }

  /// Shows the tutor greeting when the chat is opened with no messages yet.
  Future<void> ensureWelcomeMessageIfNeeded() async {
    if (turns.isNotEmpty || isRecording || isProcessing) return;
    if (!sessionContext.isFreeChat) return;

    _chatActive = true;
    await refreshSpeakingSettings();
    _seedStaticOpening(context: sessionContext);
    _notify();
  }

  Future<void> _bootstrapSessionOpening({
    String? openingMessageOverride,
  }) async {
    final sessionEpoch = _chatSessionEpoch;
    await refreshSpeakingSettings();
    if (sessionEpoch != _chatSessionEpoch || !_chatActive) return;

    final shouldGenerate =
        trainingSession.isActive || !sessionContext.isFreeChat;

    if (!shouldGenerate) {
      _seedStaticOpening(
        context: sessionContext,
        openingMessage: openingMessageOverride,
      );
      _notify();
      return;
    }

    isProcessing = true;
    stage = ConversationProcessingStage.thinking;
    _notify();

    try {
      final tutor = await _fetchSessionOpeningReply();
      if (sessionEpoch != _chatSessionEpoch || !_chatActive) return;

      final aiTurn = ConversationTurnModel(
        speaker: 'ai',
        text: tutor.reply,
        translation: tutor.translation,
        timestamp: DateTime.now(),
      );
      turns.add(aiTurn);
      final aiTurnIndex = turns.length - 1;
      trainingSession = tutor.trainingSession;

      isProcessing = false;
      stage = ConversationProcessingStage.idle;
      _notify();

      unawaited(
        speakAiTurns(
          [aiTurnIndex],
          startMicAfter:
              autoStartRecordingEnabled || autoConversationEnabled,
          isAutomatic: true,
        ),
      );
    } catch (e, st) {
      debugPrint('_bootstrapSessionOpening failed: $e\n$st');
      isProcessing = false;
      stage = ConversationProcessingStage.idle;
      _seedStaticOpening(
        context: sessionContext,
        openingMessage: openingMessageOverride,
      );
      _notify();
    }
  }

  Future<
    ({
      String reply,
      String? translation,
      ConversationTrainingSession trainingSession,
    })
  >
  _fetchSessionOpeningReply() async {
    final body = <String, dynamic>{
      'message': "Let's begin.",
      'history': <Map<String, String>>[],
      'sessionStart': true,
      'sessionContext': sessionContext.toJson(),
    };
    if (trainingSession.isActive) {
      body['trainingSession'] = trainingSession.toJson();
    }

    final data = await ApiService.post('ai/tutor', body);
    if (data is Map && data['limitReached'] == true) {
      throw Exception('Daily conversation limit reached');
    }
    if (data is Map && data['error'] != null) {
      throw Exception(data['error']['message']?.toString() ?? 'Tutor failed');
    }
    if (data is! Map) {
      throw Exception('Unexpected tutor response');
    }

    return (
      reply: _sanitizeTutorReply(data['reply']?.toString() ?? ''),
      translation: _sanitizeTranslation(_optionalString(data['translation'])),
      trainingSession: ConversationTrainingSession.fromJson(
        data['trainingSession'] is Map
            ? Map<String, dynamic>.from(data['trainingSession'] as Map)
            : null,
      ),
    );
  }

  void _seedStaticOpening({
    required SpeakingSessionContext context,
    String? openingMessage,
  }) {
    final opener =
        openingMessage?.trim().isNotEmpty == true
            ? openingMessage!.trim()
            : context.openingMessage?.trim().isNotEmpty == true
            ? context.openingMessage!.trim()
            : _defaultOpening(context);

    if (opener.isEmpty) return;

    turns.add(
      ConversationTurnModel(
        speaker: 'ai',
        text: opener,
        timestamp: DateTime.now(),
      ),
    );
    final openerIndex = turns.length - 1;
    unawaited(
      speakAiTurns(
        [openerIndex],
        startMicAfter: autoStartRecordingEnabled || autoConversationEnabled,
        isAutomatic: true,
      ),
    );
  }

  String _defaultOpening(SpeakingSessionContext context) {
    switch (context.mode) {
      case SpeakingMode.rolePlay:
        return "Let's begin our role-play: ${context.title}. I'll play ${context.tutorRole ?? 'your partner'}. When you're ready, say something to start.";
      case SpeakingMode.topic:
        return context.starterPrompt?.trim().isNotEmpty == true
            ? context.starterPrompt!.trim()
            : "Let's talk about ${context.title}. What's your take?";
      case SpeakingMode.game:
        return context.openingMessage?.trim().isNotEmpty == true
            ? context.openingMessage!.trim()
            : "Let's play ${context.title}! Ready when you are.";
      case SpeakingMode.lesson:
        return context.exercisePrompt?.trim().isNotEmpty == true
            ? 'Lesson: ${context.title}. ${context.exercisePrompt!.trim()}'
            : 'Lesson: ${context.title}. Let\'s begin.';
      case SpeakingMode.chat:
        return _chatGreetingForLevel(englishLevel);
    }
  }

  /// Opening greeting scaled to the user's CEFR proficiency level, so the
  /// very first tutor message already matches the vocabulary/complexity the
  /// rest of the conversation will use.
  static const _chatGreetingsByLevel = {
    'A1': "Hi! I'm your AI tutor. How can I help you today?",
    'A2': "Hi! I'm your AI tutor. How can I help you today?",
    'B1': "Hi there! I'm your AI tutor. What would you like to talk about today?",
    'B2': "Hello! I'm your AI tutor. What would you like to dive into today?",
    'C1':
        "Hello! I'm your AI tutor, here to help you sharpen your fluency. What's on your mind today?",
    'C2':
        "Greetings! I'm your AI tutor, here to help you refine even the subtlest nuances of the language. What shall we explore today?",
  };

  String _chatGreetingForLevel(String? level) {
    return _chatGreetingsByLevel[level] ??
        SpeakingSessionContext.defaultChatGreeting;
  }

  bool get canEvaluateSession => turns.length >= 2 && !isProcessing;

  Future<SessionEvaluationResult?> evaluateCurrentSession() async {
    if (!canEvaluateSession) return null;
    isEvaluatingSession = true;
    _notify();

    try {
      final history =
          turns
              .map(
                (turn) => {
                  'role': turn.isUser ? 'user' : 'assistant',
                  'text': turn.text,
                },
              )
              .toList();

      final data = await ApiService.post('ai/evaluate-session', {
        'history': history,
        'sessionContext': sessionContext.toJson(),
      });

      if (data is Map && data['error'] != null) {
        throw Exception(
          data['error']['message']?.toString() ?? 'Evaluation failed',
        );
      }
      if (data is! Map) {
        throw Exception('Unexpected evaluation response');
      }

      return SessionEvaluationResult.fromJson(Map<String, dynamic>.from(data));
    } finally {
      isEvaluatingSession = false;
      _notify();
    }
  }

  Future<bool> ensureMicPermission() async {
    return _recorder.hasPermission();
  }

  RecordConfig get _nativeRecordConfig {
    return const RecordConfig(encoder: AudioEncoder.aacLc);
  }

  Future<RecordConfig> _webRecordConfig() async {
    final opusSupported = await _recorder.isEncoderSupported(AudioEncoder.opus);
    if (opusSupported) {
      _webUploadFilename = 'recording.webm';
      return const RecordConfig(
        encoder: AudioEncoder.opus,
        numChannels: 1,
        bitRate: 128000,
      );
    }

    _webUploadFilename = 'recording.wav';
    return const RecordConfig(
      encoder: AudioEncoder.wav,
      sampleRate: 16000,
      numChannels: 1,
    );
  }

  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _recordingStartedAt = null;
  }

  Future<String?> _recordingPath() async {
    if (kIsWeb) return null;
    final dir = await getTemporaryDirectory();
    return '${dir.path}/conversation_${DateTime.now().millisecondsSinceEpoch}.m4a';
  }

  Future<void> startRecording() async {
    if (isProcessing || isRecording) return;
    errorMessage = null;

    // #region agent log
    _agentDebugLog('A,C,D', 'conversation_service.dart:startRecording', 'startRecording called', {
      'isProcessing': isProcessing,
      'isRecording': isRecording,
      'isPlayingTts': isPlayingTts,
      'playerState': _ttsPlayer.state.name,
      'stage': stage.name,
      'autoStartRecordingEnabled': autoStartRecordingEnabled,
      'autoConversationEnabled': autoConversationEnabled,
    });
    // #endregion

    final allowed = await ensureMicPermission();
    if (!allowed) {
      errorMessage = 'Microphone permission is required.';
      _notify();
      return;
    }

    final path = await _recordingPath();
    final config = kIsWeb ? await _webRecordConfig() : _nativeRecordConfig;
    await _recorder.start(config, path: path ?? '');
    isRecording = true;
    _recordingStartedAt = DateTime.now();
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _notify();
    });
    if (kIsWeb) {
      await WakelockPlus.enable();
    }
    _notify();
  }

  Future<void> stopRecordingAndSend() async {
    if (!isRecording) return;
    final recordedFor = recordingDuration;
    final path = await _recorder.stop();
    isRecording = false;
    _stopRecordingTimer();
    if (kIsWeb) {
      await WakelockPlus.disable();
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    _notify();

    if (path == null || path.isEmpty) {
      errorMessage = 'Recording failed. Try again.';
      _notify();
      return;
    }

    // #region agent log
    _agentDebugLog('W1,W3', 'conversation_service.dart:stopRecording', 'recording stopped', {
      'recordedMs': recordedFor.inMilliseconds,
      'pathLen': path.length,
      'isWeb': kIsWeb,
    });
    // #endregion

    // Near-empty clips are rejected before Whisper — silence often hallucinates.
    if (recordedFor < const Duration(milliseconds: 700)) {
      // #region agent log
      _agentDebugLog('LIMIT', 'conversation_service.dart:tooShort', 'skip whisper+tutor; free limit unchanged', {
        'recordedMs': recordedFor.inMilliseconds,
        'willCallTutor': false,
      });
      // #endregion
      errorMessage = 'Could not hear you. Please try again.';
      _notify();
      return;
    }

    isProcessing = true;
    stage = ConversationProcessingStage.transcribing;
    errorMessage = null;
    _notify();

    ConversationTurnModel? userTurn;
    try {
      final userText = (await _transcribe(path)).trim();
      // #region agent log
      _agentDebugLog('W1,W5', 'conversation_service.dart:afterTranscribe', 'transcription result', {
        'recordedMs': recordedFor.inMilliseconds,
        'text': userText,
        'textLen': userText.length,
        'looksHallucinated': _looksLikeWhisperHallucination(userText),
      });
      // #endregion
      if (userText.isEmpty || _looksLikeWhisperHallucination(userText)) {
        // No /ai/tutor call → free/premium daily conversation limit is not consumed.
        // #region agent log
        _agentDebugLog('LIMIT', 'conversation_service.dart:noHear', 'skip tutor; free limit unchanged', {
          'userText': userText,
          'willCallTutor': false,
        });
        // #endregion
        errorMessage = 'Could not hear you. Please try again.';
        return;
      }

      // Only check/consume the free daily meter once we have real speech text.
      final usage = await ConversationLimitService.instance.checkBeforeTurn();
      if (!usage.allowed) {
        errorMessage = _dailyLimitMessage(usage);
        return;
      }

      userTurn = ConversationTurnModel(
        speaker: 'user',
        text: userText,
        timestamp: DateTime.now(),
      );
      turns.add(userTurn);
      stage = ConversationProcessingStage.thinking;
      _notify();

      // #region agent log
      _agentDebugLog('LIMIT', 'conversation_service.dart:beforeTutor', 'calling tutor; limit will use 1 turn', {
        'userText': userText,
        'willCallTutor': true,
        'usedToday': usage.usedToday,
        'isPremium': usage.isPremium,
      });
      // #endregion
      await _completeUserTurn(userText, userTurn: userTurn);
    } catch (e) {
      if (userTurn != null) {
        final index = turns.indexOf(userTurn);
        if (index >= 0) {
          turns.removeAt(index);
        }
      }
      errorMessage = e.toString();
    } finally {
      _finishTurnProcessing();
      _notify();
    }
  }

  /// Clears the "thinking/transcribing" lock. TTS uses [isPlayingTts] + [stage] separately.
  void _finishTurnProcessing() {
    isProcessing = false;
    if (!isPlayingTts &&
        (stage == ConversationProcessingStage.thinking ||
            stage == ConversationProcessingStage.transcribing)) {
      stage = ConversationProcessingStage.idle;
    }
  }

  Future<void> sendTextMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || isProcessing || isRecording) return;
    errorMessage = null;
    await _sendUserMessage(trimmed);
  }

  Future<void> _sendUserMessage(String userText) async {
    final usage = await ConversationLimitService.instance.checkBeforeTurn();
    if (!usage.allowed) {
      errorMessage = _dailyLimitMessage(usage);
      _notify();
      return;
    }

    final userTurn = ConversationTurnModel(
      speaker: 'user',
      text: userText,
      timestamp: DateTime.now(),
    );
    turns.add(userTurn);
    isProcessing = true;
    stage = ConversationProcessingStage.thinking;
    _notify();

    try {
      await _completeUserTurn(userText, userTurn: userTurn);
    } catch (e) {
      final index = turns.indexOf(userTurn);
      if (index >= 0) {
        turns.removeAt(index);
      }
      errorMessage = e.toString();
    } finally {
      _finishTurnProcessing();
      _notify();
    }
  }

  Future<void> _completeUserTurn(
    String userText, {
    required ConversationTurnModel userTurn,
  }) async {
    final turnStarted = userTurn.timestamp ?? DateTime.now();
    final tutor = await _fetchTutorReply(userText);
    if (!isProcessing) return;

    final corrections = _markAutoSavedCorrections(
      tutor.corrections
          .map(
            (item) => GrammarCorrection.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      tutor.autoSavedWords,
    );

    final userIndex = turns.indexOf(userTurn);
    if (userIndex >= 0) {
      turns[userIndex] = ConversationTurnModel(
        speaker: 'user',
        text: userText,
        corrections: corrections,
        timestamp: userTurn.timestamp,
      );
    }

    final aiTurn = ConversationTurnModel(
      speaker: 'ai',
      text: tutor.reply,
      translation: tutor.translation,
      timestamp: DateTime.now(),
    );
    turns.add(aiTurn);
    final aiTurnIndex = turns.length - 1;
    final speakIndices = <int>[aiTurnIndex];

    if (tutor.trainingNotice != null && tutor.trainingNotice!.isNotEmpty) {
      turns.add(
        ConversationTurnModel(
          speaker: 'ai',
          text: tutor.trainingNotice!,
          timestamp: DateTime.now(),
        ),
      );
      speakIndices.add(turns.length - 1);
    }

    // Deck saves are indicated with an icon on the correction — never spoken.
    if (tutor.noteLimitMessage != null && tutor.noteLimitMessage!.isNotEmpty) {
      errorMessage = tutor.noteLimitMessage;
    }

    trainingSession = tutor.trainingSession;
    _notify();

    await UserProgressService.instance.recordConversationTurn(
      corrections: corrections,
      startedAt: turnStarted,
    );

    _finishTurnProcessing();

    unawaited(
      speakAiTurns(
        speakIndices,
        startMicAfter: autoStartRecordingEnabled || autoConversationEnabled,
        isAutomatic: true,
      ),
    );
    await ConversationLimitService.instance.recordTurn();
    await _persistActiveSession();
  }

  /// Whisper often invents YouTube-style lines from silence/noise.
  String _dailyLimitMessage(ConversationUsageStatus usage) {
    final limit = usage.dailyLimit;
    if (usage.isPremium) {
      return 'Daily AI limit reached ($limit turns). Comes back tomorrow — fair use keeps practice available for everyone.';
    }
    return 'Daily limit reached ($limit turns). Upgrade to Premium for a much higher daily allowance.';
  }

  bool _looksLikeWhisperHallucination(String text) {
    final normalized = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) return true;

    const known = <String>[
      'thank you for watching',
      'thanks for watching',
      'thank you for listening',
      'thanks for listening',
      'please subscribe',
      'like and subscribe',
      'see you next time',
      'see you in the next video',
      'thanks for joining us',
      'thanks for joining',
      'subscribe to the channel',
      'don t forget to subscribe',
      'dont forget to subscribe',
      'www',
      'amara org',
      'subtitles by',
      'captioning',
    ];
    for (final phrase in known) {
      if (normalized == phrase || normalized.startsWith('$phrase ')) {
        return true;
      }
    }
    // Extremely short filler tokens (do not reject "yes"/"hi"/etc.).
    if (normalized.length <= 1) return true;
    const fillers = <String>{
      'you',
      'thank you',
      'thanks',
      'um',
      'uh',
      'hmm',
    };
    if (fillers.contains(normalized)) return true;
    return false;
  }

  Future<String> _transcribe(String audioPath) async {
    final uri = Uri.parse('${ApiService.baseUrl}/ai/transcribe');
    final request = http.MultipartRequest('POST', uri);
    final headers = await ApiService.requestHeaders();
    headers.remove('Content-Type');
    request.headers.addAll(headers);
    request.fields['language'] = practiceLanguage;

    if (kIsWeb) {
      final bytes = await _readWebAudioBytes(audioPath);
      request.files.add(
        http.MultipartFile.fromBytes(
          'audio',
          Uint8List.fromList(bytes),
          filename: _webUploadFilename,
        ),
      );
    } else {
      request.files.add(await http.MultipartFile.fromPath('audio', audioPath));
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final body = jsonDecode(response.body);

    if (response.statusCode >= 400) {
      String? message;
      if (body is Map) {
        final error = body['error'];
        if (error is Map) {
          message = error['message']?.toString();
        }
      }
      throw Exception(message ?? 'Transcription failed (${response.statusCode})');
    }

    if (body is Map) {
      // Prefer explicit text — empty string means server discarded silence.
      if (body.containsKey('text')) {
        final text = body['text'];
        return text is String ? text.trim() : '';
      }
      final segments = body['segments'];
      if (segments is List) {
        final joined = segments
            .map((segment) {
              if (segment is! Map) return '';
              return (segment['text'] as String?)?.trim() ?? '';
            })
            .where((segmentText) => segmentText.isNotEmpty)
            .join(' ')
            .trim();
        return joined;
      }
    }
    throw Exception('Unexpected transcription response');
  }

  Future<List<int>> _readWebAudioBytes(String audioPath) async {
    final uri = Uri.parse(audioPath);
    final response = await http.get(uri);
    if (response.statusCode >= 400) {
      throw Exception('Failed to read recording (${response.statusCode})');
    }
    return response.bodyBytes;
  }

  List<GrammarCorrection> _markAutoSavedCorrections(
    List<GrammarCorrection> corrections,
    List<String> autoSavedWords,
  ) {
    if (corrections.isEmpty || autoSavedWords.isEmpty) return corrections;
    final saved = autoSavedWords
        .map((w) => w.trim().toLowerCase())
        .where((w) => w.isNotEmpty)
        .toSet();
    if (saved.isEmpty) return corrections;
    return corrections
        .map(
          (c) => saved.contains(c.correctedText.trim().toLowerCase())
              ? c.copyWith(autoSaved: true)
              : c,
        )
        .toList();
  }

  Future<
    ({
      String reply,
      String? translation,
      List<dynamic> corrections,
      ConversationTrainingSession trainingSession,
      String? trainingNotice,
      List<String> autoSavedWords,
      String? noteLimitMessage,
    })
  >
  _fetchTutorReply(String message) async {
    final historyTurns =
        turns.length > 1 ? turns.sublist(0, turns.length - 1) : <ConversationTurnModel>[];
    final history =
        historyTurns
            .map(
              (turn) => {
                'role': turn.isUser ? 'user' : 'assistant',
                'text': turn.text,
              },
            )
            .toList();

    final body = <String, dynamic>{
      'message': message,
      'history': history,
    };
    if (trainingSession.isActive) {
      body['trainingSession'] = trainingSession.toJson();
    }
    body['sessionContext'] = sessionContext.toJson();

    final data = await ApiService.post('ai/tutor', body);

    if (data is Map && data['limitReached'] == true) {
      final usageMap = <String, dynamic>{
        'allowed': false,
        'usedToday': (data['usedToday'] as num?)?.round() ?? 0,
        'dailyLimit': (data['dailyLimit'] as num?)?.round() ?? 10,
        'isPremium': data['isPremium'] == true,
        'unlimited': data['unlimited'] == true,
      };
      ConversationLimitService.instance.applyServerUsage(usageMap);
      throw Exception(
        _dailyLimitMessage(ConversationUsageStatus.fromJson(usageMap)),
      );
    }

    if (data is Map && data['error'] != null) {
      throw Exception(data['error']['message']?.toString() ?? 'Tutor failed');
    }
    if (data is! Map) {
      throw Exception('Unexpected tutor response');
    }

    if (data['usage'] is Map) {
      ConversationLimitService.instance.applyServerUsage(
        Map<String, dynamic>.from(data['usage'] as Map),
      );
    }

    final autoSavedWords = <String>[];
    final rawAutoSaved = data['autoSavedWords'];
    if (rawAutoSaved is List) {
      for (final item in rawAutoSaved) {
        if (item is Map) {
          final word = item['word']?.toString().trim();
          if (word != null && word.isNotEmpty) autoSavedWords.add(word);
        }
      }
    }
    if (data['noteCreated'] is Map) {
      final note = Map<String, dynamic>.from(data['noteCreated'] as Map);
      final word = note['word']?.toString().trim();
      if (word != null &&
          word.isNotEmpty &&
          !autoSavedWords.any((w) => w.toLowerCase() == word.toLowerCase())) {
        autoSavedWords.add(word);
      }
    }

    final noteLimitMessage =
        data['noteLimitReached'] == true
            ? (data['noteMessage']?.toString() ??
                'Free auto-save limit reached (10 notes). Upgrade for unlimited deck notes.')
            : null;

    return (
      reply: _sanitizeTutorReply(data['reply']?.toString() ?? ''),
      translation: _sanitizeTranslation(_optionalString(data['translation'])),
      corrections: data['corrections'] is List ? data['corrections'] as List : [],
      trainingSession: ConversationTrainingSession.fromJson(
        data['trainingSession'] is Map
            ? Map<String, dynamic>.from(data['trainingSession'] as Map)
            : null,
      ),
      trainingNotice: data['trainingNotice']?.toString(),
      autoSavedWords: autoSavedWords,
      noteLimitMessage: noteLimitMessage,
    );
  }

  String? _optionalString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  /// Strips internal LLM format if the server ever returns it unparsed.
  String _sanitizeTutorReply(String reply) {
    return reply
        .replaceAll(RegExp(r'\s*NOTE_ACTION_JSON:[\s\S]*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s*CORRECTIONS_JSON:\s*\[[\s\S]*\]\s*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s*TRANSLATION:[^\n]*', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^REPLY:\s*', caseSensitive: false), '')
        .trim();
  }

  String? _sanitizeTranslation(String? translation) {
    if (translation == null || translation.isEmpty) return null;
    if (RegExp(r'NOTE_ACTION_JSON', caseSensitive: false).hasMatch(translation)) {
      return null;
    }
    return translation;
  }

  Future<void> _playTutorReply(
    String text, {
    required int sessionEpoch,
  }) async {
    if (text.trim().isEmpty || sessionEpoch != _chatSessionEpoch || !_chatActive) {
      return;
    }

    final cached = await TtsCacheService.instance.readBytes(text);
    if (sessionEpoch != _chatSessionEpoch || !_chatActive) return;
    if (cached != null && cached.isNotEmpty) {
      await _ttsPlayer.stop();
      if (sessionEpoch != _chatSessionEpoch || !_chatActive) return;
      await _startTtsAndWait(
        sessionEpoch: sessionEpoch,
        source: kIsWeb
            ? UrlSource('data:audio/mpeg;base64,${base64Encode(cached)}')
            : BytesSource(Uint8List.fromList(cached)),
        fromCache: true,
        textLen: text.length,
        bytesLen: cached.length,
      );
      return;
    }

    final data = await ApiService.post('ai/tts', {'text': text});
    if (sessionEpoch != _chatSessionEpoch || !_chatActive) return;
    if (data is! Map || data['audioBase64'] is! String) {
      throw Exception('Unexpected TTS response');
    }

    final audioBase64 = data['audioBase64'] as String;
    final bytes = base64Decode(audioBase64);
    await TtsCacheService.instance.writeBytes(text, bytes);
    await _ttsPlayer.stop();

    if (sessionEpoch != _chatSessionEpoch || !_chatActive) return;
    await _startTtsAndWait(
      sessionEpoch: sessionEpoch,
      source: kIsWeb
          ? UrlSource('data:audio/mpeg;base64,$audioBase64')
          : BytesSource(bytes),
      fromCache: false,
      textLen: text.length,
      bytesLen: bytes.length,
    );
  }

  /// Starts TTS and waits until playback finishes (not merely until play starts).
  Future<void> _startTtsAndWait({
    required int sessionEpoch,
    required Source source,
    required bool fromCache,
    required int textLen,
    required int bytesLen,
  }) async {
    final done = Completer<void>();
    var seenPlaying = false;
    // Subscribe before play() so short clips can't complete before we listen.
    final subs = <StreamSubscription<dynamic>>[
      _ttsPlayer.onPlayerComplete.listen((_) {
        if (!done.isCompleted) done.complete();
      }),
      _ttsPlayer.onPlayerStateChanged.listen((state) {
        if (state == PlayerState.playing) {
          seenPlaying = true;
          return;
        }
        // Ignore a stale "stopped" from the previous stop() before this play().
        if (!seenPlaying) return;
        if (state == PlayerState.completed || state == PlayerState.stopped) {
          if (!done.isCompleted) done.complete();
        }
      }),
    ];

    try {
      await _ttsPlayer.play(source);
      if (_ttsPlayer.state == PlayerState.playing) {
        seenPlaying = true;
      }
      // #region agent log
      _agentDebugLog(
        'A',
        'conversation_service.dart:_startTtsAndWait:afterPlay',
        'play() returned; waiting for completion',
        {
          'playerState': _ttsPlayer.state.name,
          'textLen': textLen,
          'fromCache': fromCache,
          'bytesLen': bytesLen,
        },
      );
      // #endregion

      if (_ttsPlayer.state == PlayerState.completed) {
        if (!done.isCompleted) done.complete();
      }

      while (!done.isCompleted) {
        if (sessionEpoch != _chatSessionEpoch || !_chatActive) return;
        await Future.any([
          done.future,
          Future<void>.delayed(const Duration(milliseconds: 150)),
        ]);
      }

      // #region agent log
      _agentDebugLog(
        'A,D',
        'conversation_service.dart:_startTtsAndWait:completed',
        'TTS playback finished',
        {
          'playerState': _ttsPlayer.state.name,
          'isPlayingTts': isPlayingTts,
          'fromCache': fromCache,
        },
      );
      // #endregion
    } finally {
      for (final sub in subs) {
        await sub.cancel();
      }
    }
  }

  Future<void> dispose() async {
    await _recorder.dispose();
    await _ttsPlayer.dispose();
  }
}
