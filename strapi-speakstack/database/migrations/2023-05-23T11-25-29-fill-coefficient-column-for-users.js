module.exports = {
  async up(knex) {
    await knex.schema
      .hasColumn("up_users", "coefficient")
      .then(async (exists) => {
        if (!exists) {
          await knex.schema.table("up_users", (table) => {
            table.decimal("coefficient");
          });
        }

        await knex
          .from("up_users")
          .whereNull("coefficient")
          .update({ coefficient: 0 });
      });
  },
};
