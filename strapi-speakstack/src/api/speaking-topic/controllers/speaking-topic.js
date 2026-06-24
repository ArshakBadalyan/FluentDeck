'use strict';

const { createCoreController } = require('@strapi/strapi').factories;
const {
  annotateTopicRows,
  getSpeakingPremiumContext,
} = require('../../../utils/speaking-premium-access');
const { formatSpeakingTopic } = require('../../../utils/speaking-catalog-format');

async function getAuthenticatedUserId(ctx, strapi) {
  try {
    const token = await strapi.plugins['users-permissions'].services.jwt.getToken(ctx);
    return token?.id ?? null;
  } catch {
    return null;
  }
}

module.exports = createCoreController(
  'api::speaking-topic.speaking-topic',
  ({ strapi }) => ({
    async catalog(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      const premiumCtx = await getSpeakingPremiumContext(strapi, userId);
      const levelGroup = ctx.query?.levelGroup
        ? String(ctx.query.levelGroup)
        : null;

      const where = { publishedAt: { $notNull: true } };
      if (levelGroup) {
        where.levelGroup = levelGroup;
      }

      const rows = await strapi.db.query('api::speaking-topic.speaking-topic').findMany({
        where,
        orderBy: [{ order: 'asc' }, { id: 'asc' }],
      });

      const allRows = levelGroup
        ? rows
        : await strapi.db.query('api::speaking-topic.speaking-topic').findMany({
            where: { publishedAt: { $notNull: true } },
            orderBy: [{ order: 'asc' }, { id: 'asc' }],
          });

      const annotatedAll = annotateTopicRows(allRows, premiumCtx);
      const byId = new Map(
        annotatedAll.map((entry) => [entry.row.id, entry]),
      );

      ctx.body = {
        data: rows.map((row) => {
          const entry = byId.get(row.id);
          return formatSpeakingTopic(row, {
            isPremiumLocked: entry?.isPremiumLocked ?? false,
            accessMode: entry?.accessMode ?? 'automatic',
          });
        }),
        isPremium: premiumCtx.isPremium,
        rules: {
          freeLevelGroups: premiumCtx.freeLevelGroups,
        },
      };
    },
  }),
);
