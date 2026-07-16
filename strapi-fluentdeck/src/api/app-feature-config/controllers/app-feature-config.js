'use strict';

const { createCoreController } = require('@strapi/strapi').factories;
const {
  DEFAULT_CONFIG,
  getFeatureConfig,
} = require('../../../utils/app-feature-config');

module.exports = createCoreController(
  'api::app-feature-config.app-feature-config',
  ({ strapi }) => ({
    async publicConfig(ctx) {
      // Shared resolver applies FREE_/PREMIUM_DAILY_CONVERSATION_TURNS from env.
      const config = await getFeatureConfig(strapi);
      ctx.body = {
        ...DEFAULT_CONFIG,
        ...config,
      };
    },
  }),
);
