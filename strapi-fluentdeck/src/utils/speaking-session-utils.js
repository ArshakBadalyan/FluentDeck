'use strict';

function formatSession(row) {
  return {
    id: row.id,
    mode: row.mode,
    referenceKey: row.referenceKey ?? row.reference_key ?? null,
    title: row.title,
    score: row.score,
    feedback: row.feedback ?? '',
    summary: row.summary ?? '',
    durationMinutes: row.durationMinutes ?? row.duration_minutes ?? 0,
    turnCount: row.turnCount ?? row.turn_count ?? 0,
    completedAt: row.completedAt ?? row.completed_at,
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
  const streakDays = computeSpeakingStreak({
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
      streakDays,
      totalSpeakingMinutes,
      lastPracticeAt: now,
    },
  });

  return { streakDays, totalSpeakingMinutes };
}

async function createCompletedSession(strapi, userId, payload) {
  const now = payload.completedAt ? new Date(payload.completedAt) : new Date();
  const score = Math.min(10, Math.max(0, Math.round(Number(payload.score) || 0)));
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
      feedback: payload.feedback ?? '',
      summary: payload.summary ?? payload.title,
      durationMinutes,
      turnCount: Math.max(0, Number(payload.turnCount) || 0),
      completedAt: now,
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
  formatSession,
  computeSpeakingStreak,
  recordSpeakingPractice,
  createCompletedSession,
  listRecentSessions,
  bestScoresByReference,
};
