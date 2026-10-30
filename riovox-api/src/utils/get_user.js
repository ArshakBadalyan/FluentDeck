const { findUserById } = require('./document-service');

const getUser = async (userId) => {
  return findUserById(strapi, userId, {
    populate: { user_answers: { sort: 'createdAt:desc' } },
  });
};

module.exports = {
  getUser,
};
