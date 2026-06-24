'use strict';

const TRAINING_WORD_LIMIT = 12;

const SOURCE_PATTERNS = [
  { key: 'saved_words', label: 'Saved words', patterns: [/saved\s+words?/i, /my\s+saved/i] },
  { key: 'from_speaking', label: 'From speaking', patterns: [/from\s+speaking/i, /speaking\s+deck/i] },
  {
    key: 'library_notes',
    label: 'Library notes',
    patterns: [/library/i, /my\s+notes?/i, /note(s)?\s+from/i],
  },
  { key: 'custom_deck', label: 'Custom deck', patterns: [/custom\s+deck/i, /my\s+deck/i] },
];

const START_PATTERNS = [
  /teach\s+me/i,
  /train\s+(me|my|on|with|words?)/i,
  /help\s+me\s+(learn|practice|study)/i,
  /practice\s+(my|the|these|some|words?)/i,
  /practice\s+words?\s+from/i,
  /learn\s+(my|the|these|some|words?)/i,
  /quiz\s+me/i,
  /study\s+(my|the|these|some|words?)/i,
  /work\s+on\s+my\s+words?/i,
];

const STOP_PATTERNS = [
  /stop\s+(training|teaching|the\s+lesson|practicing)/i,
  /end\s+(training|lesson|practice)/i,
  /enough\s+(training|practice)/i,
  /let'?s\s+(just\s+)?chat/i,
  /normal\s+conversation/i,
  /no\s+more\s+(training|words?)/i,
];

function detectExplicitSource(message) {
  const text = String(message ?? '').trim();
  for (const source of SOURCE_PATTERNS) {
    if (source.patterns.some((re) => re.test(text))) {
      return source.key;
    }
  }
  return null;
}

function detectTrainingIntent(message, activeSession) {
  const text = String(message ?? '').trim();
  if (!text) {
    return { action: activeSession ? 'continue' : 'none', sourceKey: null };
  }

  if (STOP_PATTERNS.some((re) => re.test(text))) {
    return { action: 'stop', sourceKey: null };
  }

  const wantsTraining = START_PATTERNS.some((re) => re.test(text));
  if (!wantsTraining && activeSession) {
    return { action: 'continue', sourceKey: activeSession.sourceKey ?? null };
  }
  if (!wantsTraining) {
    return { action: 'none', sourceKey: null };
  }

  for (const source of SOURCE_PATTERNS) {
    if (source.patterns.some((re) => re.test(text))) {
      return { action: 'start', sourceKey: source.key };
    }
  }

  return { action: 'start', sourceKey: 'saved_words' };
}

function resolveSourceLabel(sourceKey) {
  return SOURCE_PATTERNS.find((s) => s.key === sourceKey)?.label ?? 'Vocabulary';
}

function shuffle(items) {
  const copy = [...items];
  for (let i = copy.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1));
    [copy[i], copy[j]] = [copy[j], copy[i]];
  }
  return copy;
}

async function loadDeckWords(strapi, userId, deckSlug) {
  let deck = await strapi.db.query('api::flashcard-deck.flashcard-deck').findOne({
    where: { user: userId, deckSlug },
  });

  if (!deck && (deckSlug === 'saved_words' || deckSlug === 'from_speaking')) {
    const { getOrCreateDefaultDeck } = require('./flashcard-auto-create');
    deck = await getOrCreateDefaultDeck(strapi, userId, deckSlug);
  }
  if (!deck) return [];

  const cards = await strapi.db.query('api::flashcard.flashcard').findMany({
    where: { user: userId, deck: deck.id },
    orderBy: { id: 'desc' },
    limit: 50,
  });

  const words = shuffle(cards)
    .slice(0, TRAINING_WORD_LIMIT)
    .map((card) => ({
      word: String(card.front ?? '').trim(),
      hint: String(card.back ?? '').trim().slice(0, 200),
    }))
    .filter((item) => item.word.length > 0);

  return words;
}

async function loadLibraryNoteWords(strapi, userId) {
  const notes = await strapi.db.query('api::user-note.user-note').findMany({
    where: { user: userId },
    populate: ['vocabularyEntry'],
    orderBy: { updatedAt: 'desc' },
    limit: 40,
  });

  const words = [];
  for (const note of notes) {
    const entry = note.vocabularyEntry;
    const word =
      String(note.word ?? '').trim() ||
      (typeof entry === 'object' ? String(entry.word ?? '').trim() : '');
    const hintParts = [
      note.definition,
      note.exampleSentence,
      typeof entry === 'object' ? entry.definition : null,
      typeof entry === 'object' ? entry.exampleSentence : null,
    ]
      .map((part) => String(part ?? '').trim())
      .filter(Boolean);
    if (!word) continue;
    words.push({
      word,
      hint: hintParts.join(' · ').slice(0, 200),
    });
  }

  return shuffle(words).slice(0, TRAINING_WORD_LIMIT);
}

async function loadCustomDeckWords(strapi, userId) {
  const decks = await strapi.db.query('api::flashcard-deck.flashcard-deck').findMany({
    where: { user: userId, isDefault: false, isFiltered: false },
    orderBy: { updatedAt: 'desc' },
    limit: 5,
  });
  if (!decks.length) return [];

  const cards = await strapi.db.query('api::flashcard.flashcard').findMany({
    where: { user: userId, deck: decks[0].id },
    orderBy: { id: 'desc' },
    limit: 50,
  });

  return shuffle(cards)
    .slice(0, TRAINING_WORD_LIMIT)
    .map((card) => ({
      word: String(card.front ?? '').trim(),
      hint: String(card.back ?? '').trim().slice(0, 200),
    }))
    .filter((item) => item.word.length > 0);
}

async function loadTrainingWords(strapi, userId, sourceKey) {
  switch (sourceKey) {
    case 'from_speaking':
      return loadDeckWords(strapi, userId, 'from_speaking');
    case 'library_notes':
      return loadLibraryNoteWords(strapi, userId);
    case 'custom_deck':
      return loadCustomDeckWords(strapi, userId);
    case 'saved_words':
    default:
      return loadDeckWords(strapi, userId, 'saved_words');
  }
}

async function resolveTrainingSession(strapi, userId, message, clientSession) {
  const activeSession =
    clientSession?.active && Array.isArray(clientSession.words) && clientSession.words.length
      ? clientSession
      : null;

  const intent = detectTrainingIntent(message, activeSession);
  const explicitSource = detectExplicitSource(message);

  if (intent.action === 'stop') {
    return { trainingSession: { active: false, sourceKey: null, sourceLabel: null, words: [] } };
  }

  // Keep active session for quiz/practice follow-ups unless user picks a new deck source.
  if (activeSession && intent.action !== 'stop') {
    if (!explicitSource || explicitSource === activeSession.sourceKey) {
      return {
        trainingSession: {
          active: true,
          sourceKey: activeSession.sourceKey,
          sourceLabel: activeSession.sourceLabel ?? resolveSourceLabel(activeSession.sourceKey),
          deckId: activeSession.deckId ?? null,
          words: activeSession.words,
        },
      };
    }
  }

  if (intent.action !== 'start') {
    return { trainingSession: { active: false, sourceKey: null, sourceLabel: null, words: [] } };
  }

  const sourceKey = explicitSource ?? intent.sourceKey ?? 'saved_words';
  const words = await loadTrainingWords(strapi, userId, sourceKey);
  if (!words.length) {
    return {
      trainingSession: { active: false, sourceKey: null, sourceLabel: null, words: [] },
      trainingNotice: `No words found in ${resolveSourceLabel(sourceKey)} yet. Save some words to that deck first, then try again.`,
    };
  }

  return {
    trainingSession: {
      active: true,
      sourceKey,
      sourceLabel: resolveSourceLabel(sourceKey),
      words,
    },
    trainingStarted: true,
  };
}

function formatTrainingWordsBlock(words) {
  if (!Array.isArray(words) || !words.length) return '';
  const lines = words.map((item, index) => {
    const hint = item.hint ? ` — ${item.hint}` : '';
    return `${index + 1}. ${item.word}${hint}`;
  });
  return lines.join('\n');
}

module.exports = {
  TRAINING_WORD_LIMIT,
  detectTrainingIntent,
  detectExplicitSource,
  resolveSourceLabel,
  loadTrainingWords,
  resolveTrainingSession,
  formatTrainingWordsBlock,
};
