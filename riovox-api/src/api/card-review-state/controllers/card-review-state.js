'use strict';

const { createCoreController } = require('@strapi/strapi').factories;
const { createCoreService } = require('@strapi/strapi').factories;
const { createCoreRouter } = require('@strapi/strapi').factories;

module.exports = createCoreController('api::card-review-state.card-review-state');
