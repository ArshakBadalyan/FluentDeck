#!/usr/bin/env node
"use strict";

/**
 * Deletes ALL vocabulary catalog rows and related user progress/links.
 *
 * Usage:
 *   cd strapi-speakstack
 *   node scripts/clear-all-vocabulary.js
 *
 * Requires DATABASE_* in .env (same as fix-pg-sequences.js).
 */

const path = require("path");
const dotenv = require("dotenv");

dotenv.config({ path: path.join(__dirname, "..", ".env") });

const knex = require("knex")({
  client: "postgres",
  connection: {
    host: process.env.DATABASE_HOST,
    port: Number(process.env.DATABASE_PORT || 5432),
    database: process.env.DATABASE_NAME,
    user: process.env.DATABASE_USERNAME,
    password: process.env.DATABASE_PASSWORD,
    ssl: false,
  },
});

async function tableExists(name) {
  return knex.schema.hasTable(name);
}

async function clearTable(name) {
  if (!(await tableExists(name))) return 0;
  const deleted = await knex(name).del();
  return deleted;
}

async function main() {
  const before = await knex("vocabulary_entries").count("* as count").first();
  const beforeCount = Number(before?.count ?? 0);
  console.log(`Vocabulary entries before: ${beforeCount}`);

  const progressLinks = await clearTable("user_vocabulary_progresses_vocabulary_entry_links");
  const progressRows = await clearTable("user_vocabulary_progresses");
  const noteLinks = await clearTable("user_notes_vocabulary_entry_links");
  const entries = await clearTable("vocabulary_entries");

  await knex.raw(`
    SELECT setval(
      pg_get_serial_sequence('vocabulary_entries', 'id'),
      COALESCE((SELECT MAX(id) FROM vocabulary_entries), 1),
      (SELECT COUNT(*) > 0 FROM vocabulary_entries)
    )
  `);

  const after = await knex("vocabulary_entries").count("* as count").first();
  const afterCount = Number(after?.count ?? 0);

  console.log(`Removed ${progressLinks} progress link(s)`);
  console.log(`Removed ${progressRows} progress row(s)`);
  console.log(`Removed ${noteLinks} user-note link(s)`);
  console.log(`Removed ${entries} vocabulary entr(ies)`);
  console.log(`Vocabulary entries after: ${afterCount}`);

  if (afterCount !== 0) {
    throw new Error(`Expected 0 vocabulary entries, found ${afterCount}`);
  }
}

main()
  .catch((err) => {
    console.error(err.message || err);
    process.exit(1);
  })
  .finally(() => knex.destroy());
