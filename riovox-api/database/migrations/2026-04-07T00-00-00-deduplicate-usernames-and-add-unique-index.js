module.exports = {
  async up(knex) {
    const duplicates = await knex.raw(`
      SELECT LOWER(username) AS lower_username
      FROM up_users
      WHERE username IS NOT NULL
      GROUP BY LOWER(username)
      HAVING COUNT(*) > 1
    `);

    for (const group of duplicates.rows) {
      const users = await knex("up_users")
        .whereRaw("LOWER(username) = ?", [group.lower_username])
        .orderByRaw(`
          CASE WHEN points IS NOT NULL AND points > 0 THEN 0 ELSE 1 END ASC,
          CASE WHEN password IS NOT NULL AND password != '' THEN 0 ELSE 1 END ASC,
          created_at DESC
        `);

      for (let i = 1; i < users.length; i++) {
        const suffix = i === 1 ? "_dup" : `_dup${i}`;
        await knex("up_users")
          .where("id", users[i].id)
          .update({ username: `${users[i].username}${suffix}` });
      }
    }

    await knex.raw(`
      CREATE UNIQUE INDEX up_users_username_unique
      ON up_users (LOWER(username))
      WHERE username IS NOT NULL
    `);
  },

  async down(knex) {
    await knex.raw("DROP INDEX IF EXISTS up_users_username_unique");
  },
};
