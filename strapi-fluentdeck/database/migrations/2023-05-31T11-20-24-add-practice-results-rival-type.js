module.exports = {
  async up(knex) {
    await knex.schema
      .hasColumn("practice_results", "rival_type")
      .then(async (exists) => {
        if (!exists) {
          await knex.schema.table("practice_results", (table) => {
            table.enu("type", ["machine", "fake_user"]);
          });
        }

        await knex
          .from("practice_results")
          .whereNull("rival_type")
          .update({ rival_type: "machine" });
      });
  },
};
