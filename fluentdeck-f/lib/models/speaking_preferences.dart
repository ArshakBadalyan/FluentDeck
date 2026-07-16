class SpeakingPreferences {
  final String practiceLanguage;
  final bool syncLearningLanguage;
  final String responseLanguage;
  final String translationLanguage;
  final bool showTranslations;
  final bool autoPlayVoice;
  final bool autoConversation;
  final bool soundOn;
  final bool typeMessagesEnabled;
  final bool autoStartRecording;
  /// Pause after tutor finishes (or after text appears if voice is off) before auto-mic.
  final int autoStartRecordingDelaySeconds;
  final bool autoSaveCorrections;
  final bool dailyReminderEnabled;
  final String dailyReminderTime;
  final int correctSentenceGoal;
  final int correctSentencesToday;
  final String? englishLevel;
  final String tutorVoice;

  const SpeakingPreferences({
    this.practiceLanguage = 'en',
    this.syncLearningLanguage = true,
    this.responseLanguage = 'en',
    this.translationLanguage = 'none',
    this.showTranslations = false,
    this.autoPlayVoice = true,
    this.autoConversation = false,
    this.soundOn = true,
    this.typeMessagesEnabled = false,
    this.autoStartRecording = false,
    this.autoStartRecordingDelaySeconds = 2,
    this.autoSaveCorrections = true,
    this.dailyReminderEnabled = false,
    this.dailyReminderTime = '09:00',
    this.correctSentenceGoal = 10,
    this.correctSentencesToday = 0,
    this.englishLevel = 'A1',
    this.tutorVoice = 'nova',
  });

  /// OpenAI TTS voices, with a short descriptor for the picker UI.
  static const voiceOptions = {
    'nova': 'Nova — Female',
    'onyx': 'Onyx — Male',
    'alloy': 'Alloy — Neutral',
    'echo': 'Echo — Male',
    'fable': 'Fable — Male, expressive',
    'shimmer': 'Shimmer — Female, soft',
  };

  /// Voices available on the free tier; the rest require Premium.
  static const freeVoiceIds = {'nova', 'onyx'};

  static const practiceLanguageOptions = {
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'it': 'Italian',
    'pt': 'Portuguese',
    'zh': 'Mandarin Chinese',
    'ja': 'Japanese',
    'ru': 'Russian',
    'hi': 'Hindi',
  };

  static const responseLanguageOptions = {
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'it': 'Italian',
    'hi': 'Hindi',
    'pt': 'Portuguese',
    'zh': 'Mandarin Chinese',
    'ja': 'Japanese',
    'ru': 'Russian',
  };

  static const translationLanguageOptions = {
    'none': 'Off',
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'it': 'Italian',
    'hi': 'Hindi',
    'pt': 'Portuguese',
    'zh': 'Mandarin Chinese',
    'ja': 'Japanese',
    'ru': 'Russian',
    'ar': 'Arabic',
    'hy': 'Armenian',
    'ko': 'Korean',
    'tr': 'Turkish',
    'uk': 'Ukrainian',
  };

  bool get usesResponseSwitching => responseLanguage != practiceLanguage;

  factory SpeakingPreferences.fromUser(Map<String, dynamic>? user) {
    if (user == null) return const SpeakingPreferences();
    return SpeakingPreferences(
      practiceLanguage: user['practice_language'] as String? ?? 'en',
      syncLearningLanguage: user['sync_learning_language'] != false,
      responseLanguage: user['response_language'] as String? ?? 'en',
      translationLanguage: user['translation_language'] as String? ?? 'none',
      showTranslations: user['show_translations'] == true,
      autoPlayVoice: user['auto_play_voice'] as bool? ?? true,
      autoConversation: user['auto_conversation'] == true,
      soundOn: user['sound_on'] as bool? ?? user['sound'] as bool? ?? true,
      typeMessagesEnabled: user['type_messages_enabled'] == true,
      autoStartRecording: user['auto_start_recording'] == true,
      autoStartRecordingDelaySeconds: _clampDelaySeconds(
        user['auto_start_recording_delay_seconds'],
      ),
      autoSaveCorrections: user['auto_save_corrections'] as bool? ?? true,
      dailyReminderEnabled: user['daily_reminder_enabled'] == true,
      dailyReminderTime: user['daily_reminder_time'] as String? ?? '09:00',
      correctSentenceGoal: user['correct_sentence_goal'] as int? ?? 10,
      correctSentencesToday: user['correct_sentences_today'] as int? ?? 0,
      englishLevel: user['english_level'] as String? ?? 'A1',
      tutorVoice: user['tutor_voice'] as String? ?? 'nova',
    );
  }

  Map<String, dynamic> toUpdatePayload() {
    return {
      'practice_language': practiceLanguage,
      'sync_learning_language': syncLearningLanguage,
      'auto_save_corrections': autoSaveCorrections,
      'response_language': responseLanguage,
      'translation_language': translationLanguage,
      'show_translations': translationLanguage != 'none',
      'auto_play_voice': autoPlayVoice,
      'auto_conversation': autoConversation,
      'sound_on': soundOn,
      'type_messages_enabled': typeMessagesEnabled,
      'auto_start_recording': autoStartRecording,
      'auto_start_recording_delay_seconds': autoStartRecordingDelaySeconds,
      'daily_reminder_enabled': dailyReminderEnabled,
      'daily_reminder_time': dailyReminderTime,
      'correct_sentence_goal': correctSentenceGoal,
      'tutor_voice': tutorVoice,
      if (englishLevel != null) 'english_level': englishLevel,
    };
  }

  static int _clampDelaySeconds(Object? raw) {
    final parsed = raw is int ? raw : int.tryParse(raw?.toString() ?? '');
    if (parsed == null) return 2;
    if (parsed < 0) return 0;
    if (parsed > 10) return 10;
    return parsed;
  }
}
