/*    "createdAt": "........................",
    "updatedAt": "........................",
    "publishedAt": "........................",*/

module.exports = {
  async up(knex) {
    await knex.schema.hasColumn("up_users", "sound").then(async (exists) => {
      if (!exists) {
        await knex.schema.table("up_users", (table) => {
          table.boolean("sound");
        });
      }

      await knex
        .from("up_users")
        .whereNull("sound")
        .update({ sound: true });
    });
  },
};
