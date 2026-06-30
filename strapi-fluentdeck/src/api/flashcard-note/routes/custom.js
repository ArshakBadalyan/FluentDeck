module.exports = {
  routes: [
    {
      method: 'GET',
      path: '/flashcards/note-types',
      handler: 'flashcard-note.listNoteTypes',
    },
    {
      method: 'POST',
      path: '/flashcards/notes',
      handler: 'flashcard-note.createNote',
    },
    {
      method: 'GET',
      path: '/flashcards/notes/:id',
      handler: 'flashcard-note.getNote',
    },
    {
      method: 'PUT',
      path: '/flashcards/notes/:id',
      handler: 'flashcard-note.updateNote',
    },
    {
      method: 'DELETE',
      path: '/flashcards/notes/:id',
      handler: 'flashcard-note.deleteNote',
    },
    {
      method: 'POST',
      path: '/flashcards/notes/:id/change-type',
      handler: 'flashcard-note.changeNoteType',
    },
  ],
};
