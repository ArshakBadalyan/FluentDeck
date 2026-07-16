module.exports = {
  async up(knex) {
    await knex.schema.table('up_users', table => {
      table.renameColumn('nickname', 'username')
    })
  },
};
