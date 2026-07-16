'use strict';

const { createCoreController } = require('@strapi/strapi').factories;
const {
  annotateRolePlayRows,
  getSpeakingPremiumContext,
  readCategory,
} = require('../../../utils/speaking-premium-access');
const { formatSpeakingRolePlay } = require('../../../utils/speaking-catalog-format');

async function getAuthenticatedUserId(ctx, strapi) {
  try {
    const token = await strapi.plugins['users-permissions'].services.jwt.getToken(ctx);
    return token?.id ?? null;
  } catch {
    return null;
  }
}

module.exports = createCoreController(
  'api::speaking-role-play.speaking-role-play',
  ({ strapi }) => ({
    async catalog(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      const premiumCtx = await getSpeakingPremiumContext(strapi, userId);
      const category = ctx.query?.category ? String(ctx.query.category) : 'all';

      const allRows = await strapi.db
        .query('api::speaking-role-play.speaking-role-play')
        .findMany({
          where: { publishedAt: { $notNull: true }, isVisible: { $ne: false } },
          orderBy: [{ order: 'asc' }, { id: 'asc' }],
        });

      const annotated = annotateRolePlayRows(allRows, premiumCtx);
      const filtered =
        category && category !== 'all' && category !== 'custom'
          ? annotated.filter(({ row }) => readCategory(row) === category)
          : annotated;

      ctx.body = {
        data: filtered.map(({ row, isPremiumLocked, accessMode }) =>
          formatSpeakingRolePlay(row, { isPremiumLocked, accessMode }),
        ),
        isPremium: premiumCtx.isPremium,
        rules: {
          freePerCategory: premiumCtx.freePerCategory,
        },
      };
    },
  }),
);
