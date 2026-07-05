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
  String practiceLanguage = 'en';
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

  Future<void> refreshSpeakingSettings() async {
    final prefs = await SpeakingPreferencesService.instance.load(forceRefresh: true);
    autoPlayVoiceEnabled = prefs.autoPlayVoice;
    autoConversationEnabled = prefs.autoConversation;
    soundOnEnabled = prefs.soundOn;
    typeMessagesEnabled = prefs.typeMessagesEnabled;
    autoStartRecordingEnabled = prefs.autoStartRecording;
    practiceLanguage = prefs.practiceLanguage;
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
    if (shouldStartMic) {
      await startRecording();
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
    errorMessage = null;
    isRecording = false;
    isProcessing = false;
    stage = ConversationProcessingStage.idle;
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
        return SpeakingSessionContext.defaultChatGreeting;
    }
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

    final usage = await ConversationLimitService.instance.checkBeforeTurn();
    if (!usage.allowed) {
      errorMessage =
          'Daily limit reached (${usage.dailyLimit} conversations). '
          'Upgrade to premium for unlimited practice.';
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
      if (userText.isEmpty) {
        errorMessage = 'Could not hear you. Please try again.';
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
      errorMessage =
          'Daily limit reached (${usage.dailyLimit} conversations). '
          'Upgrade to premium for unlimited practice.';
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

    final corrections =
        tutor.corrections
            .map(
              (item) => GrammarCorrection.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList();

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

    if (tutor.noteMessage != null && tutor.noteMessage!.isNotEmpty) {
      turns.add(
        ConversationTurnModel(
          speaker: 'ai',
          text: tutor.noteMessage!,
          timestamp: DateTime.now(),
        ),
      );
      speakIndices.add(turns.length - 1);
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
      final text = body['text'];
      if (text is String && text.trim().isNotEmpty) {
        return text.trim();
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
        if (joined.isNotEmpty) {
          return joined;
        }
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

  Future<
    ({
      String reply,
      String? translation,
      List<dynamic> corrections,
      ConversationTrainingSession trainingSession,
      String? trainingNotice,
      String? noteMessage,
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
      final usage = data['usedToday'] != null
          ? ConversationUsageStatus(
              allowed: false,
              usedToday: (data['usedToday'] as num?)?.round() ?? 0,
              dailyLimit: (data['dailyLimit'] as num?)?.round() ?? 10,
              isPremium: data['isPremium'] == true,
            )
          : null;
      if (usage != null) {
        ConversationLimitService.instance.applyServerUsage({
          'allowed': false,
          'usedToday': usage.usedToday,
          'dailyLimit': usage.dailyLimit,
          'isPremium': usage.isPremium,
        });
      }
      throw Exception(
        'Daily limit reached (${data['dailyLimit'] ?? 10} conversations). '
        'Upgrade to premium for unlimited practice.',
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

    String? noteMessage;
    if (data['noteLimitReached'] == true) {
      noteMessage =
          data['noteMessage']?.toString() ??
          'Free auto-save limit reached (10 notes). Upgrade for unlimited deck notes.';
    } else if (data['noteCreated'] is Map) {
      final note = Map<String, dynamic>.from(data['noteCreated'] as Map);
      final word = note['word']?.toString() ?? 'Note';
      final deckName = note['deckName']?.toString() ?? 'deck';
      final remaining = note['remainingFree'];
      final autoSaved = note['autoSaved'] == true;
      noteMessage =
          autoSaved
              ? (remaining == null
                  ? 'Auto-saved "$word" to $deckName.'
                  : 'Auto-saved "$word" to $deckName. ($remaining free auto-saves left)')
              : (remaining == null
                  ? 'Saved "$word" to $deckName.'
                  : 'Saved "$word" to $deckName. ($remaining free auto-saves left)');
    }

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
      noteMessage: noteMessage,
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
      if (kIsWeb) {
        await _ttsPlayer.play(
          UrlSource(
            'data:audio/mpeg;base64,${base64Encode(cached)}',
          ),
        );
      } else {
        await _ttsPlayer.play(BytesSource(Uint8List.fromList(cached)));
      }
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
    if (kIsWeb) {
      await _ttsPlayer.play(
        UrlSource('data:audio/mpeg;base64,$audioBase64'),
      );
    } else {
      await _ttsPlayer.play(BytesSource(bytes));
    }
  }

  Future<void> dispose() async {
    await _recorder.dispose();
    await _ttsPlayer.dispose();
  }
}
