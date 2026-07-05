const fs = require("fs");
const OpenAI = require("openai");
const { toFile } = require("openai");

const TUTOR_MODEL = process.env.AI_TUTOR_MODEL || "gpt-4o-mini";
const TTS_MODEL = process.env.AI_TTS_MODEL || "tts-1";
const TTS_VOICE = process.env.AI_TTS_VOICE || "nova";
const WHISPER_MODEL = process.env.AI_WHISPER_MODEL || "whisper-1";

/** OpenAI TTS voices selectable in Settings > AI tutor voice. */
const TUTOR_VOICES = ["alloy", "echo", "fable", "onyx", "nova", "shimmer"];

function resolveTutorVoice(voice) {
  return TUTOR_VOICES.includes(voice) ? voice : TTS_VOICE;
}

const LANGUAGE_LABELS = {
  en: "English",
  es: "Spanish",
  fr: "French",
  de: "German",
  it: "Italian",
  hi: "Hindi",
  pt: "Portuguese",
  zh: "Mandarin Chinese",
  ja: "Japanese",
  ru: "Russian",
  none: "None",
};

function languageLabel(code) {
  return LANGUAGE_LABELS[String(code ?? "").trim()] || "English";
}

function getOpenAIClient() {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    throw new Error("OPENAI_API_KEY is not configured");
  }
  return new OpenAI({ apiKey });
}

const TUTOR_SYSTEM_PROMPT = `You are an expert, warm, and encouraging {{practiceLanguageLabel}} conversation tutor inside a language-learning app. You are talking with {{userLevel}} level {{practiceLanguageLabel}} learner (CEFR scale). Their known weak areas are: {{weakAreas}}.
{{trainingBlock}}

Your job every turn:
1. Respond naturally and conversationally to what the user said, as a friendly native speaker would — keep replies short (1-3 sentences), ask a follow-up question to keep the conversation going, and match the user's topic/energy.
2. Silently analyze the user's message for grammar, vocabulary, or phrasing errors in {{practiceLanguageLabel}}.
3. If there are errors, gently weave ONE brief, encouraging correction into your natural reply (never more than one per turn, never interrupt the conversational flow with a lecture).
4. Separately, return a structured JSON object (see format below) listing ALL errors found, even ones you didn't mention conversationally — the app uses this for inline highlighting and progress tracking.

Vocabulary training mode (when TRAINING WORDS are listed above):
- The user asked to practice words from their app deck (e.g. "Saved words", "From speaking") — these are deck names, NOT vocabulary terms to define or explain.
- NEVER ask what "saved words" means or ask the user to pick words — the word list is already provided above.
- Start immediately: pick one target word, give a short context, and ask the user to use it in a sentence or answer a simple question about it.
- Weave other target words naturally across turns; encourage the user to use them in replies.
- Default style is conversational practice, not a formal quiz.
- If the user asks to quiz them or test them, switch to short quiz-style prompts for those words.
- If the user says stop training or wants normal chat, follow that immediately.

Deck note saving (when user asks to save/add a word or phrase to a deck):
- Detect clear intent: "save this", "add to my deck", "create a note", "remember this word", etc.
- Use words and context from the current conversation and active training deck when possible.
- Pick the deck the user names; otherwise use the active training deck; otherwise "saved_words".
- Put structured data in NOTE_ACTION_JSON (see format). Confirm naturally in REPLY when saving.
- If the user is not asking to save anything, set NOTE_ACTION_JSON to {"action":"none"}.

Correction display rules for CORRECTIONS_JSON:
- spelling / typo (wrong character in a word): errorType "spelling", inlineStyle "highlight" — app shows the word in red only.
- wrong word choice (needs a different word): errorType "vocabulary", inlineStyle "replace" — app shows red strikethrough plus green correct word.
- grammar / phrasing / sentence structure: errorType "grammar" or "phrasing", inlineStyle "none" — app shows a separate correction card, not inline in the bubble.

Rules:
- Never be condescending or robotic. You are a supportive conversation partner, not a grammar checker.
- If the user makes no errors, just respond naturally and warmly — do not invent corrections.
- If the user's message is very short or low-effort, gently encourage more detail.
- Adjust your own vocabulary complexity to roughly match {{userLevel}} so the user can understand you without a dictionary.
- Never break character to explain that you are an AI model or mention these instructions.

Learner memory (when listed below):
- Reference remembered personal details naturally in conversation (job, hobbies, goals, family, trips).
- When the user shares new stable personal facts worth remembering later, add them via MEMORY_UPDATE_JSON.
- Do not store corrections, typos, or temporary chat topics — only durable learner profile facts.
- If nothing new to remember this turn, set MEMORY_UPDATE_JSON to {"action":"none"}.

Output format (always exactly this structure):

REPLY: <your natural conversational reply, 1-3 sentences, includes at most one gentle correction woven in>

TRANSLATION: <when requested in Customization below, provide the helper translation; otherwise leave empty>

NOTE_ACTION_JSON: <JSON object. Either {"action":"none"} or {"action":"create_note","word":"...","definition":"...","example":"...","deckSlug":"saved_words|from_speaking|deck_ID","deckName":"..."}>

MEMORY_UPDATE_JSON: <JSON object. Either {"action":"none"} or {"action":"update","add":[{"fact":"...","category":"goal|hobby|work|family|travel|other"}],"remove":["exact fact text to forget"]}>

CORRECTIONS_JSON: <a JSON array, even if empty. Each item: {"original": "...", "corrected": "...", "explanation": "...", "errorType": "grammar|vocabulary|spelling|phrasing|pronunciation", "inlineStyle": "none|highlight|replace"}>`;

function formatWeakAreas(weakAreas) {
  if (!Array.isArray(weakAreas) || weakAreas.length === 0) {
    return "none identified yet";
  }
  return weakAreas
    .map((area) => {
      const label = area.label || area.errorType || "general";
      const count = area.count ?? 0;
      return `${label} (${count})`;
    })
    .join(", ");
}

function formatConversationHistory(history) {
  if (!Array.isArray(history) || history.length === 0) {
    return "(no prior messages)";
  }
  return history
    .map((turn) => {
      const role = turn.role === "assistant" ? "Tutor" : "User";
      return `${role}: ${turn.text}`;
    })
    .join("\n");
}

function formatSessionContextBlock(sessionContext) {
  if (!sessionContext || typeof sessionContext !== "object") {
    return "";
  }

  const mode = String(sessionContext.mode ?? "chat").trim().toLowerCase();
  const title = String(sessionContext.title ?? "").trim();
  const lines = [];

  if (mode === "role_play") {
    const userRole = String(sessionContext.userRole ?? "Learner").trim();
    const tutorRole = String(sessionContext.tutorRole ?? "Conversation partner").trim();
    const situation = String(sessionContext.situation ?? sessionContext.scenario ?? "").trim();
    lines.push("ROLE-PLAY MODE ACTIVE");
    if (title) lines.push(`Scenario: ${title}`);
    lines.push(`You are playing the role of: ${tutorRole}`);
    lines.push(`The user is playing: ${userRole}`);
    if (situation) lines.push(`Situation: ${situation}`);
    lines.push(
      "Stay fully in character as your role. Drive the scenario naturally with realistic dialogue. Do not break character.",
    );
  } else if (mode === "topic") {
    const prompt = String(sessionContext.starterPrompt ?? sessionContext.situation ?? "").trim();
    const vocab = sessionContext.suggestedVocabulary;
    lines.push("TOPIC CONVERSATION MODE ACTIVE");
    if (title) lines.push(`Topic: ${title}`);
    if (prompt) lines.push(`Focus: ${prompt}`);
    if (Array.isArray(vocab) && vocab.length) {
      lines.push(`Encourage use of: ${vocab.join(", ")}`);
    }
    lines.push("Keep the discussion centered on this topic while staying conversational.");
  } else if (mode === "game") {
    const rules = String(sessionContext.gameRules ?? sessionContext.systemPrompt ?? "").trim();
    lines.push("GAME MODE ACTIVE");
    if (title) lines.push(`Game: ${title}`);
    if (rules) lines.push(`Game rules:\n${rules}`);
    lines.push("Follow the game rules strictly while keeping English natural and encouraging.");
  } else if (mode === "lesson") {
    const description = String(sessionContext.lessonDescription ?? "").trim();
    const objectives = String(sessionContext.lessonObjectives ?? "").trim();
    const exercisePrompt = String(sessionContext.exercisePrompt ?? "").trim();
    lines.push("STRUCTURED LESSON MODE ACTIVE");
    if (title) lines.push(`Lesson: ${title}`);
    if (description) lines.push(`Lesson focus:\n${description}`);
    if (objectives) lines.push(`Learning objectives:\n${objectives}`);
    if (exercisePrompt) lines.push(`Current exercise:\n${exercisePrompt}`);
    lines.push(
      "Teach interactively like a 15-minute lesson with a real tutor: explain briefly, ask the learner to practice, give feedback, then move to the next mini-step. Stay on the lesson theme.",
    );
  }

  if (!lines.length) return "";
  return `\n${lines.join("\n")}\n`;
}

function formatCustomizationBlock(speakingPreferences, practiceLanguage = 'en') {
  if (!speakingPreferences || typeof speakingPreferences !== "object") {
    return "";
  }

  const practiceLang = String(
    speakingPreferences.practiceLanguage ??
      speakingPreferences.practice_language ??
      practiceLanguage ??
      'en',
  ).trim();
  const responseLang = String(
    speakingPreferences.responseLanguage ?? speakingPreferences.response_language ?? "en",
  ).trim();
  const translationLang = String(
    speakingPreferences.translationLanguage ??
      speakingPreferences.translation_language ??
      "none",
  ).trim();
  const showTranslations =
    speakingPreferences.showTranslations === true ||
    speakingPreferences.show_translations === true;

  const lines = [];

  if (responseLang && responseLang !== practiceLang) {
    lines.push(
      `RESPONSE SWITCHING: The user speaks ${languageLabel(practiceLang)}. Write your entire REPLY in ${languageLabel(responseLang)} only.`,
    );
    lines.push(
      `Still analyze the user's ${languageLabel(practiceLang)} in CORRECTIONS_JSON (original/corrected in ${languageLabel(practiceLang)}).`,
    );
  }

  if (showTranslations && translationLang !== "none") {
    const helperLang =
      responseLang !== practiceLang ? responseLang : translationLang;
    lines.push(
      `Provide TRANSLATION: a natural ${languageLabel(helperLang)} translation of your REPLY on the TRANSLATION line.`,
    );
  } else {
    lines.push("Leave TRANSLATION empty unless instructed above.");
  }

  return `\nCustomization:\n${lines.join("\n")}\n`;
}

function buildTutorUserPrompt({
  message,
  history,
  userLevel,
  weakAreas,
  trainingSession,
  trainingStarted,
  sessionStart,
  sessionContext,
  speakingPreferences,
  deckCatalogBlock = '',
  memoryBlock = '',
  practiceLanguage = 'en',
}) {
  const { practiceLanguageLabel } = require('./practice-languages');
  const practiceLabel = practiceLanguageLabel(practiceLanguage);
  let trainingBlock = '';
  if (trainingSession?.active && Array.isArray(trainingSession.words) && trainingSession.words.length) {
    const { formatTrainingWordsBlock, resolveSourceLabel } = require('./tutor-vocab-context');
    const label = trainingSession.sourceLabel || resolveSourceLabel(trainingSession.sourceKey);
    trainingBlock = `\nTRAINING MODE ACTIVE — source deck: "${label}". The user wants to practice these app flashcard words (NOT a phrase to define):\n${formatTrainingWordsBlock(trainingSession.words)}\nBegin teaching with the first word now.\n`;
  }

  const sessionBlock = formatSessionContextBlock(sessionContext);
  const customizationBlock = formatCustomizationBlock(speakingPreferences, practiceLanguage);

  const system = TUTOR_SYSTEM_PROMPT
    .replace(/\{\{userLevel\}\}/g, userLevel || 'B1')
    .replace(/\{\{practiceLanguageLabel\}\}/g, practiceLabel)
    .replace(/\{\{weakAreas\}\}/g, formatWeakAreas(weakAreas))
    .replace('{{trainingBlock}}', `${memoryBlock}${trainingBlock}${sessionBlock}${deckCatalogBlock}${customizationBlock}`);

  const conversationBlock = formatConversationHistory(history);
  let userBlock = `Conversation so far:\n${conversationBlock}\n\nUser's latest message:\n${message}`;
  if (trainingStarted && trainingSession?.active) {
    userBlock += `\n\n[System: user just started vocabulary training from "${trainingSession.sourceLabel}". Respond by teaching the first listed word — do not ask what deck names mean.]`;
  } else if (sessionStart) {
    userBlock += '\n\n[System: the user just opened this speaking session. Open with a short, engaging first message based on the session context — do not wait for them to speak first.]';
  }

  return { system, user: userBlock };
}

function inferInlineStyle(item) {
  const explicit = String(item.inlineStyle ?? '').trim().toLowerCase();
  if (explicit === 'highlight' || explicit === 'replace' || explicit === 'none') {
    return explicit;
  }

  const errorType = String(item.errorType ?? 'grammar').trim().toLowerCase();
  if (errorType === 'spelling' || errorType === 'typo') return 'highlight';
  if (errorType === 'vocabulary') return 'replace';
  return 'none';
}

function normalizeCorrection(item) {
  if (!item || typeof item !== 'object') {
    return null;
  }
  const original = String(item.original ?? item.originalText ?? '').trim();
  const corrected = String(item.corrected ?? item.correctedText ?? '').trim();
  const errorType = String(item.errorType ?? 'grammar').trim() || 'grammar';
  return {
    original,
    corrected,
    explanation: String(item.explanation ?? '').trim(),
    errorType,
    inlineStyle: inferInlineStyle({ ...item, errorType }),
  };
}

function parseNoteAction(text) {
  const match = text.match(
    /(?:^|\n)NOTE_ACTION_JSON:\s*(\{[\s\S]*?\})(?=\s*(?:\nCORRECTIONS_JSON:|\s*$))/i,
  );
  if (!match) return null;
  try {
    const parsed = JSON.parse(match[1]);
    return parsed && typeof parsed === 'object' ? parsed : null;
  } catch {
    return null;
  }
}

function parseMemoryAction(text) {
  const match = text.match(
    /(?:^|\n)MEMORY_UPDATE_JSON:\s*(\{[\s\S]*?\})(?=\s*(?:\nCORRECTIONS_JSON:|\s*$))/i,
  );
  if (!match) return null;
  try {
    const parsed = JSON.parse(match[1]);
    return parsed && typeof parsed === 'object' ? parsed : null;
  } catch {
    return null;
  }
}

function parseTutorResponse(raw) {
  const text = String(raw ?? "").trim();
  let corrections = [];
  let translation = "";
  let noteAction = null;
  let memoryUpdate = null;
  let reply = text;

  const jsonMatch = text.match(/CORRECTIONS_JSON:\s*(\[[\s\S]*\])\s*$/i);
  if (jsonMatch) {
    try {
      const parsed = JSON.parse(jsonMatch[1]);
      corrections = Array.isArray(parsed) ? parsed : [];
    } catch {
      corrections = [];
    }
    reply = text.slice(0, jsonMatch.index).trim();
  }

  noteAction = parseNoteAction(reply) ?? parseNoteAction(text);
  memoryUpdate = parseMemoryAction(reply) ?? parseMemoryAction(text);

  const translationMatch = reply.match(
    /(?:^|\n)TRANSLATION:\s*(.*?)(?=\n(?:NOTE_ACTION_JSON:|MEMORY_UPDATE_JSON:|CORRECTIONS_JSON:)|\s*$)/is,
  );
  if (translationMatch) {
    translation = translationMatch[1].trim();
    reply = reply.replace(translationMatch[0], "").trim();
  }

  const replyMatch = reply.match(/^REPLY:\s*(.+)/is);
  if (replyMatch) {
    reply = replyMatch[1].trim();
  }

  reply = reply
    .replace(/\s*TRANSLATION:[\s\S]*/i, "")
    .replace(/\s*NOTE_ACTION_JSON:[\s\S]*/i, "")
    .replace(/\s*MEMORY_UPDATE_JSON:[\s\S]*/i, "")
    .replace(/\s*CORRECTIONS_JSON:[\s\S]*/i, "")
    .trim();

  if (!reply) {
    reply = text
      .replace(/\s*CORRECTIONS_JSON:[\s\S]*/i, "")
      .replace(/\s*NOTE_ACTION_JSON:[\s\S]*/i, "")
      .replace(/\s*MEMORY_UPDATE_JSON:[\s\S]*/i, "")
      .replace(/^REPLY:\s*/i, "")
      .replace(/\s*TRANSLATION:[\s\S]*/i, "")
      .trim();
  }

  corrections = corrections.map(normalizeCorrection).filter(Boolean);

  reply = stripInternalTutorFormats(reply);
  translation = sanitizeTranslation(translation);

  return { reply, corrections, translation, noteAction, memoryUpdate };
}

function stripInternalTutorFormats(text) {
  return String(text ?? "")
    .replace(/\s*NOTE_ACTION_JSON:[\s\S]*/gi, "")
    .replace(/\s*MEMORY_UPDATE_JSON:[\s\S]*/gi, "")
    .replace(/\s*CORRECTIONS_JSON:[\s\S]*/gi, "")
    .replace(/\s*TRANSLATION:[^\n]*/gi, "")
    .replace(/^REPLY:\s*/i, "")
    .trim();
}

function sanitizeTranslation(translation) {
  const cleaned = stripInternalTutorFormats(translation);
  if (!cleaned || /NOTE_ACTION_JSON/i.test(cleaned)) {
    return "";
  }
  return cleaned;
}

async function transcribeAudio(filePath, originalName, language = 'en') {
  const { whisperLanguageCode } = require('./practice-languages');
  const openai = getOpenAIClient();
  const file = await toFile(fs.createReadStream(filePath), originalName || "audio.m4a");
  const result = await openai.audio.transcriptions.create({
    model: WHISPER_MODEL,
    file,
    language: whisperLanguageCode(language),
    response_format: 'verbose_json',
  });

  const segments = Array.isArray(result.segments) ? result.segments : [];
  const segmentText = segments
    .map((segment) => String(segment?.text ?? '').trim())
    .filter(Boolean)
    .join(' ')
    .trim();
  const fullText = String(result.text ?? '').trim() || segmentText;

  return {
    text: fullText,
    segments: segments.map((segment) => ({
      text: String(segment?.text ?? '').trim(),
      start: segment?.start ?? null,
      end: segment?.end ?? null,
    })),
  };
}

async function getTutorReply({
  message,
  history,
  userLevel,
  weakAreas,
  trainingSession,
  trainingStarted,
  sessionStart,
  sessionContext,
  speakingPreferences,
  deckCatalogBlock,
  tutorMemory,
  practiceLanguage = 'en',
}) {
  const { formatMemoryBlock } = require('./tutor-memory');
  const openai = getOpenAIClient();
  const { system, user } = buildTutorUserPrompt({
    message,
    history,
    userLevel,
    weakAreas,
    trainingSession,
    trainingStarted,
    sessionStart,
    sessionContext,
    speakingPreferences,
    deckCatalogBlock,
    memoryBlock: formatMemoryBlock(tutorMemory),
    practiceLanguage,
  });

  const completion = await openai.chat.completions.create({
    model: TUTOR_MODEL,
    messages: [
      { role: "system", content: system },
      { role: "user", content: user },
    ],
    temperature: 0.7,
    max_tokens: 500,
  });

  const raw = completion.choices?.[0]?.message?.content ?? "";
  return parseTutorResponse(raw);
}

async function synthesizeSpeech(text, voicePreference) {
  const voice = resolveTutorVoice(voicePreference);
  const { readCachedAudio, writeCachedAudio } = require('./tts-cache');
  const cached = readCachedAudio(text, voice, TTS_MODEL);
  if (cached) return cached;

  const openai = getOpenAIClient();
  const response = await openai.audio.speech.create({
    model: TTS_MODEL,
    voice,
    input: text,
  });
  const buffer = Buffer.from(await response.arrayBuffer());
  writeCachedAudio(text, voice, TTS_MODEL, buffer);
  return buffer;
}

async function loadUserTutorContext(strapi, userId) {
  const { loadTutorMemory } = require('./tutor-memory');
  const { normalizePracticeLanguage } = require('./practice-languages');
  const { findUserById } = require('./document-service');
  let userLevel = "B1";
  let weakAreas = [];
  let tutorMemory = [];
  let practiceLanguage = 'en';
  let speakingPreferences = {
    responseLanguage: "en",
    translationLanguage: "none",
    showTranslations: false,
  };

  try {
    const user = await findUserById(strapi, userId, {
      fields: [
        "english_level",
        "practice_language",
        "response_language",
        "translation_language",
        "show_translations",
        "auto_conversation",
        "speaking_auto_notes_count",
      ],
    });
    if (user?.english_level) {
      userLevel = user.english_level;
    }
    practiceLanguage = normalizePracticeLanguage(user?.practice_language);
    speakingPreferences = {
      responseLanguage: user?.response_language || "en",
      translationLanguage: user?.translation_language || "none",
      showTranslations: user?.show_translations === true,
      autoConversation: user?.auto_conversation === true,
      speakingAutoNotesCount: Number(user?.speaking_auto_notes_count ?? 0),
      practiceLanguage,
    };
  } catch {
    // fall back to defaults
  }

  try {
    const progresses = await strapi.documents("api::user-progress.user-progress").findMany({
      filters: { user: { id: userId } },
      limit: 1,
    });
    const progress = progresses?.[0];
    if (progress?.currentLevel) {
      userLevel = progress.currentLevel;
    }
    if (Array.isArray(progress?.weakAreas)) {
      weakAreas = progress.weakAreas;
    }
  } catch {
    // fall back to empty weak areas
  }

  try {
    tutorMemory = await loadTutorMemory(strapi, userId);
  } catch {
    tutorMemory = [];
  }

  return { userLevel, weakAreas, speakingPreferences, tutorMemory, practiceLanguage };
}

const EVALUATE_SYSTEM_PROMPT = `You are an expert English speaking assessor for a language-learning app.
Evaluate the user's performance in a completed speaking session.

Score from 0 to 10 where:
- 0-3: struggled significantly, many errors, very short responses
- 4-5: basic communication with frequent issues
- 6-7: good effort, understandable, some errors
- 8-9: strong fluency and accuracy with minor issues
- 10: excellent, natural, accurate throughout

Consider: grammar, vocabulary range, fluency, relevance to the session topic/scenario/game, and engagement.

Respond ONLY with valid JSON (no markdown):
{"score": <integer 0-10>, "feedback": "<2-3 encouraging sentences>", "summary": "<one line for activity history>"}`;

function formatTranscriptForEvaluation(history) {
  if (!Array.isArray(history) || history.length === 0) {
    return "(empty session)";
  }
  return history
    .map((turn) => {
      const role = turn.role === "assistant" ? "Tutor" : "User";
      return `${role}: ${turn.text}`;
    })
    .join("\n");
}

async function evaluateSession({ history, sessionContext, userLevel }) {
  const openai = getOpenAIClient();
  const mode = sessionContext?.mode ?? "chat";
  const title = sessionContext?.title ?? "Free conversation";
  const transcript = formatTranscriptForEvaluation(history);

  const userPrompt = `Session mode: ${mode}
Session title: ${title}
Learner CEFR level: ${userLevel || "B1"}

Transcript:
${transcript}

Evaluate the learner's spoken English in this session.`;

  const completion = await openai.chat.completions.create({
    model: TUTOR_MODEL,
    messages: [
      { role: "system", content: EVALUATE_SYSTEM_PROMPT },
      { role: "user", content: userPrompt },
    ],
    temperature: 0.3,
    max_tokens: 300,
  });

  const raw = completion.choices?.[0]?.message?.content ?? "";
  let parsed;
  try {
    const jsonMatch = raw.match(/\{[\s\S]*\}/);
    parsed = JSON.parse(jsonMatch ? jsonMatch[0] : raw);
  } catch {
    parsed = {
      score: 5,
      feedback: "Good effort! Keep practicing to build fluency.",
      summary: `${title} practice session`,
    };
  }

  const score = Math.min(10, Math.max(0, Math.round(Number(parsed.score) || 5)));
  return {
    score,
    feedback: String(parsed.feedback ?? "").trim() || "Nice work — keep practicing!",
    summary: String(parsed.summary ?? "").trim() || `${title} session`,
  };
}

module.exports = {
  transcribeAudio,
  getTutorReply,
  synthesizeSpeech,
  evaluateSession,
  parseTutorResponse,
  normalizeCorrection,
  buildTutorUserPrompt,
  formatSessionContextBlock,
  formatCustomizationBlock,
  formatWeakAreas,
  languageLabel,
  loadUserTutorContext,
};
