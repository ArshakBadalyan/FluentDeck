'use strict';

const { formatCard, isDue, isAvailableForReview } = require('./flashcard-helpers');
const { cardMatchesFilter } = require('./flashcard-browse-filter');

async function fetchCardsForFilter(strapi, userId, filterQuery = {}) {
  const where = { user: userId };
  if (filterQuery?.sourceDeckId) {
    where.deck = filterQuery.sourceDeckId;
  }

  const cards = await strapi.db.query('api::flashcard.flashcard').findMany({
    where,
    populate: ['deck', 'flashcardNote'],
  });

  const cardIds = cards.map((c) => c.id);
  const reviews =
    cardIds.length
      ? await strapi.db.query('api::card-review-state.card-review-state').findMany({
          where: { user: userId, flashcard: { $in: cardIds } },
        })
      : [];

  const now = new Date();
  const formatted = [];

  for (const card of cards) {
    const st = reviews.find((r) => (r.flashcard?.id ?? r.flashcard) === card.id);
    const formattedCard = formatCard(card, st);
    if (cardMatchesFilter(formattedCard, formattedCard.reviewState, filterQuery, now)) {
      formatted.push({ card, review: st, formatted: formattedCard });
    }
  }

  return { rows: formatted, now };
}

async function filteredDeckStats(strapi, userId, filterQuery) {
  const { rows, now } = await fetchCardsForFilter(strapi, userId, filterQuery);

  let newCount = 0;
  let learningCount = 0;
  let reviewDueCount = 0;

  for (const { review } of rows) {
    if (review && !isAvailableForReview(review, now)) continue;
    if (!review || review.state === 'new') {
      newCount += 1;
      continue;
    }
    if (review.state === 'learning' || review.state === 'relearning') {
      if (isDue(review, now)) learningCount += 1;
      continue;
    }
    if (review.state === 'review' && isDue(review, now)) {
      reviewDueCount += 1;
    }
  }

  return {
    total: rows.length,
    newCount,
    learningCount,
    reviewDueCount,
  };
}

async function filteredReviewQueue(strapi, userId, filterQuery, limit = 20) {
  const { rows, now } = await fetchCardsForFilter(strapi, userId, filterQuery);
  const due = [];
  const newCards = [];

  for (const { formatted, review } of rows) {
    if (review && !isAvailableForReview(review, now)) continue;
    if (!review || review.state === 'new') {
      newCards.push(formatted);
    } else if (isDue(review, now)) {
      due.push(formatted);
    }
  }

  return [...due, ...newCards].slice(0, limit);
}

module.exports = {
  fetchCardsForFilter,
  filteredDeckStats,
  filteredReviewQueue,
};
