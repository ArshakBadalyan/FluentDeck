"use strict";

/**
 * Extend vocabulary_entries for atomic senses and remove legacy mock seed rows.
 */

async function hasColumn(knex, table, column) {
  return knex.schema.hasColumn(table, column);
}

async function addColumnIfMissing(knex, table, column, builder) {
  if (!(await hasColumn(knex, table, column))) {
    await knex.schema.table(table, (t) => builder(t, column));
  }
}

module.exports = {
  async up(knex) {
    const table = "vocabulary_entries";

    if (!(await knex.schema.hasTable(table))) {
      return;
    }

    await addColumnIfMissing(knex, table, "lemma", (t, col) => {
      t.string(col);
    });
    await addColumnIfMissing(knex, table, "part_of_speech", (t, col) => {
      t.string(col);
    });
    await addColumnIfMissing(knex, table, "examples", (t, col) => {
      t.json(col);
    });
    await addColumnIfMissing(knex, table, "ipa", (t, col) => {
      t.string(col);
    });
    await addColumnIfMissing(knex, table, "audio_url", (t, col) => {
      t.string(col);
    });
    await addColumnIfMissing(knex, table, "frequency_bucket", (t, col) => {
      t.string(col);
    });
    await addColumnIfMissing(knex, table, "sense_priority", (t, col) => {
      t.string(col);
    });
    await addColumnIfMissing(knex, table, "external_id", (t, col) => {
      t.string(col);
    });

    if (await hasColumn(knex, table, "external_id")) {
      await knex.raw(`
        CREATE UNIQUE INDEX IF NOT EXISTS vocabulary_entries_external_id_unique
        ON ${table} (external_id)
        WHERE external_id IS NOT NULL
      `);
    }

    const progressTable = "user_vocabulary_progress";
    if (await knex.schema.hasTable(progressTable)) {
      const mockEntryIds = await knex(table)
        .where({ source: "cefr-j" })
        .pluck("id");

      if (mockEntryIds.length > 0) {
        await knex(progressTable)
          .whereIn("vocabulary_entry_id", mockEntryIds)
          .del();
      }
    }

    await knex(table).where({ source: "cefr-j" }).del();
  },
};
