module.exports = {
  async up(knex) {
    await knex.insert({
      action: "plugin::users-permissions.user.getUserStats",
      created_at: new Date(),
      updated_at: new Date()
    }).into('up_permissions');
  },
};
