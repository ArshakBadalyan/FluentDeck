module.exports = {
  routes: [
    {
      method: 'GET',
      path: '/flashcards/note-types/custom',
      handler: 'custom-flashcard-note-type.listCustom',
    },
    {
      method: 'POST',
      path: '/flashcards/note-types/custom',
      handler: 'custom-flashcard-note-type.createCustom',
    },
    {
      method: 'PUT',
      path: '/flashcards/note-types/custom/:id',
      handler: 'custom-flashcard-note-type.updateCustom',
    },
    {
      method: 'DELETE',
      path: '/flashcards/note-types/custom/:id',
      handler: 'custom-flashcard-note-type.deleteCustom',
    },
  ],
};
