module.exports = {
  async up(knex) {
    await knex.schema
      .hasColumn("questions", "second_answer")
      .then(async (exists) => {
        if (!exists) {
          await knex.schema.table("questions", (table) => {
            table.string("second_answer");
          });
        }
      });

    await knex
      .from("questions")
      .whereNull("second_answer")
      .update({ second_answer: "" });
  },
};
