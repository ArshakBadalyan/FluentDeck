'use strict';

async function recordReviewLog(strapi, userId, {
  flashcardId,
  deckId,
  rating,
  durationMs = 0,
  intervalBefore = 0,
  intervalAfter = 0,
  stateBefore,
  stateAfter,
  reviewedAt,
  undoSnapshot = null,
}) {
  try {
    await strapi.db.query('api::card-review-log.card-review-log').create({
      data: {
        user: userId,
        flashcard: flashcardId,
        deck: deckId,
        rating,
        durationMs: Math.max(0, parseInt(String(durationMs), 10) || 0),
        intervalBefore,
        intervalAfter,
        stateBefore: stateBefore ?? null,
        stateAfter: stateAfter ?? null,
        reviewedAt: reviewedAt ?? new Date(),
        undoSnapshot,
      },
    });
  } catch (e) {
    strapi.log.warn(`[review-log] ${e?.message}`);
  }
}

function formatReviewLogEntry(row, cardRow) {
  const card = cardRow ?? row.flashcard;
  return {
    id: row.id,
    flashcardId: card?.id ?? row.flashcard?.id ?? row.flashcard,
    deckId: row.deck?.id ?? row.deck,
    rating: row.rating,
    durationMs: row.durationMs ?? 0,
    intervalBefore: row.intervalBefore ?? 0,
    intervalAfter: row.intervalAfter ?? 0,
    stateBefore: row.stateBefore,
    stateAfter: row.stateAfter,
    reviewedAt: row.reviewedAt ?? row.reviewed_at,
    front: card?.front ?? '',
    cardType: card?.cardType ?? card?.card_type ?? 'basic',
  };
}

module.exports = {
  recordReviewLog,
  formatReviewLogEntry,
};
