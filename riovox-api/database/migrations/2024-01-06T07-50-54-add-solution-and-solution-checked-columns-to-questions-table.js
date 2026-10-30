module.exports = {
  async up(knex) {
    await knex.schema
      .hasColumn("questions", "solution")
      .then(async (exists) => {
        if (!exists) {
          await knex.schema.table("questions", (table) => {
            table.string("solution", 2048);
            table.boolean("solution_checked");
          });
        }
      });

    await knex
      .from("questions")
      .whereNull("solution_checked")
      .update({ "solution_checked": false, solution: "" });
  },
};
