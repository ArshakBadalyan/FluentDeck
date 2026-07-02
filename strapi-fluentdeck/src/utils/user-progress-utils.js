'use strict';

function truncateLabel(value, max = 40) {
  const trimmed = String(value ?? '').trim();
  if (trimmed.length <= max) return trimmed;
  return `${trimmed.slice(0, max)}…`;
}

function weakAreaLabel(correction) {
  const explanation = String(correction?.explanation ?? '').trim();
  if (explanation) return truncateLabel(explanation);
  return String(correction?.errorType ?? correction?.error_type ?? 'grammar').trim() || 'grammar';
}

function mergeWeakAreas(existing, corrections) {
  const base = Array.isArray(existing) ? existing : [];
  if (!Array.isArray(corrections) || corrections.length === 0) {
    return base;
  }

  const counts = new Map();
  for (const area of base) {
    const errorType = area.errorType ?? area.error_type ?? 'grammar';
    const label = area.label ?? '';
    counts.set(`${errorType}::${label}`, {
      errorType,
      label,
      count: Number(area.count ?? 0),
    });
  }

  for (const correction of corrections) {
    const errorType =
      String(correction?.errorType ?? correction?.error_type ?? 'grammar').trim() || 'grammar';
    const label = weakAreaLabel(correction);
    const key = `${errorType}::${label}`;
    const prior = counts.get(key);
    counts.set(key, {
      errorType,
      label,
      count: (prior?.count ?? 0) + 1,
    });
  }

  return [...counts.values()].sort((a, b) => b.count - a.count);
}

async function getOwnedProgress(strapi, userId) {
  if (!userId) return null;
  const rows = await strapi.db.query('api::user-progress.user-progress').findMany({
    where: { user: userId },
    limit: 1,
  });
  return rows[0] ?? null;
}

async function getOrCreateUserProgress(strapi, userId) {
  const existing = await getOwnedProgress(strapi, userId);
  if (existing) return existing;

  return strapi.db.query('api::user-progress.user-progress').create({
    data: {
      user: userId,
      currentLevel: 'B1',
      weakAreas: [],
      streakDays: 0,
      totalSpeakingMinutes: 0,
      perfectSentencesCount: 0,
      uniqueWordsUsed: 0,
      spokenWordBank: [],
      completedExercises: [],
    },
  });
}

async function updateOwnedProgress(strapi, userId, progressId, data) {
  const numericId = Number(progressId);
  if (!Number.isFinite(numericId)) return null;

  const row = await strapi.db.query('api::user-progress.user-progress').findOne({
    where: { id: numericId, user: userId },
  });
  if (!row) return null;

  const updated = await strapi.db.query('api::user-progress.user-progress').update({
    where: { id: row.id },
    data,
  });

  return updated;
}

function formatProgressResponse(row) {
  if (!row) return null;
  return {
    id: row.id,
    currentLevel: row.currentLevel ?? row.current_level ?? 'B1',
    weakAreas: row.weakAreas ?? row.weak_areas ?? [],
    streakDays: row.streakDays ?? row.streak_days ?? 0,
    totalSpeakingMinutes: row.totalSpeakingMinutes ?? row.total_speaking_minutes ?? 0,
    perfectSentencesCount: row.perfectSentencesCount ?? row.perfect_sentences_count ?? 0,
    uniqueWordsUsed: row.uniqueWordsUsed ?? row.unique_words_used ?? 0,
    lastPracticeAt: row.lastPracticeAt ?? row.last_practice_at ?? null,
    completedExercises: row.completedExercises ?? row.completed_exercises ?? [],
    flashcardReviewStreakDays:
      row.flashcardReviewStreakDays ?? row.flashcard_review_streak_days ?? 0,
    lastFlashcardReviewAt: row.lastFlashcardReviewAt ?? row.last_flashcard_review_at ?? null,
    user: row.user?.id ?? row.user ?? null,
  };
}

module.exports = {
  truncateLabel,
  mergeWeakAreas,
  getOwnedProgress,
  getOrCreateUserProgress,
  updateOwnedProgress,
  formatProgressResponse,
};
