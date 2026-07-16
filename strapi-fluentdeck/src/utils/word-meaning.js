"use strict";

const OpenAI = require("openai");

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

const SYSTEM_PROMPT = `You write flashcard back-of-card text for an English learning app.
Given a word or expression (and optionally the sentence it appeared in, for context only), reply with EXACTLY two lines:

DEFINITION: <brief dictionary gloss, 5–12 words max. No long explanations. Use simple A2–B1 English. For verbs start with "To …"; for nouns/adjectives use a short phrase.>
EXAMPLE: <one short natural sentence, 6–14 words, must use the word/phrase.>

Rules:
- Definition must fit on a small flashcard — never more than 12 words.
- Example must be short — never more than 14 words.
- Do not repeat the DEFINITION/EXAMPLE labels elsewhere.
- Do not add bullet points, quotes, or extra lines.`;

function clampWords(text, maxWords) {
  const words = String(text ?? "")
    .trim()
    .replace(/\s+/g, " ")
    .split(" ")
    .filter(Boolean);
  if (words.length <= maxWords) {
    return words.join(" ");
  }
  const clipped = words.slice(0, maxWords).join(" ");
  return /[.!?]$/.test(clipped) ? clipped : `${clipped}.`;
}

function parseWordMeaningResponse(raw) {
  const text = String(raw ?? "");
  const definitionMatch = text.match(/DEFINITION:\s*(.+)/i);
  const exampleMatch = text.match(/EXAMPLE:\s*(.+)/i);
  const definition = clampWords(
    definitionMatch ? definitionMatch[1].trim() : text.trim(),
    MAX_DEFINITION_WORDS,
  );
  const example = clampWords(
    exampleMatch ? exampleMatch[1].trim() : "",
    MAX_EXAMPLE_WORDS,
  );
  return { definition, example };
}

/** Generates a short learner-friendly definition + example for a word/expression. Premium-only — gate before calling. */
async function generateWordMeaning({ word, context }) {
  const trimmedWord = String(word ?? "").trim();
  if (!trimmedWord) {
    throw new Error("word is required");
  }

  const openai = getOpenAIClient();
  const userPrompt = context
    ? `Word or expression: "${trimmedWord}"\nSentence it appeared in: "${context}"`
    : `Word or expression: "${trimmedWord}"`;

  const completion = await openai.chat.completions.create({
    model: WORD_MEANING_MODEL,
    messages: [
      { role: "system", content: SYSTEM_PROMPT },
      { role: "user", content: userPrompt },
    ],
    temperature: 0.3,
    max_tokens: 80,
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
