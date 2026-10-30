'use strict';

const CEFR_LEVELS = new Set(['A1', 'A2', 'B1', 'B2', 'C1', 'C2']);

/** "b1" → "B1"; anything that isn't a CEFR level → null. */
function normalizeCefrLevel(value) {
  const level = String(value ?? '').trim().toUpperCase();
  return CEFR_LEVELS.has(level) ? level : null;
}

/** Up to 8 distinct, non-empty words or short phrases (≤ 40 chars each). */
function sanitizeNewWords(value) {
  if (!Array.isArray(value)) return [];
  const seen = new Set();
  const words = [];
  for (const item of value) {
    const word = String(item ?? '').replace(/\s+/g, ' ').trim();
    if (!word || word.length > 40) continue;
    const key = word.toLowerCase();
    if (seen.has(key)) continue;
    seen.add(key);
    words.push(word);
    if (words.length === 8) break;
  }
  return words;
}

function formatSession(row) {
  return {
    id: row.id,
    mode: row.mode,
    referenceKey: row.referenceKey ?? row.reference_key ?? null,
    title: row.title,
    score: row.score,
    fluencyScore: row.fluencyScore ?? row.fluency_score ?? null,
    grammarScore: row.grammarScore ?? row.grammar_score ?? null,
    vocabularyScore: row.vocabularyScore ?? row.vocabulary_score ?? null,
    feedback: row.feedback ?? '',
    summary: row.summary ?? '',
    durationMinutes: row.durationMinutes ?? row.duration_minutes ?? 0,
    turnCount: row.turnCount ?? row.turn_count ?? 0,
    completedAt: row.completedAt ?? row.completed_at,
    level: normalizeCefrLevel(row.level),
    newWords: sanitizeNewWords(row.newWords ?? row.new_words),
  };
}

function computeSpeakingStreak({ lastPracticeAt, currentStreakDays, now = new Date() }) {
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const lastRaw = lastPracticeAt ? new Date(lastPracticeAt) : null;
  const lastDay = lastRaw
    ? new Date(lastRaw.getFullYear(), lastRaw.getMonth(), lastRaw.getDate())
    : null;

  let streak = currentStreakDays ?? 0;

  if (!lastDay) {
    return 1;
  }

  const dayGap = Math.round((today - lastDay) / (24 * 60 * 60 * 1000));
  if (dayGap === 0) {
    return streak === 0 ? 1 : streak;
  }
  if (dayGap === 1) {
    return streak + 1;
  }
  return 1;
}

async function getOrCreateUserProgress(strapi, userId) {
  const rows = await strapi.db.query('api::user-progress.user-progress').findMany({
    where: { user: userId },
    limit: 1,
  });
  if (rows[0]) return rows[0];

  return strapi.db.query('api::user-progress.user-progress').create({
    data: {
      user: userId,
      currentLevel: 'A1',
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

async function recordSpeakingPractice(strapi, userId, durationMinutes, now = new Date()) {
  const progress = await getOrCreateUserProgress(strapi, userId);
  const addedMinutes = Math.min(Math.max(Number(durationMinutes) || 1, 1), 120);
  // Legacy, speaking-only streak — kept updated for compatibility, but no
  // longer what the app displays (see flashcardReviewStreakDays below).
  const legacyStreakDays = computeSpeakingStreak({
    lastPracticeAt: progress.lastPracticeAt ?? progress.last_practice_at,
    currentStreakDays: progress.streakDays ?? progress.streak_days ?? 0,
    now,
  });
  const totalSpeakingMinutes =
    (progress.totalSpeakingMinutes ?? progress.total_speaking_minutes ?? 0) +
    addedMinutes;

  await strapi.db.query('api::user-progress.user-progress').update({
    where: { id: progress.id },
    data: {
      streakDays: legacyStreakDays,
      totalSpeakingMinutes,
      lastPracticeAt: now,
    },
  });

  // The Profile/Activity hero cards read this one — it's shared with deck
  // reviews and free-chat turns, so a scored speaking session counts toward
  // the same streak instead of its own disconnected counter.
  const { recordFlashcardReviewStreak } = require('./flashcard-streak');
  const streakDays = await recordFlashcardReviewStreak(strapi, userId, now);

  return { streakDays, totalSpeakingMinutes };
}

async function createCompletedSession(strapi, userId, payload) {
  const now = payload.completedAt ? new Date(payload.completedAt) : new Date();
  const score = Math.min(10, Math.max(0, Math.round(Number(payload.score) || 0)));
  // Optional 0-10 skill scores from the session evaluation.
  const subScore = (value) => {
    if (value == null || value === '') return null;
    const n = Number(value);
    return Number.isFinite(n) ? Math.min(10, Math.max(0, Math.round(n))) : null;
  };
  const durationMinutes = Math.min(
    Math.max(Number(payload.durationMinutes) || 1, 1),
    120,
  );

  const session = await strapi.db.query('api::speaking-session.speaking-session').create({
    data: {
      mode: payload.mode,
      referenceKey: payload.referenceKey ?? null,
      title: payload.title,
      score,
      fluencyScore: subScore(payload.fluencyScore),
      grammarScore: subScore(payload.grammarScore),
      vocabularyScore: subScore(payload.vocabularyScore),
      feedback: payload.feedback ?? '',
      summary: payload.summary ?? payload.title,
      durationMinutes,
      turnCount: Math.max(0, Number(payload.turnCount) || 0),
      completedAt: now,
      level: normalizeCefrLevel(payload.level),
      newWords: sanitizeNewWords(payload.newWords),
      user: userId,
    },
  });

  const progress = await recordSpeakingPractice(strapi, userId, durationMinutes, now);

  return { session: formatSession(session), progress };
}

async function listRecentSessions(strapi, userId, limit = 10) {
  const rows = await strapi.db.query('api::speaking-session.speaking-session').findMany({
    where: { user: userId },
    orderBy: { completedAt: 'desc' },
    limit: Math.min(Math.max(Number(limit) || 10, 1), 50),
  });
  return rows.map(formatSession);
}

async function bestScoresByReference(strapi, userId) {
  const rows = await strapi.db.query('api::speaking-session.speaking-session').findMany({
    where: { user: userId },
    select: ['referenceKey', 'reference_key', 'score'],
  });

  const best = {};
  for (const row of rows) {
    const key = row.referenceKey ?? row.reference_key;
    if (!key) continue;
    const score = Number(row.score) || 0;
    if (best[key] == null || score > best[key]) {
      best[key] = score;
    }
  }
  return best;
}

module.exports = {
  normalizeCefrLevel,
  sanitizeNewWords,
  formatSession,
  computeSpeakingStreak,
  recordSpeakingPractice,
  createCompletedSession,
  listRecentSessions,
  bestScoresByReference,
};
