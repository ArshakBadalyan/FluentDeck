#!/usr/bin/env node
"use strict";

/**
 * Seeds sample English lessons via the Strapi REST API.
 *
 * Prefer bootstrap seeding (automatic on `npm run develop` when lessons table is empty).
 * Use this script only when Strapi is already running and you need to re-seed via API.
 *
 * The API token must be "Full access" OR have create+find on lessons and exercises.
 *
 * Usage:
 *   cd strapi-math
 *   STRAPI_API_TOKEN=your_token node scripts/seed-lessons.js
 */

require("dotenv").config({ path: require("path").join(__dirname, "..", ".env") });

const { SAMPLE_LESSONS } = require("../src/utils/seed-english-lessons");

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
    const hint =
      res.status === 401
        ? " Use a Full Access API token (Settings → API Tokens), or rely on bootstrap seed on Strapi start."
        : "";
    throw new Error(`${method} /api/${path} → ${res.status}: ${msg}.${hint}`);
  }
  return json;
}

async function lessonExists(title) {
  const q = encodeURIComponent(title);
  const data = await api(
    `lessons?filters[title][$eq]=${q}&pagination[pageSize]=1`,
  );
  return (data?.data?.length ?? 0) > 0;
}

async function createLesson(lesson) {
  const exists = await lessonExists(lesson.title);
  if (exists) {
    console.log(`Skip (exists): ${lesson.title}`);
    return;
  }

  const { exercises, ...lessonFields } = lesson;
  const created = await api("lessons", {
    method: "POST",
    body: {
      data: {
        ...lessonFields,
        publishedAt: new Date().toISOString(),
      },
    },
  });

  const lessonId = created?.data?.id;
  if (!lessonId) {
    throw new Error(`Lesson created but no id returned for "${lesson.title}"`);
  }

  console.log(`Created lesson #${lessonId}: ${lesson.title}`);

  for (const exercise of exercises) {
    await api("exercises", {
      method: "POST",
      body: {
        data: {
          ...exercise,
          lesson: lessonId,
          publishedAt: new Date().toISOString(),
        },
      },
    });
    console.log(`  + exercise (${exercise.type})`);
  }
}

async function run() {
  if (!TOKEN) {
    console.error(
      "Set STRAPI_API_TOKEN — or restart Strapi to auto-seed when no lessons exist.",
    );
    process.exit(1);
  }

  console.log(`Seeding lessons at ${STRAPI_URL} ...\n`);

  for (const lesson of SAMPLE_LESSONS) {
    await createLesson(lesson);
  }

  console.log("\nDone.");
}

run().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
