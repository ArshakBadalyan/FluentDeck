'use strict';

const { getOrCreateDefaultDeck } = require('./flashcard-auto-create');
const { createNoteAndCards } = require('./flashcard-note-sync');
const { resolveUserLanguageCode } = require('./user-language');
const { findUserById, updateByNumericId } = require('./document-service');
const { isPremiumUser } = require('./app-feature-config');

const FREE_AUTO_NOTE_LIMIT = 10;

async function loadUserDeckCatalog(strapi, userId) {
  const decks = await strapi.db.query('api::flashcard-deck.flashcard-deck').findMany({
    where: { user: userId },
    orderBy: [{ isDefault: 'desc' }, { name: 'asc' }],
    limit: 30,
  });

  return decks.map((deck) => ({
    id: deck.id,
    name: deck.name,
    deckSlug: deck.deckSlug || '',
    isDefault: deck.isDefault === true,
  }));
}

async function resolveDeckForNote(strapi, userId, noteAction, activeTrainingSession) {
  const deckId = noteAction?.deckId ?? activeTrainingSession?.deckId ?? null;
  if (deckId) {
    const deck = await strapi.db.query('api::flashcard-deck.flashcard-deck').findOne({
      where: { id: deckId, user: userId },
    });
    if (deck) return deck;
  }

  const slug = String(noteAction?.deckSlug ?? '').trim();
  if (slug === 'saved_words' || slug === 'from_speaking') {
    return getOrCreateDefaultDeck(strapi, userId, slug);
  }

  if (slug.startsWith('deck_')) {
    const id = Number.parseInt(slug.replace('deck_', ''), 10);
    if (Number.isFinite(id)) {
      const deck = await strapi.db.query('api::flashcard-deck.flashcard-deck').findOne({
        where: { id, user: userId },
      });
      if (deck) return deck;
    }
  }

  if (activeTrainingSession?.sourceKey) {
    const key = String(activeTrainingSession.sourceKey);
    if (key === 'saved_words' || key === 'from_speaking') {
      return getOrCreateDefaultDeck(strapi, userId, key);
    }
    if (key.startsWith('deck_')) {
      const id = Number.parseInt(key.replace('deck_', ''), 10);
      if (Number.isFinite(id)) {
        const deck = await strapi.db.query('api::flashcard-deck.flashcard-deck').findOne({
          where: { id, user: userId },
        });
        if (deck) return deck;
      }
    }
  }

  return getOrCreateDefaultDeck(strapi, userId, 'saved_words');
}

async function processSpeakingNoteAction(strapi, userId, noteAction, options = {}) {
  if (!noteAction || noteAction.action !== 'create_note') {
    return { processed: false };
  }

  const word = String(noteAction.word ?? '').trim();
  if (!word) {
    return { processed: false, reason: 'missing_word' };
  }

  const user = await findUserById(strapi, userId, {
    fields: ['speaking_auto_notes_count'],
  });
  const isPremium = await isPremiumUser(strapi, userId);
  const usedCount = Number(user?.speaking_auto_notes_count ?? 0);

  if (!isPremium && usedCount >= FREE_AUTO_NOTE_LIMIT) {
    return {
      processed: false,
      limitReached: true,
      message:
        'Free auto-save limit reached (10 notes). Upgrade to premium for unlimited deck notes during conversation.',
    };
  }

  const deck = await resolveDeckForNote(
    strapi,
    userId,
    noteAction,
    options.activeTrainingSession,
  );
  if (!deck) {
    return { processed: false, reason: 'deck_not_found' };
  }

  const definition =
    String(noteAction.definition ?? '').trim() ||
    String(noteAction.meaning ?? '').trim() ||
    word;
  const example = String(noteAction.example ?? noteAction.exampleSentence ?? '').trim();

  const fields = {
    Front: word,
    Back: example ? `${definition}\n\nExample: ${example}` : definition,
  };

  const languageCode = await resolveUserLanguageCode(strapi, userId);
  const result = await createNoteAndCards(strapi, userId, {
    deckId: deck.id,
    noteType: 'basic',
    fields,
    tags: ['from-speaking', 'auto-created'],
    createReverse: false,
    languageCode,
  });

  if (!isPremium) {
    await updateByNumericId(strapi, 'plugin::users-permissions.user', userId, {
      speaking_auto_notes_count: usedCount + 1,
    });
  }

  return {
    processed: true,
    noteCreated: {
      word,
      deckId: deck.id,
      deckName: deck.name,
      noteId: result.note?.id ?? null,
      remainingFree:
        isPremium ? null : Math.max(0, FREE_AUTO_NOTE_LIMIT - (usedCount + 1)),
    },
  };
}

function formatDeckCatalogBlock(decks) {
  if (!Array.isArray(decks) || !decks.length) {
    return '';
  }
  const lines = decks.map(
    (deck) =>
      `- ${deck.name}${deck.deckSlug ? ` (slug: ${deck.deckSlug})` : ` (id: ${deck.id})`}`,
  );
  return `\nUser decks available for saving notes:\n${lines.join('\n')}\n`;
}

module.exports = {
  FREE_AUTO_NOTE_LIMIT,
  loadUserDeckCatalog,
  processSpeakingNoteAction,
  formatDeckCatalogBlock,
};
