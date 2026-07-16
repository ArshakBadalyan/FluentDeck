'use strict';

const CEFR_LEVELS = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

function levelIndex(level) {
  const idx = CEFR_LEVELS.indexOf(String(level ?? '').toUpperCase());
  return idx >= 0 ? idx : 0;
}

function clampLevel(level) {
  const normalized = String(level ?? 'A1').toUpperCase();
  return CEFR_LEVELS.includes(normalized) ? normalized : 'A1';
}

/**
 * Estimate CEFR from speaking turns, accuracy, spoken vocabulary, and deck reviews.
 */
function estimateLevelFromStats(stats = {}) {
  const speakingTurns = Number(stats.speakingTurns ?? 0);
  const perfectSentences = Number(stats.perfectSentences ?? 0);
  const correctionCount = Number(stats.correctionCount ?? 0);
  const uniqueWordsSpoken = Number(stats.uniqueWordsSpoken ?? 0);
  const deckWordsReviewed = Number(stats.deckWordsReviewed ?? 0);

  let score = 0;
  score += Math.min(speakingTurns * 2, 40);
  score += Math.min(uniqueWordsSpoken / 5, 30);
  score += Math.min(deckWordsReviewed / 3, 20);

  const utterances = perfectSentences + correctionCount;
  if (utterances > 3) {
    score += (perfectSentences / utterances) * 20;
  }

  if (score < 8) return 'A1';
  if (score < 22) return 'A2';
  if (score < 40) return 'B1';
  if (score < 58) return 'B2';
  if (score < 78) return 'C1';
  return 'C2';
}

function emptyLanguageEntry(tutorLevel = 'A1') {
  const now = new Date().toISOString();
  return {
    tutorLevel: clampLevel(tutorLevel),
    estimatedLevel: 'A1',
    speakingTurns: 0,
    perfectSentences: 0,
    correctionCount: 0,
    uniqueWordsSpoken: 0,
    deckWordsReviewed: 0,
    firstSelectedAt: now,
    lastActiveAt: now,
    levelHistory: [],
  };
}

function normalizeLanguageLevels(raw) {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) {
    return {};
  }
  const out = {};
  for (const [code, entry] of Object.entries(raw)) {
    if (!entry || typeof entry !== 'object') continue;
    const tutorLevel = clampLevel(entry.tutorLevel ?? entry.tutor_level ?? 'A1');
    const stats = {
      speakingTurns: Number(entry.speakingTurns ?? entry.speaking_turns ?? 0),
      perfectSentences: Number(entry.perfectSentences ?? entry.perfect_sentences ?? 0),
      correctionCount: Number(entry.correctionCount ?? entry.correction_count ?? 0),
      uniqueWordsSpoken: Number(entry.uniqueWordsSpoken ?? entry.unique_words_spoken ?? 0),
      deckWordsReviewed: Number(entry.deckWordsReviewed ?? entry.deck_words_reviewed ?? 0),
    };
    const estimatedLevel = clampLevel(
      entry.estimatedLevel ??
        entry.estimated_level ??
        estimateLevelFromStats(stats),
    );
    out[code] = {
      tutorLevel,
      estimatedLevel,
      ...stats,
      firstSelectedAt:
        entry.firstSelectedAt ?? entry.first_selected_at ?? new Date().toISOString(),
      lastActiveAt: entry.lastActiveAt ?? entry.last_active_at ?? new Date().toISOString(),
      levelHistory: Array.isArray(entry.levelHistory ?? entry.level_history)
        ? (entry.levelHistory ?? entry.level_history).map((row) => ({
            estimatedLevel: clampLevel(row.estimatedLevel ?? row.estimated_level ?? 'A1'),
            recordedAt: row.recordedAt ?? row.recorded_at ?? new Date().toISOString(),
            source: row.source ?? 'analytics',
          }))
        : [],
    };
  }
  return out;
}

function pushLevelHistory(entry, estimatedLevel, source = 'analytics') {
  const history = Array.isArray(entry.levelHistory) ? [...entry.levelHistory] : [];
  const last = history[history.length - 1];
  if (!last || last.estimatedLevel !== estimatedLevel) {
    history.push({
      estimatedLevel,
      recordedAt: new Date().toISOString(),
      source,
    });
  }
  if (history.length > 24) {
    return history.slice(history.length - 24);
  }
  return history;
}

function recomputeEntry(entry) {
  const estimatedLevel = estimateLevelFromStats(entry);
  return {
    ...entry,
    estimatedLevel,
    levelHistory: pushLevelHistory(entry, estimatedLevel),
    lastActiveAt: new Date().toISOString(),
  };
}

async function loadUserLanguageContext(strapi, userId) {
  const { getOrCreateUserProgress } = require('./user-progress-utils');
  const user = await strapi.db.query('plugin::users-permissions.user').findOne({
    where: { id: userId },
    select: ['practice_language', 'english_level'],
  });
  const progress = await getOrCreateUserProgress(strapi, userId);
  const practiceLanguage = String(user?.practice_language ?? 'en').trim() || 'en';
  const tutorLevel = clampLevel(user?.english_level ?? 'A1');
  const languageLevels = normalizeLanguageLevels(
    progress.languageLevels ?? progress.language_levels,
  );
  return { progress, practiceLanguage, tutorLevel, languageLevels };
}

async function persistLanguageLevels(strapi, progressId, languageLevels) {
  await strapi.db.query('api::user-progress.user-progress').update({
    where: { id: progressId },
    data: { languageLevels },
  });
}

async function ensureLanguageEntry(strapi, userId, languageCode, tutorLevel = 'A1') {
  const { progress, languageLevels } = await loadUserLanguageContext(strapi, userId);
  const code = String(languageCode ?? 'en').trim() || 'en';
  if (!languageLevels[code]) {
    languageLevels[code] = emptyLanguageEntry(tutorLevel);
  } else if (tutorLevel) {
    languageLevels[code].tutorLevel = clampLevel(tutorLevel);
  }
  await persistLanguageLevels(strapi, progress.id, languageLevels);
  return languageLevels[code];
}

async function recordLanguageSelection(strapi, userId, languageCode, tutorLevel = 'A1') {
  const { progress, languageLevels } = await loadUserLanguageContext(strapi, userId);
  const code = String(languageCode ?? 'en').trim() || 'en';
  const level = clampLevel(tutorLevel);
  if (!languageLevels[code]) {
    languageLevels[code] = emptyLanguageEntry(level);
  } else {
    languageLevels[code].tutorLevel = level;
    languageLevels[code].lastActiveAt = new Date().toISOString();
  }
  await persistLanguageLevels(strapi, progress.id, languageLevels);
  return languageLevels[code];
}

async function updateTutorLevelForLanguage(strapi, userId, languageCode, tutorLevel) {
  return recordLanguageSelection(strapi, userId, languageCode, tutorLevel);
}

async function recordSpeakingActivity(strapi, userId, {
  languageCode,
  isPerfect = false,
  correctionCount = 0,
  newWords = 0,
} = {}) {
  const { progress, practiceLanguage, tutorLevel, languageLevels } =
    await loadUserLanguageContext(strapi, userId);
  const code = String(languageCode ?? practiceLanguage ?? 'en').trim() || 'en';
  const entry = languageLevels[code] ?? emptyLanguageEntry(tutorLevel);

  entry.speakingTurns += 1;
  if (isPerfect) entry.perfectSentences += 1;
  if (correctionCount > 0) entry.correctionCount += correctionCount;
  if (newWords > 0) entry.uniqueWordsSpoken += newWords;

  const updated = recomputeEntry(entry);
  languageLevels[code] = updated;
  await persistLanguageLevels(strapi, progress.id, languageLevels);

  await strapi.db.query('api::user-progress.user-progress').update({
    where: { id: progress.id },
    data: { currentLevel: updated.estimatedLevel },
  });

  return updated;
}

async function recordDeckReviewActivity(strapi, userId, { languageCode, wordsDelta = 1 } = {}) {
  const { progress, practiceLanguage, tutorLevel, languageLevels } =
    await loadUserLanguageContext(strapi, userId);
  const code = String(languageCode ?? practiceLanguage ?? 'en').trim() || 'en';
  const entry = languageLevels[code] ?? emptyLanguageEntry(tutorLevel);

  entry.deckWordsReviewed += Math.max(1, Number(wordsDelta) || 1);
  const updated = recomputeEntry(entry);
  languageLevels[code] = updated;
  await persistLanguageLevels(strapi, progress.id, languageLevels);

  await strapi.db.query('api::user-progress.user-progress').update({
    where: { id: progress.id },
    data: { currentLevel: updated.estimatedLevel },
  });

  return updated;
}

function formatLanguageLevelsResponse({
  practiceLanguage,
  tutorLevel,
  languageLevels,
}) {
  const current = languageLevels[practiceLanguage] ?? emptyLanguageEntry(tutorLevel);
  const history = Object.entries(languageLevels)
    .map(([code, entry]) => ({
      languageCode: code,
      tutorLevel: entry.tutorLevel,
      estimatedLevel: entry.estimatedLevel,
      lastActiveAt: entry.lastActiveAt,
      firstSelectedAt: entry.firstSelectedAt,
      speakingTurns: entry.speakingTurns,
      deckWordsReviewed: entry.deckWordsReviewed,
      levelHistory: entry.levelHistory ?? [],
    }))
    .sort((a, b) => String(b.lastActiveAt).localeCompare(String(a.lastActiveAt)));

  return {
    practiceLanguage,
    tutorLevel: current.tutorLevel ?? tutorLevel,
    estimatedLevel: current.estimatedLevel ?? 'A1',
    speakingTurns: current.speakingTurns ?? 0,
    deckWordsReviewed: current.deckWordsReviewed ?? 0,
    uniqueWordsSpoken: current.uniqueWordsSpoken ?? 0,
    levelHistory: current.levelHistory ?? [],
    languages: history,
  };
}

async function getLanguageLevelsSnapshot(strapi, userId) {
  const { practiceLanguage, tutorLevel, languageLevels } =
    await loadUserLanguageContext(strapi, userId);
  await ensureLanguageEntry(strapi, userId, practiceLanguage, tutorLevel);
  const refreshed = await loadUserLanguageContext(strapi, userId);
  return formatLanguageLevelsResponse({
    practiceLanguage: refreshed.practiceLanguage,
    tutorLevel: refreshed.tutorLevel,
    languageLevels: refreshed.languageLevels,
  });
}

module.exports = {
  CEFR_LEVELS,
  estimateLevelFromStats,
  normalizeLanguageLevels,
  recordLanguageSelection,
  updateTutorLevelForLanguage,
  recordSpeakingActivity,
  recordDeckReviewActivity,
  getLanguageLevelsSnapshot,
  formatLanguageLevelsResponse,
};
