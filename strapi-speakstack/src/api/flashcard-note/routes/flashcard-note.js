'use strict';

const { createCoreRouter } = require('@strapi/strapi').factories;

module.exports = createCoreRouter('api::flashcard-note.flashcard-note', {
  only: [],
});
