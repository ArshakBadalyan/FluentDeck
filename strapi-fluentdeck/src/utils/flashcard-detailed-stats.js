'use strict';

const { isAvailableForReview } = require('./flashcard-helpers');

function dayKey(date) {
  const d = new Date(date);
  return d.toISOString().slice(0, 10);
}

function addDays(date, days) {
  const d = new Date(date);
  d.setDate(d.getDate() + days);
  return d;
}

async function buildDetailedStats(strapi, userId, { deckId = null, range = '12m' } = {}) {
  const now = new Date();
  const rangeStart =
    range === 'all'
      ? new Date(0)
      : addDays(now, -365);

  const todayStart = new Date(now);
  todayStart.setHours(0, 0, 0, 0);

  const cardWhere = { user: userId };
  if (deckId) cardWhere.deck = deckId;

  const cards = await strapi.db.query('api::flashcard.flashcard').findMany({
    where: cardWhere,
  });
  const cardIds = cards.map((c) => c.id);

  const states =
    cardIds.length
      ? await strapi.db.query('api::card-review-state.card-review-state').findMany({
          where: { user: userId, flashcard: { $in: cardIds } },
        })
      : [];

  const counts = {
    new: 0,
    learning: 0,
    review: 0,
    suspended: 0,
    buried: 0,
  };

  for (const card of cards) {
    const st = states.find((s) => (s.flashcard?.id ?? s.flashcard) === card.id);
    if (!st || st.state === 'new') {
      counts.new += 1;
      continue;
    }
    if (st.suspended) {
      counts.suspended += 1;
      continue;
    }
    const buried = st.buriedUntil ?? st.buried_until;
    if (buried && new Date(buried).getTime() > now.getTime()) {
      counts.buried += 1;
      continue;
    }
    if (st.state === 'learning' || st.state === 'relearning') {
      counts.learning += 1;
      continue;
    }
    counts.review += 1;
  }

  let logs = [];
  try {
    const logWhere = {
      user: userId,
      reviewedAt: { $gte: rangeStart },
    };
    if (deckId) logWhere.deck = deckId;

    logs = await strapi.db.query('api::card-review-log.card-review-log').findMany({
      where: logWhere,
      orderBy: { reviewedAt: 'desc' },
      limit: 10000,
      populate: ['flashcard', 'deck'],
    });
  } catch (_) {
    logs = [];
  }

  const todayLogs = logs.filter((l) => new Date(l.reviewedAt ?? l.reviewed_at) >= todayStart);
  const todayDurationMs = todayLogs.reduce((sum, l) => sum + (l.durationMs ?? 0), 0);

  const reviewsByDay = {};
  const addedByDay = {};
  const buttonCounts = { again: 0, hard: 0, good: 0, easy: 0 };

  for (const log of logs) {
    const key = dayKey(log.reviewedAt ?? log.reviewed_at);
    reviewsByDay[key] = (reviewsByDay[key] ?? 0) + 1;
    const rating = log.rating;
    if (buttonCounts[rating] != null) buttonCounts[rating] += 1;
  }

  for (const st of states) {
    const studied = st.firstStudiedAt ?? st.first_studied_at;
    if (!studied) continue;
    const d = new Date(studied);
    if (d < rangeStart) continue;
    const key = dayKey(d);
    addedByDay[key] = (addedByDay[key] ?? 0) + 1;
  }

  const futureDueByDay = {};
  for (let i = 0; i < 30; i += 1) {
    futureDueByDay[dayKey(addDays(now, i))] = 0;
  }

  for (const st of states) {
    if (!isAvailableForReview(st, now)) continue;
    const due = st.dueAt ?? st.due_at;
    if (!due) continue;
    const key = dayKey(due);
    if (futureDueByDay[key] != null) {
      futureDueByDay[key] += 1;
    }
  }

  const calendarDays = {};
  for (let i = 0; i < 365; i += 1) {
    const key = dayKey(addDays(now, -i));
    calendarDays[key] = reviewsByDay[key] ?? 0;
  }

  const reviewsSeries = Object.entries(reviewsByDay)
    .sort(([a], [b]) => a.localeCompare(b))
    .slice(-90)
    .map(([date, count]) => ({ date, count }));

  const addedSeries = Object.entries(addedByDay)
    .sort(([a], [b]) => a.localeCompare(b))
    .slice(-90)
    .map(([date, count]) => ({ date, count }));

  const futureDueSeries = Object.entries(futureDueByDay).map(([date, count]) => ({
    date,
    count,
  }));

  const easeBuckets = { low: 0, mid: 0, high: 0 };
  const intervalBuckets = { day1: 0, week1: 0, month1: 0, beyond: 0 };
  let youngReviews = 0;
  let youngCorrect = 0;
  let matureReviews = 0;
  let matureCorrect = 0;
  const hourly = Array.from({ length: 24 }, (_, h) => ({ hour: h, count: 0 }));

  for (const st of states) {
    const ease = st.easeFactor ?? st.ease_factor ?? 2.5;
    if (ease < 2.0) easeBuckets.low += 1;
    else if (ease < 2.5) easeBuckets.mid += 1;
    else easeBuckets.high += 1;

    const ivl = st.intervalDays ?? st.interval_days ?? 0;
    if (ivl <= 1) intervalBuckets.day1 += 1;
    else if (ivl <= 7) intervalBuckets.week1 += 1;
    else if (ivl <= 30) intervalBuckets.month1 += 1;
    else intervalBuckets.beyond += 1;
  }

  for (const log of logs) {
    const h = new Date(log.reviewedAt ?? log.reviewed_at).getHours();
    if (h >= 0 && h < 24) hourly[h].count += 1;

    const ivlBefore = log.intervalBefore ?? log.interval_before ?? 0;
    const isMature = ivlBefore >= 21;
    const correct = log.rating === 'good' || log.rating === 'easy';
    if (isMature) {
      matureReviews += 1;
      if (correct) matureCorrect += 1;
    } else {
      youngReviews += 1;
      if (correct) youngCorrect += 1;
    }
  }

  let deckName = null;
  if (deckId) {
    const deck = await strapi.db.query('api::flashcard-deck.flashcard-deck').findOne({
      where: { id: deckId, user: userId },
      select: ['name'],
    });
    deckName = deck?.name ?? null;
  }

  return {
    scope: deckId ? 'deck' : 'collection',
    deckId,
    deckName,
    range,
    today: {
      reviews: todayLogs.length,
      durationMs: todayDurationMs,
      avgDurationMs:
        todayLogs.length ? Math.round(todayDurationMs / todayLogs.length) : 0,
    },
    cardCounts: counts,
    totalCards: cards.length,
    buttonCounts,
    reviewsByDay: reviewsSeries,
    addedByDay: addedSeries,
    futureDueByDay: futureDueSeries,
    calendar: calendarDays,
    totalReviewsInRange: logs.length,
    easeBuckets,
    intervalBuckets,
    retention: {
      young: youngReviews ? Math.round((youngCorrect / youngReviews) * 100) : null,
      mature: matureReviews ? Math.round((matureCorrect / matureReviews) * 100) : null,
      youngReviews,
      matureReviews,
    },
    hourly,
  };
}

async function listReviewLog(strapi, userId, { deckId = null, limit = 50, offset = 0 } = {}) {
  const where = { user: userId };
  if (deckId) where.deck = deckId;

  let rows = [];
  try {
    rows = await strapi.db.query('api::card-review-log.card-review-log').findMany({
      where,
      orderBy: { reviewedAt: 'desc' },
      limit: Math.min(200, Math.max(1, limit)),
      offset: Math.max(0, offset),
      populate: ['flashcard', 'deck'],
    });
  } catch (_) {
    return { data: [], total: 0 };
  }

  const { formatReviewLogEntry } = require('./flashcard-review-log');
  return {
    data: rows.map((r) => formatReviewLogEntry(r)),
    total: rows.length,
  };
}

module.exports = {
  buildDetailedStats,
  listReviewLog,
};
