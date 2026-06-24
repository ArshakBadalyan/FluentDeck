#!/usr/bin/env node
"use strict";

/**
 * Drops legacy MatheApp database tables (Postgres).
 *
 * Usage:
 *   cd strapi-math
 *   DROP_LEGACY_MATH_TABLES=true npm run develop
 *   # or once:
 *   node scripts/drop-legacy-math-tables.js
 */

require("dotenv").config({ path: require("path").join(__dirname, "..", ".env") });

const LEGACY_TABLES = [
  "answers",
  "assignments",
  "assignment_solution_peeks",
  "categories",
  "category_classes",
  "classrooms",
  "classroom_members",
  "institutions",
  "parents_emails",
  "practice_results",
  "question_reports",
  "questions",
  "user_answers",
  "answers_question_links",
  "assignments_classroom_links",
  "categories_category_class_links",
  "classrooms_students_links",
  "classrooms_teacher_links",
  "classroom_members_classroom_links",
  "classroom_members_user_links",
  "institutions_users_links",
  "parents_emails_users_permissions_users_links",
  "practice_results_users_permissions_user_links",
  "question_reports_users_permissions_user_links",
  "question_reports_question_links",
  "questions_category_links",
  "user_answers_users_permissions_user_links",
  "user_answers_question_links",
  "up_users_institution_links",
];

async function dropLegacyTables(knex) {
  let dropped = 0;
  for (const table of LEGACY_TABLES) {
    const exists = await knex.schema.hasTable(table);
    if (!exists) continue;
    await knex.raw(`DROP TABLE IF EXISTS ?? CASCADE`, [table]);
    dropped += 1;
    console.log(`Dropped ${table}`);
  }
  return dropped;
}

async function runStandalone() {
  const knex = require("knex")({
    client: process.env.DATABASE_CLIENT || "postgres",
    connection: {
      host: process.env.DATABASE_HOST || "127.0.0.1",
      port: Number(process.env.DATABASE_PORT || 5432),
      database: process.env.DATABASE_NAME || "english",
      user: process.env.DATABASE_USERNAME || "postgres",
      password: process.env.DATABASE_PASSWORD || "",
      ssl: process.env.DATABASE_SSL === "true" ? { rejectUnauthorized: false } : false,
    },
  });

  try {
    const dropped = await dropLegacyTables(knex);
    console.log(`Done. Dropped ${dropped} legacy table(s).`);
  } finally {
    await knex.destroy();
  }
}

module.exports = { dropLegacyTables, LEGACY_TABLES };

if (require.main === module) {
  runStandalone().catch((err) => {
    console.error(err.message || err);
    process.exit(1);
  });
}
