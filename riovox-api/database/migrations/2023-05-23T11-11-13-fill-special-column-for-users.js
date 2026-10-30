module.exports = {
  async up(knex) {
    await knex.schema.hasColumn("up_users", "special").then(async (exists) => {
      if (!exists) {
        await knex.schema.table("up_users", (table) => {
          table.boolean("special");
        });
      }

      await knex
        .from("up_users")
        .whereNull("special")
        .update({ special: false });
    });
  },
};
