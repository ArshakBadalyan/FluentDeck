'use strict';

/**
 * Global default SM-2 learning steps for new decks (Again / Hard / Good / Easy previews).
 * Priority: Strapi CMS (app-feature-config) → .env → built-in defaults.
 *
 * Env:
 *   FLASHCARD_DEFAULT_LEARNING_STEPS=2,8,10
 *   FLASHCARD_DEFAULT_EASY_INTERVAL_DAYS=5
 */

const BUILTIN_DEFAULTS = {
  learningStepsMinutes: [2, 8, 10],
  easyIntervalDays: 5,
};

let cachedDefaults = null;

function parseStepsList(raw, fallback) {
  if (raw == null || raw === '') return fallback;
  if (Array.isArray(raw)) {
    const parsed = raw
      .map((n) => parseInt(String(n), 10))
      .filter((n) => Number.isFinite(n) && n > 0);
    return parsed.length ? parsed : fallback;
  }
  if (typeof raw === 'string') {
    const parsed = raw
      .split(/[,;\s]+/)
      .map((s) => parseInt(s.trim(), 10))
      .filter((n) => Number.isFinite(n) && n > 0);
    return parsed.length ? parsed : fallback;
  }
  return fallback;
}

function parseEasyDays(raw, fallback) {
  if (raw == null || raw === '') return fallback;
  const n = typeof raw === 'number' ? raw : parseFloat(String(raw));
  return Number.isFinite(n) && n > 0 ? n : fallback;
}

function getEnvSchedulingDefaults() {
  const envSteps = process.env.FLASHCARD_DEFAULT_LEARNING_STEPS;
  const envEasy = process.env.FLASHCARD_DEFAULT_EASY_INTERVAL_DAYS;
  return {
    learningStepsMinutes: parseStepsList(
      envSteps,
      BUILTIN_DEFAULTS.learningStepsMinutes,
    ),
    easyIntervalDays: parseEasyDays(envEasy, BUILTIN_DEFAULTS.easyIntervalDays),
  };
}

function getSchedulingDefaultsSync() {
  return cachedDefaults || getEnvSchedulingDefaults();
}

function setCachedSchedulingDefaults(defaults) {
  cachedDefaults = {
    learningStepsMinutes: parseStepsList(
      defaults.learningStepsMinutes,
      BUILTIN_DEFAULTS.learningStepsMinutes,
    ),
    easyIntervalDays: parseEasyDays(
      defaults.easyIntervalDays,
      BUILTIN_DEFAULTS.easyIntervalDays,
    ),
  };
  return cachedDefaults;
}

/**
 * Load CMS values over env defaults and cache for sync SM-2 helpers.
 */
async function refreshSchedulingDefaults(strapi) {
  const envDefaults = getEnvSchedulingDefaults();
  let cmsSteps = null;
  let cmsEasy = null;

  try {
    const { getFeatureConfig } = require('./app-feature-config');
    const config = await getFeatureConfig(strapi);
    cmsSteps =
      config.defaultLearningStepsMinutes ?? config.default_learning_steps_minutes;
    cmsEasy =
      config.defaultEasyIntervalDays ?? config.default_easy_interval_days;
  } catch {
    // Keep env/builtin defaults.
  }

  return setCachedSchedulingDefaults({
    learningStepsMinutes: parseStepsList(cmsSteps, envDefaults.learningStepsMinutes),
    easyIntervalDays: parseEasyDays(cmsEasy, envDefaults.easyIntervalDays),
  });
}

module.exports = {
  BUILTIN_DEFAULTS,
  parseStepsList,
  parseEasyDays,
  getEnvSchedulingDefaults,
  getSchedulingDefaultsSync,
  setCachedSchedulingDefaults,
  refreshSchedulingDefaults,
};
