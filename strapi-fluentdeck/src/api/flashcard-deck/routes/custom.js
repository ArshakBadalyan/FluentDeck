module.exports = {
  routes: [
    {
      method: 'GET',
      path: '/flashcards/decks',
      handler: 'flashcard-deck.listDecks',
    },
    {
      method: 'GET',
      path: '/flashcards/decks/:id',
      handler: 'flashcard-deck.deckDetail',
    },
    {
      method: 'POST',
      path: '/flashcards/decks',
      handler: 'flashcard-deck.createDeck',
    },
    {
      method: 'PUT',
      path: '/flashcards/decks/:id',
      handler: 'flashcard-deck.updateDeck',
    },
    {
      method: 'POST',
      path: '/flashcards/decks/filtered',
      handler: 'flashcard-deck.createFilteredDeck',
    },
    {
      method: 'DELETE',
      path: '/flashcards/decks/:id',
      handler: 'flashcard-deck.deleteDeck',
    },
    {
      method: 'POST',
      path: '/flashcards/cards',
      handler: 'flashcard-deck.createCard',
    },
    {
      method: 'PUT',
      path: '/flashcards/cards/:cardId',
      handler: 'flashcard-deck.updateCard',
    },
    {
      method: 'DELETE',
      path: '/flashcards/cards/:cardId',
      handler: 'flashcard-deck.deleteCard',
    },
    {
      method: 'GET',
      path: '/flashcards/review/queue',
      handler: 'flashcard-deck.reviewQueue',
    },
    {
      method: 'POST',
      path: '/flashcards/review/answer',
      handler: 'flashcard-deck.submitReview',
    },
    {
      method: 'GET',
      path: '/flashcards/stats',
      handler: 'flashcard-deck.studyStats',
    },
    {
      method: 'GET',
      path: '/flashcards/stats/detailed',
      handler: 'flashcard-deck.detailedStats',
    },
    {
      method: 'GET',
      path: '/flashcards/review-log',
      handler: 'flashcard-deck.reviewLog',
    },
    {
      method: 'GET',
      path: '/flashcards/sync/pull',
      handler: 'flashcard-deck.syncPull',
    },
    {
      method: 'POST',
      path: '/flashcards/sync/push',
      handler: 'flashcard-deck.syncPush',
    },
    {
      method: 'GET',
      path: '/flashcards/sync/status',
      handler: 'flashcard-deck.syncStatus',
    },
    {
      method: 'GET',
      path: '/flashcards/browse',
      handler: 'flashcard-deck.browseCards',
    },
    {
      method: 'POST',
      path: '/flashcards/cards/:cardId/suspend',
      handler: 'flashcard-deck.suspendCard',
    },
    {
      method: 'POST',
      path: '/flashcards/cards/:cardId/unsuspend',
      handler: 'flashcard-deck.unsuspendCard',
    },
    {
      method: 'POST',
      path: '/flashcards/cards/:cardId/bury',
      handler: 'flashcard-deck.buryCard',
    },
    {
      method: 'POST',
      path: '/flashcards/cards/:cardId/flag',
      handler: 'flashcard-deck.setCardFlag',
    },
    {
      method: 'GET',
      path: '/flashcards/export/json',
      handler: 'flashcard-deck.exportJson',
    },
    {
      method: 'GET',
      path: '/flashcards/export/apkg',
      handler: 'flashcard-deck.exportApkg',
    },
    {
      method: 'POST',
      path: '/flashcards/import/csv',
      handler: 'flashcard-deck.importCsv',
    },
    {
      method: 'POST',
      path: '/flashcards/import/txt',
      handler: 'flashcard-deck.importTxt',
    },
    {
      method: 'POST',
      path: '/flashcards/import/apkg',
      handler: 'flashcard-deck.importApkg',
    },
    {
      method: 'POST',
      path: '/flashcards/import/json',
      handler: 'flashcard-deck.importJson',
    },
    {
      method: 'POST',
      path: '/flashcards/media/upload',
      handler: 'flashcard-deck.uploadMedia',
    },
    {
      method: 'POST',
      path: '/flashcards/review/undo',
      handler: 'flashcard-deck.undoReview',
    },
    {
      method: 'POST',
      path: '/flashcards/cards/:cardId/bury-siblings',
      handler: 'flashcard-deck.burySiblings',
    },
    {
      method: 'POST',
      path: '/flashcards/cards/:cardId/unbury',
      handler: 'flashcard-deck.unburyCard',
    },
    {
      method: 'POST',
      path: '/flashcards/check',
      handler: 'flashcard-deck.checkCollection',
    },
    {
      method: 'POST',
      path: '/flashcards/check/database',
      handler: 'flashcard-deck.checkDatabase',
    },
    {
      method: 'POST',
      path: '/flashcards/check/media',
      handler: 'flashcard-deck.checkMediaFiles',
    },
    {
      method: 'GET',
      path: '/flashcards/check/empty-cards',
      handler: 'flashcard-deck.listEmptyCards',
    },
    {
      method: 'POST',
      path: '/flashcards/check/empty-cards/delete',
      handler: 'flashcard-deck.deleteEmptyCards',
    },
    {
      method: 'GET',
      path: '/flashcards/cards/:cardId/info',
      handler: 'flashcard-deck.cardInfo',
    },
    {
      method: 'POST',
      path: '/flashcards/cards/:cardId/set-due',
      handler: 'flashcard-deck.setCardDue',
    },
    {
      method: 'POST',
      path: '/flashcards/cards/:cardId/reset-progress',
      handler: 'flashcard-deck.resetCardProgress',
    },
    {
      method: 'POST',
      path: '/flashcards/cards/:cardId/grade',
      handler: 'flashcard-deck.gradeCardNow',
    },
    {
      method: 'POST',
      path: '/flashcards/cards/:cardId/reposition',
      handler: 'flashcard-deck.repositionCard',
    },
    {
      method: 'GET',
      path: '/flashcards/cards/:cardId/export',
      handler: 'flashcard-deck.exportCardJson',
    },
  ],
};
