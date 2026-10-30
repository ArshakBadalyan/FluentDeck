#!/usr/bin/env node
"use strict";

/**
 * Guards against a recurring crash: this project carries ~60 legacy migration
 * files inherited from the app this was rebranded from (categories/questions/
 * answers/classrooms/assignments — none of which have a matching content-type
 * in the current codebase). Strapi's migration runner replays every migration
 * that isn't recorded in `strapi_migrations`, in order, BEFORE it creates any
 * content-type tables. On a fresh or fully-wiped database that means it always
 * crashes on the very first legacy migration (`INSERT INTO "categories"` when
 * no "categories" table will ever exist).
 *
 * On a genuinely fresh database there is no legacy data for these migrations
 * to act on anyway — every current table is built directly from this
 * project's schema.json files right after migrations run. So when this script
 * detects a fresh database (no `up_users` table yet — created by the
 * users-permissions plugin on first successful boot, a reliable "has this app
 * ever initialized" signal), it fast-forwards every migration file as
 * already-applied instead of executing it. On an already-initialized database
 * this script is a complete no-op.
 *
 * Wired into `npm run develop` / `npm run start` so this self-heals
 * automatically — no manual intervention needed after wiping the database.
 */

const fs = require("fs");
const path = require("path");
const { Client } = require("pg");

require("dotenv").config({ path: path.join(__dirname, "..", ".env") });

async function tableExists(client, tableName) {
  const res = await client.query(
    `SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = $1`,
    [tableName],
  );
  return res.rowCount > 0;
}

async function main() {
  const client = new Client({
    host: process.env.DATABASE_HOST,
    port: process.env.DATABASE_PORT,
    database: process.env.DATABASE_NAME,
    user: process.env.DATABASE_USERNAME,
    password: process.env.DATABASE_PASSWORD,
    ssl:
      process.env.ENVIRONMENT === "production"
        ? { rejectUnauthorized: process.env.DATABASE_SSL_SELF === "true" }
        : false,
  });

  try {
    await client.connect();
  } catch (e) {
    console.warn(`[migrations-baseline] Could not connect to database, skipping: ${e.message}`);
    return;
  }

  try {
    const initialized = await tableExists(client, "up_users");
    if (initialized) {
      return;
    }

    console.log(
      "[migrations-baseline] Fresh database detected (no up_users table yet) — fast-forwarding legacy migrations.",
    );

    await client.query(`
      CREATE TABLE IF NOT EXISTS strapi_migrations (
        id SERIAL PRIMARY KEY,
        time TIMESTAMP,
        name VARCHAR(255)
      )
    `);

    const migrationsDir = path.join(__dirname, "..", "database", "migrations");
    const files = fs
      .readdirSync(migrationsDir)
      .filter((f) => f.endsWith(".js"))
      .sort();

    const { rows: existing } = await client.query("SELECT name FROM strapi_migrations");
    const alreadyRecorded = new Set(existing.map((r) => r.name));

    let inserted = 0;
    for (const name of files) {
      if (alreadyRecorded.has(name)) continue;
      await client.query("INSERT INTO strapi_migrations (name, time) VALUES ($1, NOW())", [name]);
      inserted += 1;
    }

    console.log(`[migrations-baseline] Fast-forwarded ${inserted} legacy migration(s).`);
  } catch (e) {
    console.warn(`[migrations-baseline] Skipped: ${e.message}`);
  } finally {
    await client.end();
  }
}

main();
