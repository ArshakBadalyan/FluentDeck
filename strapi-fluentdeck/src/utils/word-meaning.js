"use strict";

const OpenAI = require("openai");
const { languageLabel } = require("./ai-tutor");

const WORD_MEANING_MODEL = process.env.AI_WORD_MEANING_MODEL || "gpt-4o-mini";
const MAX_DEFINITION_WORDS = 12;
const MAX_EXAMPLE_WORDS = 14;

function getOpenAIClient() {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    throw new Error("OPENAI_API_KEY is not configured");
  }
  return new OpenAI({ apiKey });
}

const MAX_TRANSLATION_WORDS = 14;
/** Fallback for languages written without spaces (Japanese, Chinese). */
const MAX_FIELD_CHARS = 90;

function buildSystemPrompt(wordLanguage, translationLanguage) {
  const lines = [
    `You write flashcard back-of-card text for a ${wordLanguage} learning app.`,
    `Given a ${wordLanguage} word or expression (and optionally the sentence it appeared in, for context only), reply with EXACTLY ${translationLanguage ? "three" : "two"} lines:`,
    "",
    `DEFINITION: <brief dictionary gloss written in ${wordLanguage}, 5–12 words max. Simple A2–B1 ${wordLanguage}. No long explanations.>`,
    `EXAMPLE: <one short natural ${wordLanguage} sentence, 6–14 words, that uses the word/phrase.>`,
  ];
  if (translationLanguage) {
    lines.push(
      `TRANSLATION: <natural ${translationLanguage} translation of the word/phrase itself (not the definition), as short as possible.>`,
    );
  }
  lines.push(
    "",
    "Rules:",
    `- DEFINITION and EXAMPLE must be in ${wordLanguage} only${translationLanguage ? `; TRANSLATION must be in ${translationLanguage} only` : ""}.`,
    "- Keep every line short enough for a small flashcard.",
    "- Do not repeat the labels elsewhere.",
    "- Do not add bullet points, quotes, romanization, or extra lines.",
  );
  return lines.join("\n");
}

function clampWords(text, maxWords) {
  const words = String(text ?? "")
    .trim()
    .replace(/\s+/g, " ")
    .split(" ")
    .filter(Boolean);
  if (words.length <= maxWords) {
    const joined = words.join(" ");
    // Space-less scripts (ja/zh) count as one "word" — cap by characters instead.
    return joined.length > MAX_FIELD_CHARS
      ? `${joined.slice(0, MAX_FIELD_CHARS).trim()}…`
      : joined;
  }
  const clipped = words.slice(0, maxWords).join(" ");
  return /[.!?]$/.test(clipped) ? clipped : `${clipped}.`;
}

function parseWordMeaningResponse(raw) {
  const text = String(raw ?? "");
  const definitionMatch = text.match(/DEFINITION:\s*(.+)/i);
  const exampleMatch = text.match(/EXAMPLE:\s*(.+)/i);
  const translationMatch = text.match(/TRANSLATION:\s*(.+)/i);
  const definition = clampWords(
    definitionMatch ? definitionMatch[1].trim() : text.trim(),
    MAX_DEFINITION_WORDS,
  );
  const example = clampWords(
    exampleMatch ? exampleMatch[1].trim() : "",
    MAX_EXAMPLE_WORDS,
  );
  const translation = clampWords(
    translationMatch ? translationMatch[1].trim() : "",
    MAX_TRANSLATION_WORDS,
  );
  return { definition, example, translation };
}

/**
 * Generates a short definition + example in the word's own language, plus an
 * optional translation of the word into the user's translation language.
 * Premium-only — gate before calling.
 */
async function generateWordMeaning({ word, context, languageCode, translationLanguage }) {
  const trimmedWord = String(word ?? "").trim();
  if (!trimmedWord) {
    throw new Error("word is required");
  }

  const wordLanguage = languageLabel(languageCode || "en");
  const target = String(translationLanguage ?? "none").trim();
  const translationLabel =
    target && target !== "none" && target !== (languageCode || "en")
      ? languageLabel(target)
      : null;

  const openai = getOpenAIClient();
  const userPrompt = context
    ? `Word or expression: "${trimmedWord}"\nSentence it appeared in: "${context}"`
    : `Word or expression: "${trimmedWord}"`;

  const completion = await openai.chat.completions.create({
    model: WORD_MEANING_MODEL,
    messages: [
      { role: "system", content: buildSystemPrompt(wordLanguage, translationLabel) },
      { role: "user", content: userPrompt },
    ],
    temperature: 0.3,
    max_tokens: 220,
  });

  const raw = completion.choices?.[0]?.message?.content ?? "";
  return parseWordMeaningResponse(raw);
}

module.exports = {
  generateWordMeaning,
  parseWordMeaningResponse,
  clampWords,
  MAX_DEFINITION_WORDS,
  MAX_EXAMPLE_WORDS,
};
