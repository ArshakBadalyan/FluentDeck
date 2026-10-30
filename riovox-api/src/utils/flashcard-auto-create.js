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

function buildCardBack({ definition, explanation }) {
  const parts = [];
  if (definition) parts.push(definition);
  if (explanation) parts.push(explanation);
  return parts.join('\n\n') || '—';
}

function plainText(value) {
  return String(value ?? '')
    .replace(/<[^>]+>/g, '')
    .replace(/\{\{c\d+::(.*?)(::[^}]*)?\}\}/g, '$1')
    .trim();
}

/**
 * Saves a My Notes entry. There is one notes table: the entry is a basic
 * flashcard note in "From speaking" / "Saved words" (Front = word, Back =
 * definition, Example, Translation) flagged inMyNotes. With auto-create off
 * its cards are suspended, so they stay out of reviews.
 */
async function createMyNote(strapi, userId, data) {
  const {
    word,
    definition,
    exampleSentence,
    translation,
    explanation,
    tags,
    source = 'manual',
    languageCode,
    cefrLevel,
    topic,
  } = data;
  const lang = await resolveUserLanguageCode(strapi, userId, languageCode);
  const deck = await getOrCreateDefaultDeck(strapi, userId, deckSlugForSource(source));

  const sameDeckNotes = await strapi.db.query('api::flashcard-note.flashcard-note').findMany({
    where: { user: userId, deck: deck.id },
  });
  const wordKey = String(word).trim().toLowerCase();
  const duplicate = sameDeckNotes.find(
    (n) => plainText(n.fields?.Front).toLowerCase() === wordKey,
  );
  if (duplicate) {
    const note = await strapi.db.query('api::flashcard-note.flashcard-note').update({
      where: { id: duplicate.id },
      data: { inMyNotes: true },
    });
    return {
      note: { ...note, deck },
      created: false,
      flashcardCreated: false,
      deckId: deck.id,
      autoCreateEnabled: await userWantsAutoCreate(strapi, userId),
    };
  }

  const result = await createNoteAndCards(strapi, userId, {
    deckId: deck.id,
    noteType: 'basic',
    fields: {
      Front: String(word).trim(),
      Back: buildCardBack({ definition, explanation }),
      Example: String(exampleSentence ?? '').trim(),
      Translation: String(translation ?? '').trim(),
    },
    tags,
    languageCode: lang,
    source,
    inMyNotes: true,
    cefrLevel: cefrLevel != null && String(cefrLevel).trim() ? String(cefrLevel).trim() : null,
    topic: topic != null && String(topic).trim() ? String(topic).trim() : null,
  });

  const autoCreate = await userWantsAutoCreate(strapi, userId);
  if (!autoCreate) {
    for (const card of result.cards) {
      await strapi.db.query('api::card-review-state.card-review-state').updateMany({
        where: { flashcard: card.id, user: userId },
        data: { suspended: true },
      });
    }
  }

  const note = await strapi.db.query('api::flashcard-note.flashcard-note').findOne({
    where: { id: result.note.id },
    populate: ['deck'],
  });
  return {
    note,
    created: true,
    flashcardCreated: autoCreate,
    flashcardId: result.cards[0]?.id,
    deckId: deck.id,
    autoCreateEnabled: autoCreate,
  };
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

/** A flashcard note in the shape the My Notes API (/notes) returns. */
function formatMyNote(row) {
  const fields = row.fields ?? {};
  const deck = typeof row.deck === 'object' ? row.deck : null;
  const source = row.source ?? 'deck';
  return {
    id: row.id,
    word: plainText(fields.Front ?? fields.Text),
    definition: plainText(fields.Back),
    exampleSentence: plainText(fields.Example),
    translation: String(fields.Translation ?? '').trim(),
    tags: row.tags ?? [],
    source,
    languageCode: row.languageCode ?? row.language_code ?? 'en',
    cefrLevel: row.cefrLevel ?? row.cefr_level ?? null,
    topic: row.topic ?? (source === 'deck' ? deck?.name ?? null : null),
    deckId: deck?.id ?? row.deck ?? null,
    noteType: row.noteType ?? row.note_type ?? 'basic',
    createdAt: row.createdAt ?? row.created_at,
  };
}

module.exports = {
  DEFAULT_DECKS,
  userWantsAutoCreate,
  getOrCreateDefaultDeck,
  ensureUserDefaultDecks,
  createMyNote,
  deckSlugForSource,
  formatMyNote,
  plainText,
  buildCardBack,
};
