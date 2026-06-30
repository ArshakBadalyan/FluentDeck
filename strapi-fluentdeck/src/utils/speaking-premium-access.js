'use strict';

const { getFeatureConfig, isPremiumUser } = require('./app-feature-config');

const ACCESS_MODES = new Set(['automatic', 'free', 'premium']);

function readAccessMode(row) {
  const raw = row?.accessMode ?? row?.access_mode ?? 'automatic';
  return ACCESS_MODES.has(raw) ? raw : 'automatic';
}

function readLevelGroup(row) {
  return row?.levelGroup ?? row?.level_group ?? 'intermediate';
}

function readCategory(row) {
  return row?.category ?? 'daily_life';
}

function resolveLockedByMode(accessMode, automaticLocked, isPremium) {
  if (isPremium) return false;
  if (accessMode === 'free') return false;
  if (accessMode === 'premium') return true;
  return automaticLocked;
}

function pickFreeTopicLevelGroups(config) {
  const raw =
    config?.freeTopicLevelGroups ?? config?.free_topic_level_groups ?? ['intermediate'];
  if (Array.isArray(raw)) {
    return raw.map((v) => String(v).toLowerCase()).filter(Boolean);
  }
  if (typeof raw === 'string') {
    try {
      const parsed = JSON.parse(raw);
      if (Array.isArray(parsed)) {
        return parsed.map((v) => String(v).toLowerCase()).filter(Boolean);
      }
    } catch {
      return ['intermediate'];
    }
  }
  return ['intermediate'];
}

function pickFreeRolePlayPerCategory(config) {
  const raw =
    config?.freeRolePlayPerCategory ?? config?.free_role_play_per_category ?? 2;
  const n = typeof raw === 'number' ? raw : parseInt(String(raw), 10);
  return Number.isFinite(n) && n >= 0 ? n : 2;
}

function pickGamesRequirePremium(config) {
  const raw = config?.gamesRequirePremium ?? config?.games_require_premium;
  return raw === true;
}

function annotateRolePlayRows(rows, { isPremium, freePerCategory }) {
  const counters = {};
  return rows.map((row) => {
    const category = readCategory(row);
    const index = counters[category] ?? 0;
    counters[category] = index + 1;

    const accessMode = readAccessMode(row);
    const automaticLocked = !isPremium && index >= freePerCategory;
    const isPremiumLocked = resolveLockedByMode(accessMode, automaticLocked, isPremium);

    return { row, isPremiumLocked, accessMode };
  });
}

function annotateTopicRows(rows, { isPremium, freeLevelGroups }) {
  return rows.map((row) => {
    const accessMode = readAccessMode(row);
    const level = readLevelGroup(row);
    const automaticLocked = !isPremium && !freeLevelGroups.includes(level);
    const isPremiumLocked = resolveLockedByMode(accessMode, automaticLocked, isPremium);
    return { row, isPremiumLocked, accessMode };
  });
}

function annotateGameRows(rows, { isPremium, gamesRequirePremium }) {
  return rows.map((row) => {
    const accessMode = readAccessMode(row);
    const automaticLocked = !isPremium && gamesRequirePremium;
    const isPremiumLocked = resolveLockedByMode(accessMode, automaticLocked, isPremium);
    return { row, isPremiumLocked, accessMode };
  });
}

async function getSpeakingPremiumContext(strapi, userId) {
  const [config, isPremium] = await Promise.all([
    getFeatureConfig(strapi),
    userId ? isPremiumUser(strapi, userId) : false,
  ]);

  return {
    isPremium,
    freePerCategory: pickFreeRolePlayPerCategory(config),
    freeLevelGroups: pickFreeTopicLevelGroups(config),
    gamesRequirePremium: pickGamesRequirePremium(config),
  };
}

module.exports = {
  readAccessMode,
  readCategory,
  annotateRolePlayRows,
  annotateTopicRows,
  annotateGameRows,
  getSpeakingPremiumContext,
  pickFreeTopicLevelGroups,
  pickFreeRolePlayPerCategory,
  pickGamesRequirePremium,
};
