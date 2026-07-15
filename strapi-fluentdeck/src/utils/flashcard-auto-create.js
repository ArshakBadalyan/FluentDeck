'use strict';

const { createNoteAndCards } = require('./flashcard-note-sync');
const { resolveUserLanguageCode } = require('./user-language');

const DEFAULT_DECKS = [
  { slug: 'saved_words', name: 'Saved words' },
  { slug: 'from_speaking', name: 'From speaking' },
];

async function userWantsAutoCreate(strapi, userId) {
  const user = await strapi.db.query('plugin::users-permissions.user').findOne({
    where: { id: userId },
  });
  const flag = user?.autoCreateFlashcards ?? user?.auto_create_flashcards;
  return flag !== false;
}

async function getOrCreateDefaultDeck(strapi, userId, slug) {
  const meta = DEFAULT_DECKS.find((d) => d.slug === slug);
  if (!meta) throw new Error(`Unknown deck slug: ${slug}`);

  const existing = await strapi.db.query('api::flashcard-deck.flashcard-deck').findOne({
    where: { user: userId, deckSlug: slug },
  });
  if (existing) return existing;

  return strapi.db.query('api::flashcard-deck.flashcard-deck').create({
    data: {
      name: meta.name,
      deckSlug: slug,
      isDefault: true,
      user: userId,
    },
  });
}

function buildCardBack({ definition, exampleSentence, explanation }) {
  const parts = [];
  if (definition) parts.push(definition);
  if (exampleSentence) parts.push(`Example: ${exampleSentence}`);
  if (explanation) parts.push(explanation);
  return parts.join('\n\n') || '—';
}

async function createFlashcardForNote(strapi, userId, { word, deckSlug, noteId, back, languageCode }) {
  const deck = await getOrCreateDefaultDeck(strapi, userId, deckSlug);

  const duplicate = await strapi.db.query('api::flashcard.flashcard').findOne({
    where: { user: userId, deck: deck.id, front: word },
  });
  if (duplicate) {
    return { created: false, flashcardId: duplicate.id, deckId: deck.id };
  }

  const lang = await resolveUserLanguageCode(strapi, userId, languageCode);
  const result = await createNoteAndCards(strapi, userId, {
    deckId: deck.id,
    noteType: 'basic',
    fields: { Front: word, Back: back },
    tags: [],
    userNoteId: noteId,
    languageCode: lang,
  });

  const card = result.cards[0];
  return {
    created: true,
    flashcardId: card?.id,
    deckId: deck.id,
    noteId: result.note?.id,
  };
}

async function maybeCreateFlashcard(strapi, userId, payload) {
  const enabled = await userWantsAutoCreate(strapi, userId);
  if (!enabled) {
    return { flashcardCreated: false, autoCreateEnabled: false };
  }

  const back = buildCardBack(payload);
  const result = await createFlashcardForNote(strapi, userId, {
    word: payload.word,
    deckSlug: payload.deckSlug,
    noteId: payload.noteId,
    back,
    languageCode: payload.languageCode,
  });

  return {
    flashcardCreated: result.created,
    flashcardId: result.flashcardId,
    deckId: result.deckId,
    autoCreateEnabled: true,
  };
}

async function createUserNote(strapi, userId, data) {
  const { word, definition, exampleSentence, tags, source, languageCode } = data;
  const lang = await resolveUserLanguageCode(strapi, userId, languageCode);

  const noteData = {
    word,
    definition: definition ?? '',
    exampleSentence: exampleSentence ?? '',
    tags: Array.isArray(tags) ? tags : [],
    source: source ?? 'manual',
    languageCode: lang,
    user: userId,
  };

  const note = await strapi.db.query('api::user-note.user-note').create({
    data: noteData,
  });

  return { note, created: true };
}

async function ensureUserDefaultDecks(strapi, userId) {
  for (const deck of DEFAULT_DECKS) {
    await getOrCreateDefaultDeck(strapi, userId, deck.slug);
  }
}

function deckSlugForSource(source) {
  if (source === 'speaking') return 'from_speaking';
  return 'saved_words';
}

function formatNote(row) {
  return {
    id: row.id,
    word: row.word,
    definition: row.definition ?? '',
    exampleSentence: row.exampleSentence ?? row.example_sentence ?? '',
    tags: row.tags ?? [],
    source: row.source ?? 'manual',
    languageCode: row.languageCode ?? row.language_code ?? 'en',
    createdAt: row.createdAt ?? row.created_at,
  };
}

module.exports = {
  DEFAULT_DECKS,
  userWantsAutoCreate,
  getOrCreateDefaultDeck,
  ensureUserDefaultDecks,
  maybeCreateFlashcard,
  createUserNote,
  deckSlugForSource,
  formatNote,
  buildCardBack,
};
