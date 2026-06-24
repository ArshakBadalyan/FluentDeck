'use strict';

const { generateCardsFromNote, formatNote } = require('./flashcard-note-types');
const {
  resolveCustomNoteType,
  generateCardsFromCustomType,
} = require('./flashcard-custom-note-types');
const { ensureReviewState, formatCard } = require('./flashcard-helpers');

async function generateCardsForNote(strapi, userId, { noteType, fields, createReverse = false }) {
  const custom = await resolveCustomNoteType(strapi, userId, noteType);
  if (custom) {
    return generateCardsFromCustomType(custom, fields);
  }
  return generateCardsFromNote({ noteType, fields, createReverse });
}

async function deleteCardsForNote(strapi, userId, noteId) {
  const cards = await strapi.db.query('api::flashcard.flashcard').findMany({
    where: { flashcardNote: noteId, user: userId },
  });

  for (const card of cards) {
    const review = await strapi.db.query('api::card-review-state.card-review-state').findOne({
      where: { flashcard: card.id, user: userId },
    });
    if (review) {
      await strapi.db.query('api::card-review-state.card-review-state').delete({
        where: { id: review.id },
      });
    }
    await strapi.db.query('api::flashcard.flashcard').delete({ where: { id: card.id } });
  }
}

async function syncCardsForNote(strapi, userId, noteRow, { preserveReviewState = true, deckId = null } = {}) {
  const noteId = noteRow.id;
  const resolvedDeckId =
    deckId ?? noteRow.deck?.id ?? noteRow.deck ?? null;
  if (!resolvedDeckId) {
    throw Object.assign(new Error('Deck is required to sync cards for a note'), { status: 400 });
  }
  const existingCards = await strapi.db.query('api::flashcard.flashcard').findMany({
    where: { flashcardNote: noteId, user: userId },
    orderBy: { templateOrdinal: 'asc' },
  });

  const generated = await generateCardsForNote(strapi, userId, {
    noteType: noteRow.noteType ?? noteRow.note_type,
    fields: noteRow.fields ?? {},
    createReverse: noteRow.createReverse ?? noteRow.create_reverse ?? false,
  });

  const results = [];
  const keptCardIds = new Set();

  for (const spec of generated) {
    const existing = existingCards.find((c) => c.templateOrdinal === spec.templateOrdinal);

    const cardData = {
      front: spec.front,
      back: spec.back,
      cardType: spec.cardType,
      clozeText: spec.clozeText,
      tags: noteRow.tags ?? [],
      mediaUrl: noteRow.mediaUrl ?? noteRow.media_url ?? null,
      templateName: spec.templateName,
      templateOrdinal: spec.templateOrdinal,
      clozeIndex: spec.clozeIndex,
      flashcardNote: noteId,
      deck: resolvedDeckId,
      user: userId,
      occlusionData: spec.occlusionData ?? null,
    };

    let card;
    if (existing && preserveReviewState) {
      card = await strapi.db.query('api::flashcard.flashcard').update({
        where: { id: existing.id },
        data: cardData,
      });
      keptCardIds.add(existing.id);
    } else {
      card = await strapi.db.query('api::flashcard.flashcard').create({ data: cardData });
      await ensureReviewState(strapi, userId, card.id);
      keptCardIds.add(card.id);
    }

    const review = await ensureReviewState(strapi, userId, card.id);
    results.push(
      formatCard({ ...card, deck: resolvedDeckId, flashcardNote: noteId }, review),
    );
  }

  for (const card of existingCards) {
    if (keptCardIds.has(card.id)) continue;
    const review = await strapi.db.query('api::card-review-state.card-review-state').findOne({
      where: { flashcard: card.id, user: userId },
    });
    if (review) {
      await strapi.db.query('api::card-review-state.card-review-state').delete({
        where: { id: review.id },
      });
    }
    await strapi.db.query('api::flashcard.flashcard').delete({ where: { id: card.id } });
  }

  return results;
}

async function createNoteAndCards(strapi, userId, payload) {
  const {
    deckId,
    noteType = 'basic',
    fields,
    tags,
    createReverse = false,
    mediaUrl,
    userNoteId,
  } = payload;

  const deck = await strapi.db.query('api::flashcard-deck.flashcard-deck').findOne({
    where: { id: deckId, user: userId },
  });
  if (!deck) throw Object.assign(new Error('Deck not found'), { status: 404 });

  await generateCardsForNote(strapi, userId, { noteType, fields, createReverse });

  const note = await strapi.db.query('api::flashcard-note.flashcard-note').create({
    data: {
      noteType,
      fields: fields ?? {},
      tags: Array.isArray(tags) ? tags : [],
      marked: false,
      createReverse: !!createReverse,
      mediaUrl: mediaUrl ?? null,
      deck: deckId,
      user: userId,
      ...(userNoteId ? { userNote: userNoteId } : {}),
    },
  });

  const cards = await syncCardsForNote(strapi, userId, note, {
    preserveReviewState: false,
    deckId,
  });
  return { note: formatNote({ ...note, deck: deckId }, cards), cards };
}

async function updateNoteAndCards(strapi, userId, noteId, payload) {
  const existing = await strapi.db.query('api::flashcard-note.flashcard-note').findOne({
    where: { id: noteId, user: userId },
  });
  if (!existing) throw Object.assign(new Error('Note not found'), { status: 404 });

  const data = {};
  if (payload.noteType != null) data.noteType = payload.noteType;
  if (payload.fields != null) data.fields = payload.fields;
  if (payload.tags != null) data.tags = Array.isArray(payload.tags) ? payload.tags : [];
  if (payload.createReverse !== undefined) data.createReverse = !!payload.createReverse;
  if (payload.mediaUrl !== undefined) data.mediaUrl = payload.mediaUrl;
  if (payload.deckId != null) data.deck = payload.deckId;
  if (payload.marked !== undefined) data.marked = !!payload.marked;

  const note = await strapi.db.query('api::flashcard-note.flashcard-note').update({
    where: { id: noteId },
    data,
  });

  const merged = { ...existing, ...note, ...data };
  await generateCardsForNote(strapi, userId, {
    noteType: merged.noteType ?? merged.note_type,
    fields: merged.fields ?? {},
    createReverse: merged.createReverse ?? merged.create_reverse ?? false,
  });

  const cards = await syncCardsForNote(strapi, userId, merged, {
    preserveReviewState: true,
    deckId: merged.deck?.id ?? merged.deck ?? payload.deckId ?? null,
  });
  return { note: formatNote(merged, cards), cards };
}

async function deleteNoteAndCards(strapi, userId, noteId) {
  const existing = await strapi.db.query('api::flashcard-note.flashcard-note').findOne({
    where: { id: noteId, user: userId },
  });
  if (!existing) throw Object.assign(new Error('Note not found'), { status: 404 });

  await deleteCardsForNote(strapi, userId, noteId);
  await strapi.db.query('api::flashcard-note.flashcard-note').delete({ where: { id: noteId } });
  return { ok: true };
}

async function migrateLegacyCardsToNotes(strapi) {
  let cards;
  try {
    cards = await strapi.db.query('api::flashcard.flashcard').findMany({ limit: 500 });
  } catch (_) {
    return { migrated: 0 };
  }

  const unmigrated = cards.filter(
    (c) => !(c.flashcardNote ?? c.flashcard_note),
  );
  if (!unmigrated.length) return { migrated: 0 };

  let migrated = 0;
  for (const card of unmigrated) {
    const noteType = card.cardType === 'cloze' ? 'cloze' : 'basic';
    const fields =
      noteType === 'cloze'
        ? { Text: card.clozeText || card.front, Back: card.back }
        : { Front: card.front, Back: card.back };

    const note = await strapi.db.query('api::flashcard-note.flashcard-note').create({
      data: {
        noteType,
        fields,
        tags: card.tags ?? [],
        marked: false,
        createReverse: false,
        mediaUrl: card.mediaUrl ?? null,
        deck: card.deck?.id ?? card.deck,
        user: card.user?.id ?? card.user,
        ...(card.userNote ? { userNote: card.userNote?.id ?? card.userNote } : {}),
      },
    });

    await strapi.db.query('api::flashcard.flashcard').update({
      where: { id: card.id },
      data: {
        flashcardNote: note.id,
        templateName: 'Card 1',
        templateOrdinal: 0,
      },
    });
    migrated += 1;
  }

  return { migrated };
}

/** Fix cards missing or mismatched deck relation (legacy sync bug). */
async function repairCardsDeckFromNotes(strapi, userId, deckId) {
  const notes = await strapi.db.query('api::flashcard-note.flashcard-note').findMany({
    where: { user: userId, deck: deckId },
    select: ['id'],
  });
  if (!notes.length) return 0;

  const noteIds = notes.map((n) => n.id);
  const cards = await strapi.db.query('api::flashcard.flashcard').findMany({
    where: { user: userId, flashcardNote: { $in: noteIds } },
  });

  let fixed = 0;
  for (const card of cards) {
    const cardDeck = card.deck?.id ?? card.deck;
    if (cardDeck !== deckId) {
      await strapi.db.query('api::flashcard.flashcard').update({
        where: { id: card.id },
        data: { deck: deckId },
      });
      fixed += 1;
    }
  }
  return fixed;
}

module.exports = {
  createNoteAndCards,
  updateNoteAndCards,
  deleteNoteAndCards,
  syncCardsForNote,
  migrateLegacyCardsToNotes,
  repairCardsDeckFromNotes,
};
