'use strict';

const { getSchedulingDefaultsSync } = require('./flashcard-scheduling-defaults');

const DEFAULT_DECK_OPTIONS = {
  newCardsPerDay: 20,
  maxReviewsPerDay: 200,
  learningStepsMinutes: getSchedulingDefaultsSync().learningStepsMinutes,
  graduatingIntervalDays: 1,
  easyIntervalDays: getSchedulingDefaultsSync().easyIntervalDays,
  easyBonus: 1.3,
  lapseStepsMinutes: [10],
  minimumIntervalDays: 1,
  leechThreshold: 8,
};

function normalizeDeckOptions(raw) {
  const schedulingDefaults = getSchedulingDefaultsSync();
  const o = raw && typeof raw === 'object' ? raw : {};
  return {
    newCardsPerDay: parseInt(String(o.newCardsPerDay ?? DEFAULT_DECK_OPTIONS.newCardsPerDay), 10) || 20,
    maxReviewsPerDay: parseInt(String(o.maxReviewsPerDay ?? DEFAULT_DECK_OPTIONS.maxReviewsPerDay), 10) || 200,
    learningStepsMinutes: Array.isArray(o.learningStepsMinutes) && o.learningStepsMinutes.length
      ? o.learningStepsMinutes.map((n) => parseInt(String(n), 10)).filter((n) => n > 0)
      : schedulingDefaults.learningStepsMinutes,
    graduatingIntervalDays:
      parseFloat(String(o.graduatingIntervalDays ?? DEFAULT_DECK_OPTIONS.graduatingIntervalDays)) || 1,
    easyIntervalDays:
      parseFloat(String(o.easyIntervalDays ?? schedulingDefaults.easyIntervalDays)) ||
      schedulingDefaults.easyIntervalDays,
    easyBonus: parseFloat(String(o.easyBonus ?? DEFAULT_DECK_OPTIONS.easyBonus)) || 1.3,
    lapseStepsMinutes: Array.isArray(o.lapseStepsMinutes)
      ? o.lapseStepsMinutes.map((n) => parseInt(String(n), 10)).filter((n) => n > 0)
      : DEFAULT_DECK_OPTIONS.lapseStepsMinutes,
    minimumIntervalDays:
      parseFloat(String(o.minimumIntervalDays ?? DEFAULT_DECK_OPTIONS.minimumIntervalDays)) || 1,
    leechThreshold: parseInt(String(o.leechThreshold ?? DEFAULT_DECK_OPTIONS.leechThreshold), 10) || 8,
  };
}

function reviewStateSnapshot(review) {
  if (!review) return null;
  return {
    state: review.state ?? 'new',
    intervalDays: review.intervalDays ?? review.interval_days ?? 0,
    easeFactor: review.easeFactor ?? review.ease_factor ?? 2.5,
    dueAt: review.dueAt ?? review.due_at ?? null,
    lapses: review.lapses ?? 0,
    repetitions: review.repetitions ?? 0,
    learningStep: review.learningStep ?? review.learning_step ?? 0,
    lastReviewedAt: review.lastReviewedAt ?? review.last_reviewed_at ?? null,
    firstStudiedAt: review.firstStudiedAt ?? review.first_studied_at ?? null,
    suspended: review.suspended === true,
    buriedUntil: review.buriedUntil ?? review.buried_until ?? null,
  };
}

async function maybeAutoSuspendLeech(strapi, userId, cardId, review, threshold) {
  const lapses = review.lapses ?? 0;
  if (lapses < threshold || review.suspended === true) return review;
  return strapi.db.query('api::card-review-state.card-review-state').update({
    where: { id: review.id },
    data: { suspended: true },
  });
}

async function burySiblingCards(strapi, userId, cardId) {
  const card = await strapi.db.query('api::flashcard.flashcard').findOne({
    where: { id: cardId, user: userId },
    populate: ['flashcardNote'],
  });
  if (!card) throw Object.assign(new Error('Card not found'), { status: 404 });

  const noteId = card.flashcardNote?.id ?? card.flashcard_note;
  if (!noteId) return { buried: 0 };

  const siblings = await strapi.db.query('api::flashcard.flashcard').findMany({
    where: { flashcardNote: noteId, user: userId },
  });

  const { endOfLocalDay } = require('./flashcard-helpers');
  const buriedUntil = endOfLocalDay();
  let buried = 0;

  for (const sibling of siblings) {
    if (sibling.id === cardId) continue;
    const review = await strapi.db.query('api::card-review-state.card-review-state').findOne({
      where: { flashcard: sibling.id, user: userId },
    });
    if (!review) continue;
    await strapi.db.query('api::card-review-state.card-review-state').update({
      where: { id: review.id },
      data: { buriedUntil },
    });
    buried += 1;
  }

  return { buried };
}

async function unburyCard(strapi, userId, cardId) {
  const review = await strapi.db.query('api::card-review-state.card-review-state').findOne({
    where: { flashcard: cardId, user: userId },
  });
  if (!review) return null;
  return strapi.db.query('api::card-review-state.card-review-state').update({
    where: { id: review.id },
    data: { buriedUntil: null },
  });
}

async function undoLastReview(strapi, userId) {
  const log = await strapi.db.query('api::card-review-log.card-review-log').findOne({
    where: { user: userId },
    orderBy: { reviewedAt: 'desc' },
    populate: ['flashcard'],
  });
  if (!log) throw Object.assign(new Error('Nothing to undo'), { status: 404 });

  const snapshot = log.undoSnapshot ?? log.undo_snapshot;
  if (!snapshot || typeof snapshot !== 'object') {
    throw Object.assign(new Error('Undo not available for this review'), { status: 400 });
  }

  const cardId = log.flashcard?.id ?? log.flashcard;
  const review = await strapi.db.query('api::card-review-state.card-review-state').findOne({
    where: { flashcard: cardId, user: userId },
  });
  if (!review) throw Object.assign(new Error('Review state not found'), { status: 404 });

  const data = {
    state: snapshot.state ?? 'new',
    intervalDays: snapshot.intervalDays ?? 0,
    easeFactor: snapshot.easeFactor ?? 2.5,
    dueAt: snapshot.dueAt ? new Date(snapshot.dueAt) : null,
    lapses: snapshot.lapses ?? 0,
    repetitions: snapshot.repetitions ?? 0,
    learningStep: snapshot.learningStep ?? 0,
    lastReviewedAt: snapshot.lastReviewedAt ? new Date(snapshot.lastReviewedAt) : null,
    firstStudiedAt: snapshot.firstStudiedAt ? new Date(snapshot.firstStudiedAt) : null,
    suspended: snapshot.suspended === true,
    buriedUntil: snapshot.buriedUntil ? new Date(snapshot.buriedUntil) : null,
  };

  const updated = await strapi.db.query('api::card-review-state.card-review-state').update({
    where: { id: review.id },
    data,
  });

  await strapi.db.query('api::card-review-log.card-review-log').delete({ where: { id: log.id } });

  const card = await strapi.db.query('api::flashcard.flashcard').findOne({
    where: { id: cardId, user: userId },
    populate: ['deck', 'flashcardNote'],
  });

  const { formatCard } = require('./flashcard-helpers');
  return { card: formatCard(card, updated), undoneLogId: log.id };
}

module.exports = {
  DEFAULT_DECK_OPTIONS,
  normalizeDeckOptions,
  reviewStateSnapshot,
  maybeAutoSuspendLeech,
  burySiblingCards,
  unburyCard,
  undoLastReview,
};
