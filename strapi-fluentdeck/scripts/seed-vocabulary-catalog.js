#!/usr/bin/env node
"use strict";

/**
 * Seeds the vocabulary catalog (Library > Words tab) from
 * src/utils/seed-data/vocabulary-catalog.json — ~11k entries derived from the
 * Langeek A1-C1 wordlists (real definitions/IPA/topics) plus CEFR-J/Oxford CSV
 * gap words extended to C2 (AI-completed definitions where the source had none).
 *
 * Idempotent: dedups by externalId (pre-fetches existing ones into a Set, so a
 * re-run only inserts what's missing). Also retires the old 24-word
 * `placement-seed` placeholder rows once real data covers the catalog.
 *
 * Usage: cd strapi-fluentdeck && node scripts/seed-vocabulary-catalog.js
 */

const path = require("path");
const fs = require("fs");
require("dotenv").config({ path: path.join(__dirname, "..", ".env") });

const UID = "api::vocabulary-entry.vocabulary-entry";
const DATA_PATH = path.join(__dirname, "..", "src", "utils", "seed-data", "vocabulary-catalog.json");
const CHUNK_SIZE = 50;

async function main() {
  const { createStrapi } = require("@strapi/strapi");
  const strapi = await createStrapi({ appDir: path.join(__dirname, "..") }).load();

  try {
    const entries = JSON.parse(fs.readFileSync(DATA_PATH, "utf-8"));
    console.log(`Loaded ${entries.length} entries from seed data file.`);

    const existing = await strapi.db.query(UID).findMany({ fields: ["externalId"] });
    const existingIds = new Set(existing.map((e) => e.externalId).filter(Boolean));
    console.log(`Existing rows in DB: ${existing.length} (${existingIds.size} with externalId).`);

    const toCreate = entries.filter((e) => !existingIds.has(e.externalId));
    console.log(`New entries to insert: ${toCreate.length} (skipping ${entries.length - toCreate.length} already present).`);

    const now = new Date();
    let created = 0;
    for (let i = 0; i < toCreate.length; i += CHUNK_SIZE) {
      const chunk = toCreate.slice(i, i + CHUNK_SIZE);
      await Promise.all(
        chunk.map((e) =>
          strapi.db.query(UID).create({
            data: {
              word: e.word,
              lemma: e.lemma,
              entryType: e.entryType,
              partOfSpeech: e.partOfSpeech,
              definition: e.definition,
              exampleSentence: e.exampleSentence || null,
              ipa: e.ipa || null,
              audioUrl: null,
              cefrLevel: e.cefrLevel,
              topic: e.topic || null,
              frequencyRank: e.frequencyRank,
              frequencyBucket: e.frequencyBucket,
              sensePriority: e.sensePriority,
              source: e.source,
              externalId: e.externalId,
              publishedAt: now,
            },
          }),
        ),
      );
      created += chunk.length;
      if (created % 500 === 0 || created === toCreate.length) {
        console.log(`  inserted ${created}/${toCreate.length}...`);
      }
    }

    console.log(`Done. Created ${created} new vocabulary entries.`);

    if (created > 1000) {
      const removed = await strapi.db.query(UID).deleteMany({
        where: { source: "placement-seed" },
      });
      console.log(`Retired old placement-seed placeholder rows: ${removed?.count ?? 0}`);
    }

    const finalCount = await strapi.db.query(UID).count({ where: { publishedAt: { $notNull: true } } });
    console.log(`Total published vocabulary entries now: ${finalCount}`);
  } finally {
    await strapi.destroy();
  }
}

main().catch((err) => {
  console.error("FATAL:", err);
  process.exit(1);
});
