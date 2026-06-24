#!/usr/bin/env node
"use strict";

/**
 * Validates tutor prompt output without starting Strapi.
 * Usage: cd strapi-math && node scripts/test-ai-tutor.js
 */

require("dotenv").config({ path: require("path").join(__dirname, "..", ".env") });

const { getTutorReply } = require("../src/utils/ai-tutor");

const TEST_MESSAGES = [
  { label: "past tense + article", message: "I go to store yesterday" },
  { label: "clean greeting", message: "Hello! I'm fine, thanks." },
  { label: "low effort", message: "Yes" },
  { label: "gerund error", message: "I am liking to travel very much" },
  { label: "topic change", message: "Can we talk about movies?" },
  { label: "subject-verb", message: "She don't like coffee" },
  { label: "perfect tense", message: "I have went to Paris last year" },
  { label: "word order", message: "What means this word?" },
];

async function run() {
  if (!process.env.OPENAI_API_KEY) {
    console.error("OPENAI_API_KEY missing in .env");
    process.exit(1);
  }

  let passed = 0;
  for (const test of TEST_MESSAGES) {
    process.stdout.write(`\n--- ${test.label} ---\n`);
    try {
      const { reply, corrections } = await getTutorReply({
        message: test.message,
        history: [],
        userLevel: "B1",
        weakAreas: [],
      });
      const ok =
        typeof reply === "string" &&
        reply.trim().length > 0 &&
        !/CORRECTIONS_JSON:/i.test(reply) &&
        Array.isArray(corrections);
      if (ok) passed += 1;
      console.log("User:", test.message);
      console.log("Reply:", reply);
      console.log("Corrections:", JSON.stringify(corrections, null, 2));
      console.log(ok ? "PASS" : "FAIL (empty reply or invalid corrections)");
    } catch (error) {
      console.error("FAIL:", error.message);
    }
  }

  console.log(`\n${passed}/${TEST_MESSAGES.length} cases returned valid structure.`);
  process.exit(passed === TEST_MESSAGES.length ? 0 : 1);
}

run();
