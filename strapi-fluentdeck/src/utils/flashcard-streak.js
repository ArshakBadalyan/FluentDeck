'use strict';

async function recordFlashcardReviewStreak(strapi, userId, now = new Date()) {
  const rows = await strapi.db.query('api::user-progress.user-progress').findMany({
    where: { user: userId },
    limit: 1,
  });

  let progress = rows[0];
  if (!progress) {
    progress = await strapi.db.query('api::user-progress.user-progress').create({
      data: {
        user: userId,
        currentLevel: 'B1',
        flashcardReviewStreakDays: 1,
        lastFlashcardReviewAt: now,
      },
    });
    return progress.flashcardReviewStreakDays ?? 1;
  }

  const lastRaw = progress.lastFlashcardReviewAt ?? progress.last_flashcard_review_at;
  const last = lastRaw ? new Date(lastRaw) : null;
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const lastDay = last
    ? new Date(last.getFullYear(), last.getMonth(), last.getDate())
    : null;

  let streak = progress.flashcardReviewStreakDays ?? progress.flashcard_review_streak_days ?? 0;

  if (!lastDay) {
    streak = 1;
  } else {
    const dayGap = Math.round((today - lastDay) / (24 * 60 * 60 * 1000));
    if (dayGap === 0) {
      streak = streak === 0 ? 1 : streak;
    } else if (dayGap === 1) {
      streak += 1;
    } else {
      streak = 1;
    }
  }

  await strapi.db.query('api::user-progress.user-progress').update({
    where: { id: progress.id },
    data: {
      flashcardReviewStreakDays: streak,
      lastFlashcardReviewAt: now,
    },
  });

  return streak;
}

async function getFlashcardReviewStreak(strapi, userId) {
  const rows = await strapi.db.query('api::user-progress.user-progress').findMany({
    where: { user: userId },
    limit: 1,
  });
  const progress = rows[0];
  if (!progress) return 0;
  return progress.flashcardReviewStreakDays ?? progress.flashcard_review_streak_days ?? 0;
}

module.exports = {
  recordFlashcardReviewStreak,
  getFlashcardReviewStreak,
};
