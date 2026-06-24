'use strict';

const { createCoreController } = require('@strapi/strapi').factories;
const { buildStudyHallSummary } = require('../../../utils/study-hall');

async function getAuthenticatedUserId(ctx, strapi) {
  const token = await strapi.plugins['users-permissions'].services.jwt.getToken(
    ctx,
  );
  return token?.id ?? null;
}

module.exports = createCoreController('api::study-hall.study-hall', ({ strapi }) => ({
  async summary(ctx) {
    const userId = await getAuthenticatedUserId(ctx, strapi);
    if (!userId) return ctx.unauthorized('Authentication required');

    try {
      const summary = await buildStudyHallSummary(strapi, userId);
      ctx.body = summary;
    } catch (error) {
      strapi.log.error('[study-hall.summary]', error);
      return ctx.internalServerError('Could not load Study Hall');
    }
  },
}));
