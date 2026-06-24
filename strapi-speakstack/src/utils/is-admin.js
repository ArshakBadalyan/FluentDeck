const isAdmin = async (ctx) => {
  const user = await strapi.plugins[
    "users-permissions"
  ].services.jwt.getToken(ctx);
  if (!user?.id) {
    return false;
  }
  const userInfo = await strapi.entityService.findOne(
    "plugin::users-permissions.user",
    user.id,
    { fields: ["is_admin"] }
  );
  return userInfo?.is_admin === true;
};
module.exports = {
  isAdmin
}
