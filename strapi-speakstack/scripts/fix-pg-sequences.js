#!/usr/bin/env node
"use strict";

/**
 * After restoring local-strapi1.sql, PostgreSQL id sequences can lag behind
 * MAX(id). Strapi then fails on startup with duplicate key on admin_permissions.
 *
 * Usage: node scripts/fix-pg-sequences.js
 * Requires DATABASE_* env vars (loads .env via Strapi config).
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

async function main() {
  await knex.raw(`
    DO $$
    DECLARE
      r RECORD;
      max_id bigint;
    BEGIN
      FOR r IN
        SELECT
          quote_ident(n.nspname) || '.' || quote_ident(t.relname) AS table_name,
          quote_ident(n.nspname) || '.' || quote_ident(s.relname) AS seq_name
        FROM pg_class t
        JOIN pg_namespace n ON n.oid = t.relnamespace
        JOIN pg_depend d ON d.refobjid = t.oid AND d.deptype = 'a'
        JOIN pg_class s ON s.oid = d.objid AND s.relkind = 'S'
        WHERE t.relkind = 'r' AND n.nspname = 'public'
      LOOP
        EXECUTE format('SELECT COALESCE(MAX(id), 0) FROM %s', r.table_name) INTO max_id;
        IF max_id > 0 THEN
          EXECUTE format('SELECT setval(%L, %s, true)', r.seq_name, max_id);
        END IF;
      END LOOP;
    END $$;
  `);
  console.log("All public id sequences synced to MAX(id).");
}

main()
  .catch((err) => {
    console.error(err);
    process.exit(1);
  })
  .finally(() => knex.destroy());
