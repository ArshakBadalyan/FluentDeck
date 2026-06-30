/*    "createdAt": "........................",
    "updatedAt": "........................",
    "publishedAt": "........................",*/

module.exports = {
  async up(knex) {
    await knex.schema.hasColumn("up_users", "volume_sound").then(async (exists) => {
      if (!exists) {
        await knex.schema.table("up_users", (table) => {
          table.integer("volume_sound");
        });
      }

      await knex
        .from("up_users")
        .whereNull("volume_sound")
        .update({ volume_sound: 50 });
    });

    await knex.schema.hasColumn("up_users", "volume_music").then(async (exists) => {
      if (!exists) {
        await knex.schema.table("up_users", (table) => {
          table.integer("volume_music");
        });
      }

      await knex
        .from("up_users")
        .whereNull("volume_music")
        .update({ volume_music: 50 });
    });

    await knex.schema.hasColumn("up_users", "music").then(async (exists) => {
      if (!exists) {
        await knex.schema.table("up_users", (table) => {
          table.boolean("music");
        });
      }

      await knex
        .from("up_users")
        .whereNull("music")
        .update({ music: true });
    });
  },
};

