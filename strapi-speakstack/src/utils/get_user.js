const getUser = async (userId) => {
  return await strapi.entityService.findOne(
    "plugin::users-permissions.user",
    userId,
    {
      populate: { user_answers: { sort: "createdAt:desc" } },
    }
  );
};

module.exports = {
  getUser
}
