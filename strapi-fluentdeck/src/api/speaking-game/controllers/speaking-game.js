'use strict';

const { createCoreController } = require('@strapi/strapi').factories;
const {
  annotateGameRows,
  getSpeakingPremiumContext,
} = require('../../../utils/speaking-premium-access');
const { formatSpeakingGame } = require('../../../utils/speaking-catalog-format');

async function getAuthenticatedUserId(ctx, strapi) {
  try {
    const token = await strapi.plugins['users-permissions'].services.jwt.getToken(ctx);
    return token?.id ?? null;
  } catch {
    return null;
  }
}

module.exports = createCoreController(
  'api::speaking-game.speaking-game',
  ({ strapi }) => ({
    async catalog(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      const premiumCtx = await getSpeakingPremiumContext(strapi, userId);

      const rows = await strapi.db.query('api::speaking-game.speaking-game').findMany({
        where: { publishedAt: { $notNull: true } },
        orderBy: [{ order: 'asc' }, { id: 'asc' }],
      });

      const annotated = annotateGameRows(rows, premiumCtx);

      ctx.body = {
        data: annotated.map(({ row, isPremiumLocked, accessMode }) =>
          formatSpeakingGame(row, { isPremiumLocked, accessMode }),
        ),
        isPremium: premiumCtx.isPremium,
        rules: {
          gamesRequirePremium: premiumCtx.gamesRequirePremium,
        },
      };
    },
  }),
);
