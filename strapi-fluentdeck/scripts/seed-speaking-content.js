#!/usr/bin/env node
"use strict";

/**
 * Seeds role-play scenarios, speaking topics, and games via the Strapi REST API.
 *
 * Role-play rows are upserted by title (skips existing titles).
 * Topics are upserted by title. Games are upserted by slug.
 *
 * Usage:
 *   cd strapi-fluentdeck
 *   STRAPI_API_TOKEN=your_token node scripts/seed-speaking-content.js
 */

require("dotenv").config({ path: require("path").join(__dirname, "..", ".env") });

const {
  ROLE_PLAY_SCENARIOS,
  SPEAKING_TOPICS,
  SPEAKING_GAMES,
} = require("../src/utils/seed-speaking-content");

const STRAPI_URL = (process.env.STRAPI_URL || "http://localhost:1337").replace(
  /\/$/,
  "",
);
const TOKEN = process.env.STRAPI_API_TOKEN || process.env.STRAPI_TOKEN;

async function api(path, { method = "GET", body } = {}) {
  let res;
  try {
    res = await fetch(`${STRAPI_URL}/api/${path}`, {
      method,
      headers: {
        "Content-Type": "application/json",
        ...(TOKEN ? { Authorization: `Bearer ${TOKEN}` } : {}),
      },
      body: body ? JSON.stringify(body) : undefined,
    });
  } catch (err) {
    throw new Error(
      `Cannot reach ${STRAPI_URL} — is Strapi running? (${err.message})`,
    );
  }

  const text = await res.text();
  let json;
  try {
    json = text ? JSON.parse(text) : null;
  } catch {
    json = { raw: text };
  }

  if (!res.ok) {
    const msg = json?.error?.message || res.statusText;
    throw new Error(`${method} /api/${path} → ${res.status}: ${msg}`);
  }
  return json;
}

async function existsByTitle(collection, title) {
  const q = encodeURIComponent(title);
  const data = await api(
    `${collection}?filters[title][$eq]=${q}&pagination[pageSize]=1`,
  );
  return (data?.data?.length ?? 0) > 0;
}

async function collectionEmpty(collection) {
  const data = await api(`${collection}?pagination[pageSize]=1`);
  return (data?.data?.length ?? 0) === 0;
}

async function createPublished(collection, data) {
  await api(collection, {
    method: "POST",
    body: {
      data: {
        ...data,
        publishedAt: new Date().toISOString(),
      },
    },
  });
}

async function seedRolePlays() {
  let created = 0;
  for (const item of ROLE_PLAY_SCENARIOS) {
    const exists = await existsByTitle("conversation-prompts", item.title);
    if (exists) {
      console.log(`Skip role-play (exists): ${item.title}`);
      continue;
    }
    await createPublished("conversation-prompts", item);
    created += 1;
    console.log(`Created role-play: ${item.title}`);
  }
  return created;
}

async function seedTopics() {
  let created = 0;
  for (const item of SPEAKING_TOPICS) {
    const exists = await existsByTitle("speaking-topics", item.title);
    if (exists) {
      console.log(`Skip topic (exists): ${item.title}`);
      continue;
    }
    await createPublished("speaking-topics", item);
    created += 1;
    console.log(`Created topic: ${item.title}`);
  }
  return created;
}

async function seedTopicsIfEmpty() {
  if (!(await collectionEmpty("speaking-topics"))) {
    console.log("Topics collection not empty — upserting missing titles...");
    return seedTopics();
  }
  for (const item of SPEAKING_TOPICS) {
    await createPublished("speaking-topics", item);
    console.log(`Created topic: ${item.title}`);
  }
  return SPEAKING_TOPICS.length;
}

async function existsBySlug(collection, slug) {
  const q = encodeURIComponent(slug);
  const data = await api(
    `${collection}?filters[slug][$eq]=${q}&pagination[pageSize]=1`,
  );
  return (data?.data?.length ?? 0) > 0;
}

async function seedGames() {
  let created = 0;
  for (const item of SPEAKING_GAMES) {
    const exists = await existsBySlug("speaking-games", item.slug);
    if (exists) {
      console.log(`Skip game (exists): ${item.title}`);
      continue;
    }
    await createPublished("speaking-games", item);
    created += 1;
    console.log(`Created game: ${item.title}`);
  }
  return created;
}

async function seedGamesIfEmpty() {
  if (!(await collectionEmpty("speaking-games"))) {
    console.log("Games collection not empty — upserting missing slugs...");
    return seedGames();
  }
  for (const item of SPEAKING_GAMES) {
    await createPublished("speaking-games", item);
    console.log(`Created game: ${item.title}`);
  }
  return SPEAKING_GAMES.length;
}

async function run() {
  if (!TOKEN) {
    console.error("Set STRAPI_API_TOKEN (Settings → API Tokens → Full access).");
    process.exit(1);
  }

  console.log(`Seeding speaking content at ${STRAPI_URL} ...\n`);

  const rolePlays = await seedRolePlays();
  const topics = await seedTopicsIfEmpty();
  const games = await seedGamesIfEmpty();

  console.log(
    `\nDone. Created ${rolePlays} role-play(s), ${topics} topic(s), ${games} game(s).`,
  );
}

run().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
