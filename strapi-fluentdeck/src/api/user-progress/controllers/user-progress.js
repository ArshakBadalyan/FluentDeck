'use strict';

const { createCoreController } = require('@strapi/strapi').factories;
const {
  getOwnedProgress,
  getOrCreateUserProgress,
  updateOwnedProgress,
  formatProgressResponse,
} = require('../../../utils/user-progress-utils');

module.exports = createCoreController('api::user-progress.user-progress', ({ strapi }) => ({
  async find(ctx) {
    const userId = ctx.state.user?.id;
    if (!userId) return ctx.unauthorized('Authentication required');

    const row = await getOwnedProgress(strapi, userId);
    ctx.body = { data: row ? [formatProgressResponse(row)] : [] };
  },

  async findOne(ctx) {
    const userId = ctx.state.user?.id;
    if (!userId) return ctx.unauthorized('Authentication required');

    const row = await getOwnedProgress(strapi, userId);
    const id = Number(ctx.params.id);
    if (!row || row.id !== id) return ctx.notFound('User progress not found');

    ctx.body = { data: formatProgressResponse(row) };
  },

  async create(ctx) {
    const userId = ctx.state.user?.id;
    if (!userId) return ctx.unauthorized('Authentication required');

    const existing = await getOwnedProgress(strapi, userId);
    if (existing) {
      ctx.body = { data: formatProgressResponse(existing) };
      return;
    }

    const payload = ctx.request.body?.data ?? {};
    const row = await strapi.db.query('api::user-progress.user-progress').create({
      data: {
        currentLevel: payload.currentLevel ?? 'B1',
        weakAreas: payload.weakAreas ?? [],
        streakDays: payload.streakDays ?? 0,
        totalSpeakingMinutes: payload.totalSpeakingMinutes ?? 0,
        perfectSentencesCount: payload.perfectSentencesCount ?? 0,
        uniqueWordsUsed: payload.uniqueWordsUsed ?? 0,
        completedExercises: payload.completedExercises ?? [],
        user: userId,
      },
    });

    ctx.body = { data: formatProgressResponse(row) };
  },

  async update(ctx) {
    const userId = ctx.state.user?.id;
    if (!userId) return ctx.unauthorized('Authentication required');

    const payload = ctx.request.body?.data;
    if (!payload || typeof payload !== 'object') {
      return ctx.badRequest('data object is required');
    }

    const updated = await updateOwnedProgress(strapi, userId, ctx.params.id, payload);
    if (!updated) {
      return ctx.forbidden('You can only update your own progress record');
    }

    ctx.body = { data: formatProgressResponse(updated) };
  },
}));
