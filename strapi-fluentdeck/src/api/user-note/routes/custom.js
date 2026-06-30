module.exports = {
  routes: [
    {
      method: 'GET',
      path: '/notes',
      handler: 'user-note.listNotes',
    },
    {
      method: 'POST',
      path: '/notes',
      handler: 'user-note.createNote',
    },
    {
      method: 'PUT',
      path: '/notes/:id',
      handler: 'user-note.updateNote',
    },
    {
      method: 'DELETE',
      path: '/notes/:id',
      handler: 'user-note.deleteNote',
    },
    {
      method: 'POST',
      path: '/notes/from-correction',
      handler: 'user-note.saveFromCorrection',
    },
    {
      method: 'GET',
      path: '/notes/study-settings',
      handler: 'user-note.studySettings',
    },
  ],
};
