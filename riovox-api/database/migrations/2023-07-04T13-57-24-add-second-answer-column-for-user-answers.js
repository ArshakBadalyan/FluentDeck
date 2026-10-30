module.exports = {
  async up(knex) {
    await knex.schema
      .hasColumn("user_answers", "second_answer")
      .then(async (exists) => {
        if (!exists) {
          await knex.schema.table("user_answers", (table) => {
            table.string("second_answer");
          });
        }
      });

    await knex
      .from("user_answers")
      .whereNull("second_answer")
      .update({ second_answer: "" });
  },
};
