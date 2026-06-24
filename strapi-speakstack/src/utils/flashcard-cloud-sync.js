'use strict';

const { formatDeck, formatCard, formatReviewState } = require('./flashcard-helpers');
const { formatNote } = require('./flashcard-note-types');

const STORE_NAME = 'flashcard-sync';
const FULL_SYNC_AFTER_MS = 7 * 24 * 60 * 60 * 1000;

function getStore(strapi) {
  return strapi.store({ environment: 'plugin', type: 'plugin', name: STORE_NAME });
}

async function getSyncMeta(strapi, userId) {
  const store = getStore(strapi);
  const row = await store.get({ key: `user_${userId}` });
  return row ?? { lastPullAt: null, lastPushAt: null };
}

async function setSyncMeta(strapi, userId, patch) {
  const store = getStore(strapi);
  const prev = await getSyncMeta(strapi, userId);
  await store.set({ key: `user_${userId}`, value: { ...prev, ...patch } });
}

function parseSince(raw) {
  if (!raw) return null;
  const d = new Date(String(raw));
  return Number.isNaN(d.getTime()) ? null : d;
}

function sinceFilter(sinceDate) {
  if (!sinceDate) return {};
  return { updatedAt: { $gt: sinceDate.toISOString() } };
}

async function pullSyncData(strapi, userId, { since = null } = {}) {
  const sinceDate = parseSince(since);
  const meta = await getSyncMeta(strapi, userId);
  const lastPull = parseSince(meta.lastPullAt);
  const forceFull =
    !sinceDate ||
    !lastPull ||
    Date.now() - lastPull.getTime() > FULL_SYNC_AFTER_MS;

  const filter = forceFull ? {} : sinceFilter(sinceDate);

  const decks = await strapi.db.query('api::flashcard-deck.flashcard-deck').findMany({
    where: { user: userId, ...filter },
    populate: ['parentDeck'],
  });

  const notes = await strapi.db.query('api::flashcard-note.flashcard-note').findMany({
    where: { user: userId, ...filter },
    populate: ['deck'],
  });

  const cards = await strapi.db.query('api::flashcard.flashcard').findMany({
    where: { user: userId, ...filter },
    populate: ['deck', 'flashcardNote'],
  });

  const cardIds = cards.map((c) => c.id);
  const reviews =
    cardIds.length
      ? await strapi.db.query('api::card-review-state.card-review-state').findMany({
          where: {
            user: userId,
            flashcard: { $in: cardIds },
            ...(forceFull ? {} : sinceFilter(sinceDate)),
          },
        })
      : [];

  const noteCardsMap = new Map();
  for (const note of notes) {
    const noteCards = cards.filter(
      (c) => (c.flashcardNote?.id ?? c.flashcard_note) === note.id,
    );
    noteCardsMap.set(note.id, noteCards);
  }

  const syncedAt = new Date().toISOString();
  await setSyncMeta(strapi, userId, { lastPullAt: syncedAt });

  return {
    syncedAt,
    incremental: !forceFull,
    serverCursor: syncedAt,
    decks: decks.map((d) => formatDeck(d)),
    notes: notes.map((n) => formatNote(n, noteCardsMap.get(n.id) ?? [])),
    cards: cards.map((c) => {
      const st = reviews.find((r) => (r.flashcard?.id ?? r.flashcard) === c.id);
      return formatCard(c, st);
    }),
    reviewStates: reviews.map((r) => ({
      flashcardId: r.flashcard?.id ?? r.flashcard,
      ...formatReviewState(r),
      updatedAt: r.updatedAt,
    })),
  };
}

module.exports = {
  getSyncMeta,
  setSyncMeta,
  pullSyncData,
};
