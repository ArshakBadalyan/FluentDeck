#!/usr/bin/env node
"use strict";

/**
 * Removes legacy mock vocabulary entries (source=cefr-j) via Strapi REST API.
 *
 * Usage:
 *   cd strapi-fluentdeck
 *   STRAPI_API_TOKEN=your_token node scripts/clear-vocabulary-mock.js
 */

require("dotenv").config({ path: require("path").join(__dirname, "..", ".env") });

const STRAPI_URL = (process.env.STRAPI_URL || "http://localhost:1337").replace(/\/$/, "");
const TOKEN = process.env.STRAPI_API_TOKEN || process.env.STRAPI_TOKEN;

async function api(path, { method = "GET", body } = {}) {
  const res = await fetch(`${STRAPI_URL}/api/${path}`, {
    method,
    headers: {
      "Content-Type": "application/json",
      ...(TOKEN ? { Authorization: `Bearer ${TOKEN}` } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let json;
  try {
    json = text ? JSON.parse(text) : null;
  } catch {
    json = { raw: text };
  }
  if (!res.ok) {
    throw new Error(`${method} /api/${path} → ${res.status}: ${json?.error?.message || res.statusText}`);
  }
  return json;
}

async function run() {
  if (!TOKEN) {
    console.error("Set STRAPI_API_TOKEN in .env");
    process.exit(1);
  }

  let page = 1;
  let deleted = 0;

  while (true) {
    const data = await api(
      `vocabulary-entries?filters[source][$eq]=cefr-j&pagination[page]=${page}&pagination[pageSize]=100&fields[0]=id&fields[1]=word`,
    );
    const rows = data?.data ?? [];
    if (!rows.length) break;

    for (const row of rows) {
      await api(`vocabulary-entries/${row.id}`, { method: "DELETE" });
      deleted += 1;
      const word = row.attributes?.word ?? row.word ?? row.id;
      console.log(`Deleted: ${word} (#${row.id})`);
    }

    if (rows.length < 100) break;
    page += 1;
  }

  console.log(`\nDone. Deleted ${deleted} mock vocabulary entries.`);
}

run().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
