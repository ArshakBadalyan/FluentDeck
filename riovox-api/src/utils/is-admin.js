const { findUserById } = require('./document-service');

const isAdmin = async (ctx) => {
  const user = await strapi.plugins['users-permissions'].services.jwt.getToken(ctx);
  if (!user?.id) {
    return false;
  }
  const userInfo = await findUserById(strapi, user.id, {
    fields: ['is_admin'],
  });
  return userInfo?.is_admin === true;
};

module.exports = {
  isAdmin,
};
