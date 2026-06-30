'use strict';

const { getFeatureConfig, isPremiumUser } = require('./app-feature-config');

function todayKey(now = new Date()) {
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
}

async function getConversationUsage(strapi, userId) {
  const premium = await isPremiumUser(strapi, userId);
  const config = await getFeatureConfig(strapi);
  const dailyLimit =
    config.freeDailyConversationTurns ??
    config.free_daily_conversation_turns ??
    10;

  if (premium) {
    return {
      allowed: true,
      usedToday: 0,
      dailyLimit,
      isPremium: true,
    };
  }

  const user = await strapi.db.query('plugin::users-permissions.user').findOne({
    where: { id: userId },
    select: ['ai_turns_date', 'ai_turns_count'],
  });

  const today = todayKey();
  const storedDate = user?.ai_turns_date ?? user?.aiTurnsDate ?? '';
  let usedToday = Number(user?.ai_turns_count ?? user?.aiTurnsCount ?? 0);
  if (storedDate !== today) {
    usedToday = 0;
  }

  return {
    allowed: usedToday < dailyLimit,
    usedToday,
    dailyLimit,
    isPremium: false,
  };
}

async function recordConversationTurn(strapi, userId) {
  const premium = await isPremiumUser(strapi, userId);
  if (premium) {
    return getConversationUsage(strapi, userId);
  }

  const today = todayKey();
  const user = await strapi.db.query('plugin::users-permissions.user').findOne({
    where: { id: userId },
    select: ['ai_turns_date', 'ai_turns_count'],
  });

  const storedDate = user?.ai_turns_date ?? user?.aiTurnsDate ?? '';
  let usedToday = Number(user?.ai_turns_count ?? user?.aiTurnsCount ?? 0);
  if (storedDate !== today) {
    usedToday = 0;
  }
  usedToday += 1;

  await strapi.db.query('plugin::users-permissions.user').update({
    where: { id: userId },
    data: {
      ai_turns_date: today,
      ai_turns_count: usedToday,
    },
  });

  const config = await getFeatureConfig(strapi);
  const dailyLimit =
    config.freeDailyConversationTurns ??
    config.free_daily_conversation_turns ??
    10;

  return {
    allowed: usedToday < dailyLimit,
    usedToday,
    dailyLimit,
    isPremium: false,
  };
}

module.exports = {
  todayKey,
  getConversationUsage,
  recordConversationTurn,
};
