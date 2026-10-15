'use strict';

module.exports = {
  routes: [
    {
      method: 'GET',
      path: '/user-progress/language-levels',
      handler: 'user-progress.languageLevels',
    },
    {
      method: 'DELETE',
      path: '/user-progress/learning-data',
      handler: 'user-progress.resetLearningData',
    },
  ],
};
