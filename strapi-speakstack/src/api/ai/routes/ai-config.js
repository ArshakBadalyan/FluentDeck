'use strict';

const { createCoreRouter } = require('@strapi/strapi').factories;

// Placeholder single type — real endpoints are in custom.js (ai.transcribe, etc.)
module.exports = createCoreRouter('api::ai.ai-config', {
  only: [],
});
