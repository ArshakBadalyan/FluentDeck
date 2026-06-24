module.exports = {
  async up(knex) {
    await knex.schema
      .hasColumn("notifications", "type")
      .then(async (exists) => {
        if (!exists) {
          await knex.schema.table("notifications", (table) => {
            table.enu("type", ["congrats", "unfinished_goal"]);
          });
        }

        await knex
          .from("notifications")
          .whereLike("title", "%Congrats%")
          .update({ type: "congrats" });

        await knex
          .from("notifications")
          .whereLike("title", "%Don't%")
          .update({ type: "unfinished_goal" });
      });
  },
};
