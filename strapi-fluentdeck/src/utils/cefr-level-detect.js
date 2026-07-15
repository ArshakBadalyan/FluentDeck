'use strict';

const OpenAI = require('openai');
const { practiceLanguageLabel } = require('./practice-languages');

const CEFR_LEVEL_MODEL = process.env.AI_CEFR_LEVEL_MODEL || 'gpt-4o-mini';
const VALID_LEVELS = new Set(['A1', 'A2', 'B1', 'B2', 'C1', 'C2']);

function getOpenAIClient() {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    throw new Error('OPENAI_API_KEY is not configured');
  }
  return new OpenAI({ apiKey });
}

const SYSTEM_PROMPT = `You classify vocabulary for language learners using the CEFR framework.
Given a word or phrase and its language, respond with EXACTLY one line:

LEVEL: <A1|A2|B1|B2|C1|C2>

Rules:
- Judge difficulty for a typical adult learner of that language.
- Use only one of the six levels above.
- Consider word frequency, complexity, and typical learner exposure.
- Do not add explanation or extra lines.`;

function parseCefrLevelResponse(raw) {
  const text = String(raw ?? '').trim();
  const match = text.match(/LEVEL:\s*(A1|A2|B1|B2|C1|C2)\b/i);
  if (match) {
    return match[1].toUpperCase();
  }
  const inline = text.match(/\b(A1|A2|B1|B2|C1|C2)\b/i);
  if (inline) {
    return inline[1].toUpperCase();
  }
  return null;
}

/** Estimates CEFR level for a word/phrase. Premium-only — gate before calling. */
async function detectCefrLevel({ word, languageCode = 'en', definition, exampleSentence }) {
  const trimmedWord = String(word ?? '').trim();
  if (!trimmedWord) {
    throw new Error('word is required');
  }

  const langLabel = practiceLanguageLabel(languageCode);
  const parts = [`Word or phrase: "${trimmedWord}"`, `Language: ${langLabel}`];
  if (definition && String(definition).trim()) {
    parts.push(`Definition: ${String(definition).trim()}`);
  }
  if (exampleSentence && String(exampleSentence).trim()) {
    parts.push(`Example: ${String(exampleSentence).trim()}`);
  }

  const openai = getOpenAIClient();
  const completion = await openai.chat.completions.create({
    model: CEFR_LEVEL_MODEL,
    messages: [
      { role: 'system', content: SYSTEM_PROMPT },
      { role: 'user', content: parts.join('\n') },
    ],
    temperature: 0.1,
    max_tokens: 16,
  });

  const raw = completion.choices?.[0]?.message?.content ?? '';
  const level = parseCefrLevelResponse(raw);
  if (!level || !VALID_LEVELS.has(level)) {
    throw new Error('Could not determine CEFR level');
  }
  return { cefrLevel: level };
}

module.exports = {
  detectCefrLevel,
  parseCefrLevelResponse,
  VALID_LEVELS,
};
