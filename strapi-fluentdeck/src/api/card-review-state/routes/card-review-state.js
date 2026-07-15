'use strict';

const { createCoreRouter } = require('@strapi/strapi').factories;

module.exports = createCoreRouter('api::card-review-state.card-review-state', {
  only: [],
});
