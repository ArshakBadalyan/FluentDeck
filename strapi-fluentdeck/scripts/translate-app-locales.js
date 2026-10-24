#!/usr/bin/env node
"use strict";

/**
 * Translates the Flutter app's interface strings
 * (fluentdeck-f/assets/locales/en.json) into every app language.
 * Incremental: only keys missing from a language file are sent, so re-run it
 * whenever new keys are added to en.json. See docs/app-languages.md.
 *
 * Usage (from strapi-fluentdeck/, uses OPENAI_API_KEY from .env):
 *   node scripts/translate-app-locales.js --dry-run       # what would be sent
 *   node scripts/translate-app-locales.js                 # all languages
 *   node scripts/translate-app-locales.js --langs=es,tr   # some languages
 *   node scripts/translate-app-locales.js --model=gpt-4.1 --all   # redo everything
 *
 * Free, on this machine (Ollama, no API key):
 *   node scripts/translate-app-locales.js --local                # qwen2.5:14b
 *   node scripts/translate-app-locales.js --local --model=qwen2.5:latest --langs=es --limit=20
 *   (--base-url=<OpenAI-compatible URL> works for LM Studio etc.)
 *
 * Strings whose {placeholders} don't survive translation are left out and the
 * app falls back to English for them; the run lists them.
 */

const fs = require("fs");
const path = require("path");

const LOCALES_DIR = path.join(__dirname, "..", "..", "fluentdeck-f", "assets", "locales");
const SOURCE = "en";
const BATCH_SIZE = 120;
/** Local models: Ollama's default context is ~4k tokens, so keep batches small. */
const LOCAL_BATCH_SIZE = 20;
const OLLAMA_URL = "http://localhost:11434/v1";

/** Must match AppLanguage.options in fluentdeck-f/lib/config/app_language.dart. */
const LANGUAGES = {
  es: { name: "Spanish", style: "Latin-American-neutral Spanish, informal \"tú\"" },
  pt: { name: "Brazilian Portuguese", style: "Brazilian Portuguese, informal \"você\"" },
  tr: { name: "Turkish", style: "informal \"sen\"" },
  ru: { name: "Russian", style: "informal \"ты\", as in popular learning apps" },
  vi: { name: "Vietnamese", style: "friendly, \"bạn\"" },
  id: { name: "Indonesian", style: "casual-friendly \"kamu\"" },
  ja: { name: "Japanese", style: "polite です/ます form, natural app UI wording" },
  ko: { name: "Korean", style: "polite 해요체, natural app UI wording" },
  ar: { name: "Arabic", style: "Modern Standard Arabic, friendly" },
  de: { name: "German", style: "informal \"du\"" },
};

const PLACEHOLDER = /\{[^{}]*\}/g;

/** Letters each non-Latin language must be written in. */
const SCRIPTS = {
  ru: /\p{Script=Cyrillic}/u,
  hy: /\p{Script=Armenian}/u,
  ja: /[\p{Script=Hiragana}\p{Script=Katakana}\p{Script=Han}]/u,
  ko: /\p{Script=Hangul}/u,
  ar: /\p{Script=Arabic}/u,
};
const CJK = /[\p{Script=Han}\p{Script=Hiragana}\p{Script=Katakana}\p{Script=Hangul}]/u;

/**
 * Rejects text in the wrong writing system — local models sometimes slip
 * Chinese into other languages, or leave a string in English.
 */
function matchesScript(lang, source, translated) {
  if (typeof translated !== "string") return false;
  const letters = String(source).replace(PLACEHOLDER, "");
  if (!/\p{L}{2}/u.test(letters)) return true; // "OK", "A1", emoji, numbers
  const required = SCRIPTS[lang];
  if (required && !required.test(translated)) return false;
  if (lang !== "ja" && lang !== "ko" && CJK.test(translated)) return false;
  return true;
}

/** { "a.b.c": "text" } for every string leaf (arrays use numeric segments). */
function flatten(obj, prefix = "", out = {}) {
  if (Array.isArray(obj)) {
    obj.forEach((v, i) => flatten(v, prefix ? `${prefix}.${i}` : String(i), out));
  } else if (obj && typeof obj === "object") {
    for (const [k, v] of Object.entries(obj)) {
      flatten(v, prefix ? `${prefix}.${k}` : k, out);
    }
  } else if (typeof obj === "string") {
    out[prefix] = obj;
  }
  return out;
}

/**
 * Rebuilds [source]'s shape and key order, taking strings from [flat].
 * A list is written only when every item is translated — the app can read a
 * whole list at once, so a half-filled one would show blanks; until then the
 * English list is used.
 */
function unflattenLike(source, flat, prefix = "") {
  if (Array.isArray(source)) {
    const items = source.map((v, i) => unflattenLike(v, flat, prefix ? `${prefix}.${i}` : String(i)));
    return items.some((v) => v === undefined) ? undefined : items;
  }
  if (source && typeof source === "object") {
    const out = {};
    for (const [k, v] of Object.entries(source)) {
      const child = unflattenLike(v, flat, prefix ? `${prefix}.${k}` : k);
      if (child !== undefined) out[k] = child;
    }
    return Object.keys(out).length ? out : undefined;
  }
  return Object.prototype.hasOwnProperty.call(flat, prefix) ? flat[prefix] : undefined;
}

function placeholders(text) {
  return (String(text).match(PLACEHOLDER) || []).sort().join("|");
}

/** True when [translated] keeps exactly the source's {placeholders}. */
function keepsPlaceholders(source, translated) {
  return (
    typeof translated === "string" &&
    translated.trim() !== "" &&
    placeholders(source) === placeholders(translated)
  );
}

/** Keys to translate: missing (or all with [all]), in source order. */
function keysToTranslate(sourceFlat, targetFlat, { all = false } = {}) {
  return Object.keys(sourceFlat).filter(
    (k) => all || !Object.prototype.hasOwnProperty.call(targetFlat, k),
  );
}

function chunk(list, size) {
  const out = [];
  for (let i = 0; i < list.length; i += size) out.push(list.slice(i, i + size));
  return out;
}

function systemPrompt(lang) {
  const { name, style } = LANGUAGES[lang];
  return [
    `You translate the interface of FluentDeck, a mobile app for practising speaking a language with an AI tutor and learning words with flashcards, from English into ${name} (${style}).`,
    "Return JSON: {\"translations\": {\"<key>\": \"<translation>\"}} with exactly the keys you were given.",
    "Rules:",
    "- Keep every {placeholder} exactly as written (same name, same braces); move it where the grammar needs it.",
    "- Keep brand and product names unchanged: FluentDeck, Premium, Anki, Google, Apple, AI.",
    "- Keep CEFR levels (A1–C2), numbers, emoji, URLs and markdown/HTML tags unchanged.",
    "- Short UI labels stay short (buttons, tabs). Use the terms native mobile apps use (e.g. Settings, Log out).",
    "- Sentence case where the language uses it. No explanations, no quotes around values.",
  ].join("\n");
}

async function translateBatch(client, model, lang, entries) {
  const response = await client.chat.completions.create({
    model,
    temperature: 0.2,
    response_format: { type: "json_object" },
    messages: [
      { role: "system", content: systemPrompt(lang) },
      { role: "user", content: JSON.stringify(Object.fromEntries(entries)) },
    ],
  });
  const parsed = JSON.parse(response.choices?.[0]?.message?.content || "{}");
  return parsed.translations && typeof parsed.translations === "object" ? parsed.translations : {};
}

function readJson(file) {
  return fs.existsSync(file) ? JSON.parse(fs.readFileSync(file, "utf8")) : {};
}

function parseArgs(argv) {
  const args = {
    dryRun: false,
    all: false,
    model: null,
    baseUrl: null,
    batch: null,
    limit: null,
    langs: Object.keys(LANGUAGES),
  };
  for (const a of argv) {
    if (a === "--dry-run") args.dryRun = true;
    else if (a === "--all") args.all = true;
    else if (a === "--local") args.baseUrl = OLLAMA_URL;
    else if (a.startsWith("--base-url=")) args.baseUrl = a.slice(11);
    else if (a.startsWith("--batch=")) args.batch = Number(a.slice(8));
    else if (a.startsWith("--limit=")) args.limit = Number(a.slice(8));
    else if (a.startsWith("--model=")) args.model = a.slice(8);
    else if (a.startsWith("--langs=")) args.langs = a.slice(8).split(",").map((s) => s.trim()).filter(Boolean);
  }
  const unknown = args.langs.filter((l) => !LANGUAGES[l]);
  if (unknown.length) throw new Error(`Unknown language(s): ${unknown.join(", ")}`);
  args.model ||= args.baseUrl ? "qwen2.5:14b" : "gpt-4.1";
  args.batch ||= args.baseUrl ? LOCAL_BATCH_SIZE : BATCH_SIZE;
  return args;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const source = readJson(path.join(LOCALES_DIR, `${SOURCE}.json`));
  const sourceFlat = flatten(source);

  let client = null;
  if (!args.dryRun) {
    const OpenAI = require("openai");
    if (args.baseUrl) {
      // Local server (Ollama / LM Studio): no key needed.
      client = new OpenAI({ baseURL: args.baseUrl, apiKey: "local" });
    } else {
      require("dotenv").config({ path: path.join(__dirname, "..", ".env") });
      if (!process.env.OPENAI_API_KEY) throw new Error("OPENAI_API_KEY is not set in strapi-fluentdeck/.env");
      client = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
    }
    console.log(`model ${args.model}${args.baseUrl ? ` @ ${args.baseUrl}` : ""}, batches of ${args.batch}`);
  }

  for (const lang of args.langs) {
    const file = path.join(LOCALES_DIR, `${lang}.json`);
    const targetFlat = args.all ? {} : flatten(readJson(file));
    // Drop keys no longer in English, so files don't accumulate stale text.
    for (const k of Object.keys(targetFlat)) if (!(k in sourceFlat)) delete targetFlat[k];
    let keys = keysToTranslate(sourceFlat, targetFlat, args);
    if (args.limit) keys = keys.slice(0, args.limit);
    console.log(`${lang} (${LANGUAGES[lang].name}): ${keys.length} to translate`);
    if (args.dryRun || keys.length === 0) continue;

    const ok = (k, text) =>
      keepsPlaceholders(sourceFlat[k], text) && matchesScript(lang, sourceFlat[k], text);
    const attempt = async (batch) => {
      try {
        return await translateBatch(client, args.model, lang, batch.map((k) => [k, sourceFlat[k]]));
      } catch (err) {
        console.warn(`  batch failed: ${err.message}`);
        return {};
      }
    };

    const rejected = [];
    const batches = chunk(keys, args.batch);
    const started = Date.now();
    for (const [i, batch] of batches.entries()) {
      const result = await attempt(batch);
      // Retry once whatever came back missing or broken.
      const retry = batch.filter((k) => !ok(k, result[k]));
      if (retry.length) Object.assign(result, await attempt(retry));
      for (const k of batch) {
        if (ok(k, result[k])) targetFlat[k] = result[k].trim();
        else rejected.push(k);
      }
      // Save after every batch, so an interrupted run keeps its progress.
      fs.writeFileSync(file, JSON.stringify(unflattenLike(source, targetFlat) || {}, null, 2) + "\n");
      const perBatch = (Date.now() - started) / (i + 1);
      const left = Math.round((perBatch * (batches.length - i - 1)) / 60000);
      process.stdout.write(`  batch ${i + 1}/${batches.length} saved (~${left} min left)\n`);
    }
    if (rejected.length) {
      console.log(`  ${rejected.length} left in English (missing or broken placeholders): ${rejected.slice(0, 8).join(", ")}${rejected.length > 8 ? " …" : ""}`);
    }
  }
}

module.exports = {
  LANGUAGES,
  flatten,
  unflattenLike,
  keepsPlaceholders,
  keysToTranslate,
  matchesScript,
  chunk,
  parseArgs,
  systemPrompt,
};

if (require.main === module) {
  main().catch((err) => {
    console.error(err.message || err);
    process.exit(1);
  });
}
