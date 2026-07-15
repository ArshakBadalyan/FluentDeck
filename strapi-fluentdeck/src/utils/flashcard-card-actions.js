'use strict';

const {
  formatCard,
  formatReviewState,
  ensureReviewState,
  applySm2Rating,
} = require('./flashcard-helpers');
const { formatNote } = require('./flashcard-note-types');
const { initialReviewState } = require('./sm2');
const { normalizeDeckOptions, reviewStateSnapshot } = require('./flashcard-review-actions');
const { recordReviewLog } = require('./flashcard-review-log');

async function loadCard(strapi, userId, cardId) {
  const card = await strapi.db.query('api::flashcard.flashcard').findOne({
    where: { id: cardId, user: userId },
    populate: ['deck', 'flashcardNote'],
  });
  if (!card) throw Object.assign(new Error('Card not found'), { status: 404 });
  return card;
}

async function getCardInfo(strapi, userId, cardId) {
  const card = await loadCard(strapi, userId, cardId);
  const noteId = card.flashcardNote?.id ?? card.flashcard_note ?? card.flashcardNote;

  let note = null;
  let siblingCards = [];

  if (noteId) {
    note = await strapi.db.query('api::flashcard-note.flashcard-note').findOne({
      where: { id: noteId, user: userId },
      populate: ['deck'],
    });
    const siblings = await strapi.db.query('api::flashcard.flashcard').findMany({
      where: { flashcardNote: noteId, user: userId },
      orderBy: { templateOrdinal: 'asc' },
    });
    const siblingIds = siblings.map((c) => c.id);
    const reviews =
      siblingIds.length
        ? await strapi.db.query('api::card-review-state.card-review-state').findMany({
            where: { user: userId, flashcard: { $in: siblingIds } },
          })
        : [];
    siblingCards = siblings.map((c) => {
      const st = reviews.find((r) => (r.flashcard?.id ?? r.flashcard) === c.id);
      return formatCard(c, st);
    });
  }

  const review = await ensureReviewState(strapi, userId, cardId);
  const formatted = formatCard(card, review);

  return {
    card: formatted,
    note: note ? formatNote(note, siblingCards) : null,
    siblingCards,
    position: {
      templateOrdinal: card.templateOrdinal ?? 0,
      templateName: card.templateName ?? 'Card 1',
      siblingCount: siblingCards.length,
    },
  };
}

async function setCardDue(strapi, userId, cardId, dueAtRaw) {
  const card = await loadCard(strapi, userId, cardId);
  const dueAt = new Date(String(dueAtRaw));
  if (Number.isNaN(dueAt.getTime())) {
    throw Object.assign(new Error('Invalid dueAt'), { status: 400 });
  }

  const review = await ensureReviewState(strapi, userId, cardId);
  const now = new Date();
  const data = {
    dueAt,
    lastReviewedAt: review.lastReviewedAt ?? review.last_reviewed_at ?? now,
  };

  if (review.state === 'new') {
    data.state = dueAt.getTime() <= now.getTime() ? 'learning' : 'new';
    if (data.state === 'learning') {
      data.learningStep = review.learningStep ?? 0;
    }
  }

  const updated = await strapi.db.query('api::card-review-state.card-review-state').update({
    where: { id: review.id },
    data,
  });

  return formatCard(card, updated);
}

async function resetCardProgress(strapi, userId, cardId) {
  const card = await loadCard(strapi, userId, cardId);
  const review = await ensureReviewState(strapi, userId, cardId);
  const fresh = initialReviewState();

  const updated = await strapi.db.query('api::card-review-state.card-review-state').update({
    where: { id: review.id },
    data: {
      ...fresh,
      dueAt: fresh.dueAt,
      suspended: false,
      buriedUntil: null,
    },
  });

  return formatCard(card, updated);
}

async function gradeCardNow(strapi, userId, cardId, rating) {
  const card = await loadCard(strapi, userId, cardId);
  const review = await ensureReviewState(strapi, userId, cardId);
  const now = new Date();
  const intervalBefore = review.intervalDays ?? review.interval_days ?? 0;
  const stateBefore = review.state ?? 'new';
  const undoSnapshot = reviewStateSnapshot(review);

  const deckRow = card.deck?.id
    ? await strapi.db.query('api::flashcard-deck.flashcard-deck').findOne({
        where: { id: card.deck?.id ?? card.deck, user: userId },
      })
    : null;
  const deckOpts = normalizeDeckOptions(deckRow?.deckOptions ?? deckRow?.deck_options);

  const next = applySm2Rating(review, rating, now, deckOpts);
  if (stateBefore === 'new' && !next.firstStudiedAt) {
    next.firstStudiedAt = now;
  }

  const updated = await strapi.db.query('api::card-review-state.card-review-state').update({
    where: { id: review.id },
    data: next,
  });

  await recordReviewLog(strapi, userId, {
    flashcardId: cardId,
    deckId: card.deck?.id ?? card.deck,
    rating,
    durationMs: 0,
    intervalBefore,
    intervalAfter: updated.intervalDays ?? next.intervalDays ?? 0,
    stateBefore,
    stateAfter: updated.state ?? next.state,
    reviewedAt: now,
    undoSnapshot,
  });

  return formatCard(card, updated);
}

async function repositionCard(strapi, userId, cardId, direction) {
  const card = await loadCard(strapi, userId, cardId);
  const { ensureCardHasNote } = require('./flashcard-note-sync');
  const noteId = await ensureCardHasNote(strapi, userId, card);
  if (!noteId) {
    throw Object.assign(new Error('Card has no linked note to reposition'), { status: 400 });
  }

  const siblings = await strapi.db.query('api::flashcard.flashcard').findMany({
    where: { flashcardNote: noteId, user: userId },
    orderBy: { templateOrdinal: 'asc' },
  });
  if (siblings.length < 2) {
    throw Object.assign(new Error('Note has only one card'), { status: 400 });
  }

  const idx = siblings.findIndex((c) => c.id === cardId);
  if (idx < 0) throw Object.assign(new Error('Card not found in note'), { status: 404 });

  const targetIdx = direction === 'down' ? idx + 1 : idx - 1;
  if (targetIdx < 0 || targetIdx >= siblings.length) {
    throw Object.assign(new Error('Already at edge of note card order'), { status: 400 });
  }

  const current = siblings[idx];
  const swap = siblings[targetIdx];
  const currentOrd = current.templateOrdinal ?? idx;
  const swapOrd = swap.templateOrdinal ?? targetIdx;

  await strapi.db.query('api::flashcard.flashcard').update({
    where: { id: current.id },
    data: { templateOrdinal: swapOrd },
  });
  await strapi.db.query('api::flashcard.flashcard').update({
    where: { id: swap.id },
    data: { templateOrdinal: currentOrd },
  });

  const review = await ensureReviewState(strapi, userId, cardId);
  return formatCard(
    { ...current, templateOrdinal: swapOrd },
    review,
  );
}

function exportCardJson(card, note) {
  return {
    format: 'english-app-flashcard-v1',
    exportedAt: new Date().toISOString(),
    card,
    note,
  };
}

module.exports = {
  getCardInfo,
  setCardDue,
  resetCardProgress,
  gradeCardNow,
  repositionCard,
  exportCardJson,
};
