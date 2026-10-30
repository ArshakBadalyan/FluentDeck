'use strict';

const { createCoreRouter } = require('@strapi/strapi').factories;

// All flashcard HTTP APIs live under flashcard-deck custom routes (/flashcards/*).
// Disable core CRUD so GET /flashcards/:id does not steal paths like /flashcards/decks.
module.exports = createCoreRouter('api::flashcard.flashcard', {
  only: [],
});
