module.exports = {
  async up(knex) {
    await knex.insert({
      permission_id: 46,
      role_id: 1
    }).into('up_permissions_role_links');
  },
};
