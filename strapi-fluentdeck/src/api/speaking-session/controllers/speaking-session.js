'use strict';

const { createCoreController } = require('@strapi/strapi').factories;
const {
  createCompletedSession,
  listRecentSessions,
  bestScoresByReference,
} = require('../../../utils/speaking-session-utils');

async function getAuthenticatedUserId(ctx, strapi) {
  const token = await strapi.plugins['users-permissions'].services.jwt.getToken(
    ctx,
  );
  return token?.id ?? null;
}

const VALID_MODES = new Set(['chat', 'role_play', 'topic', 'game', 'lesson']);

module.exports = createCoreController(
  'api::speaking-session.speaking-session',
  ({ strapi }) => ({
    async completeSession(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const body = ctx.request.body ?? {};
      const mode = String(body.mode ?? 'chat').trim();
      const title = String(body.title ?? '').trim();

      if (!VALID_MODES.has(mode)) {
        return ctx.badRequest('Invalid mode');
      }
      if (!title) {
        return ctx.badRequest('title is required');
      }
      if (body.score == null || Number.isNaN(Number(body.score))) {
        return ctx.badRequest('score is required');
      }

      try {
        const result = await createCompletedSession(strapi, userId, {
          mode,
          referenceKey: body.referenceKey ? String(body.referenceKey) : null,
          title,
          score: body.score,
          feedback: body.feedback,
          summary: body.summary,
          durationMinutes: body.durationMinutes,
          turnCount: body.turnCount,
          completedAt: body.completedAt,
        });

        const bestScores = await bestScoresByReference(strapi, userId);

        ctx.body = {
          session: result.session,
          progress: result.progress,
          bestScores,
        };
      } catch (error) {
        strapi.log.error('[speaking-session.completeSession]', error);
        return ctx.internalServerError('Could not save speaking session');
      }
    },

    async recentHistory(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const limit = ctx.query?.limit ?? 10;
      const data = await listRecentSessions(strapi, userId, limit);
      ctx.body = { data };
    },

    async scoreMap(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const bestScores = await bestScoresByReference(strapi, userId);
      ctx.body = { bestScores };
    },
  }),
);
