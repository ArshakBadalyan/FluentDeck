'use strict';

const { createCoreRouter } = require('@strapi/strapi').factories;

module.exports = createCoreRouter('api::card-review-log.card-review-log', {
  only: [],
});
