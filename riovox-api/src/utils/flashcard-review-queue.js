'use strict';

const { isDue } = require('./sm2');

/**
 * Include review cards due within the learn-ahead window.
 */
function isDueWithLearnAhead(review, now, learnAheadMinutes = 0) {
  if (!review) return false;
  if (review.state === 'new') return false;
  const dueRaw = review.dueAt ?? review.due_at;
  if (!dueRaw) return isDue(review, now);
  const dueMs = new Date(dueRaw).getTime();
  const nowMs = now.getTime();
  if (dueMs <= nowMs) return true;
  if (learnAheadMinutes <= 0) return false;
  return dueMs <= nowMs + learnAheadMinutes * 60 * 1000;
}

function orderReviewQueue(queue, newCardOrder = 'after_reviews') {
  if (!Array.isArray(queue) || queue.length < 2) return queue;

  const due = [];
  const news = [];
  for (const card of queue) {
    if (card.reviewState?.state === 'new') {
      news.push(card);
    } else {
      due.push(card);
    }
  }

  if (newCardOrder === 'before_reviews') {
    return [...news, ...due];
  }
  if (newCardOrder === 'mixed') {
    const mixed = [];
    let i = 0;
    let j = 0;
    while (i < due.length || j < news.length) {
      if (i < due.length) mixed.push(due[i++]);
      if (j < news.length) mixed.push(news[j++]);
    }
    return mixed;
  }
  return [...due, ...news];
}

function parseNewCardOrder(raw) {
  const v = String(raw ?? '').toLowerCase();
  if (v === 'mixed') return 'mixed';
  if (v === 'before_reviews' || v === 'before') return 'before_reviews';
  return 'after_reviews';
}

module.exports = {
  isDueWithLearnAhead,
  orderReviewQueue,
  parseNewCardOrder,
};
