module.exports = {
  routes: [
    {
      method: 'GET',
      path: '/vocabulary/catalog/stats',
      handler: 'vocabulary-entry.catalogStats',
    },
    {
      method: 'GET',
      path: '/vocabulary/catalog',
      handler: 'vocabulary-entry.catalogList',
    },
    {
      method: 'POST',
      path: '/vocabulary/save',
      handler: 'vocabulary-entry.saveWord',
    },
    {
      method: 'POST',
      path: '/vocabulary/unsave',
      handler: 'vocabulary-entry.unsaveWord',
    },
    {
      method: 'GET',
      path: '/vocabulary/my-words',
      handler: 'vocabulary-entry.myWords',
    },
    {
      method: 'GET',
      path: '/vocabulary/placement/questions',
      handler: 'vocabulary-entry.placementQuestions',
    },
    {
      method: 'POST',
      path: '/vocabulary/placement/submit',
      handler: 'vocabulary-entry.submitPlacement',
    },
    {
      method: 'GET',
      path: '/vocabulary/placement/latest',
      handler: 'vocabulary-entry.latestPlacement',
    },
  ],
};
