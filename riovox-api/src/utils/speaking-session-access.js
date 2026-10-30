'use strict';

const {
  annotateRolePlayRows,
  annotateTopicRows,
  annotateGameRows,
  getSpeakingPremiumContext,
  readCategory,
} = require('./speaking-premium-access');

function parseSessionMode(sessionContext) {
  return String(sessionContext?.mode ?? 'chat').trim().toLowerCase();
}

function parseReferenceKey(sessionContext) {
  return String(sessionContext?.referenceKey ?? '').trim();
}

function isFreeChatReference(referenceKey) {
  if (!referenceKey) return true;
  return (
    referenceKey === 'chat_free' ||
    referenceKey.startsWith('practice_') ||
    referenceKey.startsWith('notes_') ||
    referenceKey.startsWith('training_')
  );
}

async function isRolePlayLocked(strapi, rolePlayId, premiumCtx) {
  const row = await strapi.db.query('api::speaking-role-play.speaking-role-play').findOne({
    where: { id: rolePlayId, publishedAt: { $notNull: true }, isVisible: { $ne: false } },
  });
  if (!row) return false;

  const category = readCategory(row);
  const allRows = await strapi.db.query('api::speaking-role-play.speaking-role-play').findMany({
    where: { publishedAt: { $notNull: true }, isVisible: { $ne: false }, category },
    orderBy: [{ order: 'asc' }, { id: 'asc' }],
  });
  const annotated = annotateRolePlayRows(allRows, premiumCtx);
  const match = annotated.find(({ row }) => row.id === rolePlayId);
  return match?.isPremiumLocked === true;
}

async function isTopicLocked(strapi, topicId, premiumCtx) {
  const row = await strapi.db.query('api::speaking-topic.speaking-topic').findOne({
    where: { id: topicId, publishedAt: { $notNull: true }, isVisible: { $ne: false } },
  });
  if (!row) return false;

  const allRows = await strapi.db.query('api::speaking-topic.speaking-topic').findMany({
    where: { publishedAt: { $notNull: true }, isVisible: { $ne: false } },
    orderBy: [{ order: 'asc' }, { id: 'asc' }],
  });
  const annotated = annotateTopicRows(allRows, premiumCtx);
  const match = annotated.find(({ row }) => row.id === topicId);
  return match?.isPremiumLocked === true;
}

async function isGameLocked(strapi, slug, premiumCtx) {
  const row = await strapi.db.query('api::speaking-game.speaking-game').findOne({
    where: { slug, publishedAt: { $notNull: true }, isVisible: { $ne: false } },
  });
  if (!row) return false;

  const allRows = await strapi.db.query('api::speaking-game.speaking-game').findMany({
    where: { publishedAt: { $notNull: true }, isVisible: { $ne: false } },
    orderBy: [{ order: 'asc' }, { id: 'asc' }],
  });
  const annotated = annotateGameRows(allRows, premiumCtx);
  const match = annotated.find(({ row }) => row.slug === slug);
  return match?.isPremiumLocked === true;
}

/**
 * Ensures the user may use this speaking session context (premium paywall).
 * Returns { ok: true } or { ok: false, status, message }.
 */
async function assertSpeakingSessionAllowed(strapi, userId, sessionContext) {
  if (!sessionContext || typeof sessionContext !== 'object') {
    return { ok: true };
  }

  const mode = parseSessionMode(sessionContext);
  const referenceKey = parseReferenceKey(sessionContext);

  if (mode === 'chat' || isFreeChatReference(referenceKey)) {
    return { ok: true };
  }

  const premiumCtx = await getSpeakingPremiumContext(strapi, userId);
  if (premiumCtx.isPremium) {
    return { ok: true };
  }

  if (mode === 'role_play') {
    if (referenceKey.startsWith('roleplay_local_')) {
      return { ok: true };
    }
    const id = Number.parseInt(referenceKey.replace(/^roleplay_/, ''), 10);
    if (!Number.isFinite(id)) {
      return { ok: true };
    }
    if (await isRolePlayLocked(strapi, id, premiumCtx)) {
      return {
        ok: false,
        status: 402,
        message: 'This role-play scenario requires a premium subscription.',
      };
    }
    return { ok: true };
  }

  if (mode === 'topic') {
    const id = Number.parseInt(referenceKey.replace(/^topic_/, ''), 10);
    if (!Number.isFinite(id)) {
      return { ok: true };
    }
    if (await isTopicLocked(strapi, id, premiumCtx)) {
      return {
        ok: false,
        status: 402,
        message: 'This speaking topic requires a premium subscription.',
      };
    }
    return { ok: true };
  }

  if (mode === 'game') {
    const slug = referenceKey.replace(/^game_/, '');
    if (!slug) {
      return { ok: true };
    }
    if (await isGameLocked(strapi, slug, premiumCtx)) {
      return {
        ok: false,
        status: 402,
        message: 'This speaking game requires a premium subscription.',
      };
    }
    return { ok: true };
  }

  return { ok: true };
}

module.exports = {
  assertSpeakingSessionAllowed,
  isFreeChatReference,
};
