'use strict';

const { generateCardsFromNote, formatNote } = require('./flashcard-note-types');
const { normalizePracticeLanguage } = require('./practice-languages');
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

async function syncCardsForNote(strapi, userId, noteRow, { preserveReviewState = true, deckId = null, languageCode } = {}) {
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
      languageCode: normalizePracticeLanguage(
        languageCode ?? noteRow.languageCode ?? noteRow.language_code ?? 'en',
      ),
      occlusionData: spec.occlusionData ?? null,
      example: spec.example ?? null,
    };
    const noteFields = noteRow.fields ?? {};
    if (Object.prototype.hasOwnProperty.call(noteFields, 'Translation')) {
      cardData.translation = String(noteFields.Translation ?? '').trim() || null;
    }

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
    languageCode = 'en',
    source = 'deck',
    inMyNotes = false,
    cefrLevel = null,
    topic = null,
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
      source,
      inMyNotes: !!inMyNotes,
      languageCode: normalizePracticeLanguage(languageCode),
      cefrLevel: cefrLevel || null,
      topic: topic || null,
    },
  });

  const cards = await syncCardsForNote(strapi, userId, note, {
    preserveReviewState: false,
    deckId,
    languageCode,
  });
  return { note: formatNote({ ...note, deck: deckId }, cards), cards };
}

/**
 * Loads a note owned by [userId]. Also claims an ownerless note that one of
 * the user's own cards points to — an old startup migration created such
 * notes, which made mark/edit fail with "Note not found".
 */
async function findOwnedNote(strapi, userId, noteId, { populate } = {}) {
  if (!noteId) return null;
  const query = strapi.db.query('api::flashcard-note.flashcard-note');
  const note = await query.findOne({
    where: { id: noteId, user: userId },
    ...(populate ? { populate } : {}),
  });
  if (note) return note;

  const orphan = await query.findOne({ where: { id: noteId }, populate: ['user'] });
  if (!orphan || orphan.user) return null;
  const ownCard = await strapi.db.query('api::flashcard.flashcard').findOne({
    where: { flashcardNote: noteId, user: userId },
    populate: ['deck'],
  });
  if (!ownCard) return null;

  await query.update({
    where: { id: noteId },
    data: {
      user: userId,
      ...(ownCard.deck?.id ? { deck: ownCard.deck.id } : {}),
    },
  });
  return query.findOne({
    where: { id: noteId, user: userId },
    ...(populate ? { populate } : {}),
  });
}

const BASIC_NOTE_TYPES = new Set([
  'basic',
  'basic_reversed',
  'basic_optional_reversed',
  'basic_type_answer',
]);

async function updateNoteAndCards(strapi, userId, noteId, payload) {
  // Deck must be loaded: card sync needs it, and a mark-only update sends none.
  const existing = await findOwnedNote(strapi, userId, noteId, { populate: ['deck'] });
  if (!existing) throw Object.assign(new Error('Note not found'), { status: 404 });

  const data = {};
  if (payload.noteType != null) data.noteType = payload.noteType;
  if (payload.fields != null) data.fields = payload.fields;
  if (payload.tags != null) data.tags = Array.isArray(payload.tags) ? payload.tags : [];
  if (payload.createReverse !== undefined) data.createReverse = !!payload.createReverse;
  if (payload.mediaUrl !== undefined) data.mediaUrl = payload.mediaUrl;
  if (payload.deckId != null) data.deck = payload.deckId;
  if (payload.marked !== undefined) data.marked = !!payload.marked;
  if (payload.source != null) data.source = payload.source;
  if (payload.inMyNotes !== undefined) data.inMyNotes = !!payload.inMyNotes;
  if (payload.languageCode != null) {
    data.languageCode = normalizePracticeLanguage(payload.languageCode);
  }
  if (payload.cefrLevel !== undefined) data.cefrLevel = payload.cefrLevel || null;
  if (payload.topic !== undefined) data.topic = payload.topic || null;

  // Validate/generate against the new type+fields BEFORE writing anything —
  // e.g. switching to Cloze without a `{{c1::...}}` deletion in the text
  // throws here. Persisting `data.noteType` first and validating after (as
  // this used to) left the note stuck claiming the new type in the DB while
  // its cards were never regenerated, since the throw happened after the
  // write: the note and its cards silently fell out of sync with no way to
  // recover except changing the type again.
  const preview = { ...existing, ...data };
  await generateCardsForNote(strapi, userId, {
    noteType: preview.noteType ?? preview.note_type,
    fields: preview.fields ?? {},
    createReverse: preview.createReverse ?? preview.create_reverse ?? false,
  });

  const note = await strapi.db.query('api::flashcard-note.flashcard-note').update({
    where: { id: noteId },
    data,
  });

  const merged = { ...existing, ...note, ...data };
  const cards = await syncCardsForNote(strapi, userId, merged, {
    preserveReviewState: true,
    deckId: merged.deck?.id ?? merged.deck ?? payload.deckId ?? null,
  });
  return { note: formatNote(merged, cards), cards };
}

async function deleteNoteAndCards(strapi, userId, noteId) {
  const existing = await findOwnedNote(strapi, userId, noteId);
  if (!existing) throw Object.assign(new Error('Note not found'), { status: 404 });

  await deleteCardsForNote(strapi, userId, noteId);
  await strapi.db.query('api::flashcard-note.flashcard-note').delete({ where: { id: noteId } });
  return { ok: true };
}

async function ensureCardHasNote(strapi, userId, card) {
  const existingId = card.flashcardNote?.id ?? card.flashcard_note ?? card.flashcardNote;
  if (existingId) {
    const note = await findOwnedNote(strapi, userId, existingId);
    if (note) return existingId;

    // Stale link: card points at a deleted/missing note — clear and recreate.
    await strapi.db.query('api::flashcard.flashcard').update({
      where: { id: card.id },
      data: { flashcardNote: null },
    });
  }

  const deckId = card.deck?.id ?? card.deck;
  if (!deckId) {
    throw Object.assign(new Error('Card has no deck'), { status: 400 });
  }

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
      mediaUrl: card.mediaUrl ?? card.media_url ?? null,
      deck: deckId,
      user: userId,
      languageCode: card.languageCode ?? card.language_code ?? 'en',
    },
  });

  await strapi.db.query('api::flashcard.flashcard').update({
    where: { id: card.id },
    data: {
      flashcardNote: note.id,
      templateName: card.templateName ?? card.template_name ?? 'Card 1',
      templateOrdinal: card.templateOrdinal ?? card.template_ordinal ?? 0,
    },
  });

  return note.id;
}

async function migrateLegacyCardsToNotes(strapi) {
  let cards;
  try {
    // Relations must be populated: without them every card looks unmigrated,
    // and each boot re-linked all cards to new ownerless notes.
    cards = await strapi.db.query('api::flashcard.flashcard').findMany({
      where: { flashcardNote: { id: { $null: true } } },
      populate: ['flashcardNote', 'user', 'deck'],
      limit: 500,
    });
  } catch (_) {
    return { migrated: 0 };
  }

  const unmigrated = cards.filter(
    (c) => !(c.flashcardNote ?? c.flashcard_note) && (c.user?.id ?? c.user),
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
  BASIC_NOTE_TYPES,
  createNoteAndCards,
  findOwnedNote,
  updateNoteAndCards,
  deleteNoteAndCards,
  syncCardsForNote,
  ensureCardHasNote,
  migrateLegacyCardsToNotes,
  repairCardsDeckFromNotes,
};
