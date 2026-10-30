'use strict';

const { createCoreRouter } = require('@strapi/strapi').factories;

// Deck/card study APIs are custom routes in routes/custom.js.
module.exports = createCoreRouter('api::flashcard-deck.flashcard-deck', {
  only: [],
});
