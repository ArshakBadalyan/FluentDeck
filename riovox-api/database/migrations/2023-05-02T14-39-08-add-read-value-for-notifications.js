module.exports = {
  async up(knex) {
    await knex.schema.hasColumn('notifications', 'read')
      .then(async exists => {
        if (!exists) {
          await knex.schema.table('notifications', table => {
            table.boolean('read')
          })
        }

        await knex.from('notifications').whereNull('read').update({ read: false });
      });
  },
};
