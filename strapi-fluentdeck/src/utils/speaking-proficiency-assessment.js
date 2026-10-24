'use strict';

const OpenAI = require('openai');
const { practiceLanguageLabel, normalizePracticeLanguage } = require('./practice-languages');

const ASSESSMENT_MODEL = process.env.AI_PROFICIENCY_MODEL || 'gpt-4o-mini';
const VALID_LEVELS = new Set(['A1', 'A2', 'B1', 'B2', 'C1', 'C2']);
const VALID_CONFIDENCE = new Set(['low', 'medium', 'high']);

function getOpenAIClient() {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    throw new Error('OPENAI_API_KEY is not configured');
  }
  return new OpenAI({ apiKey });
}

// Per-language rubric nuance (Phase 2) — layered on top of the generic
// CEFR descriptors below, not a replacement for them. Config-driven by
// design: adding a 6th language's notes is a map entry, not a code change.
// Codes match `practice-languages.js` exactly (this registry has no
// regional/script variants, e.g. a single `zh` for Mandarin Chinese).
// Any code with no entry here — including every practice language not
// explicitly listed — silently falls back to the generic rubric alone.
const LANGUAGE_RUBRIC_NOTES = {
  ja: `Japanese-specific: also weigh particle accuracy (は/が/を/に/で etc.), politeness/register appropriate to context (plain form vs. masu-form vs. keigo), verb/adjective conjugation, and overall naturalness of phrasing — correct grammar that still sounds unnatural or register-mismatched should cap the level below what raw grammatical correctness alone would suggest.`,
  zh: `Chinese-specific: also weigh grammar (word order, aspect markers such as 了/过/着, measure-word usage), vocabulary range and precision, and contextual/pragmatic appropriateness. Do NOT assess tone accuracy or pronunciation — you only have a text transcript, and tones cannot be judged from text alone; ignore this dimension entirely rather than guessing.`,
  en: `English-specific: also weigh tense/aspect accuracy, article and preposition usage, vocabulary precision, and register appropriate to a spoken conversational context (not written-formal).`,
  es: `Spanish-specific: also weigh verb conjugation accuracy (including subjunctive where the context calls for it), ser/estar distinction, gender and number agreement, vocabulary range, and tú/usted register appropriate to context.`,
  tr: `Turkish-specific: also weigh vowel harmony and suffix order in agglutinated words, case endings, verb tense/aspect/mood suffixes, SOV word order, and sen/siz register appropriate to context.`,
  ko: `Korean-specific: also weigh particle accuracy (은/는, 이/가, 을/를 etc.), verb endings and speech level (해요체 vs. 합니다체 vs. 반말) appropriate to context, honorifics, and SOV word order.`,
  ar: `Arabic-specific: also weigh verb conjugation (person, gender, number), gender and number agreement, definiteness, and whether Modern Standard Arabic or a dialect is used consistently. Do not penalise a consistent dialect.`,
  vi: `Vietnamese-specific: also weigh word order, classifier usage, tense/aspect markers (đã, đang, sẽ), pronoun choice appropriate to the relationship, and vocabulary range. Do NOT assess tones or pronunciation — you only have a transcript.`,
  id: `Indonesian-specific: also weigh affix usage (me-, ber-, di-, -kan, -i), word order, time/aspect markers (sudah, sedang, akan), and formal vs. casual register appropriate to context.`,
  hy: `Armenian-specific (Eastern Armenian unless the learner clearly uses Western): also weigh case endings, verb conjugation for person/number/tense, the definite article -ը/-ն, word order, and formal/informal (դուք/դու) register appropriate to context.`,
  it: `Italian-specific: also weigh verb conjugation and mood (including congiuntivo at higher levels), gender/number agreement, preposition usage, vocabulary range, and register appropriate to context.`,
};

function languageRubricNotes(languageCode) {
  return LANGUAGE_RUBRIC_NOTES[normalizePracticeLanguage(languageCode)] ?? null;
}

// Generic, language-parameterized CEFR rubric that applies to every
// supported language; LANGUAGE_RUBRIC_NOTES above adds targeted criteria
// per language without forking this prompt or the response schema.
const ASSESSMENT_SYSTEM_PROMPT = `You are an expert CEFR (Common European Framework of Reference) proficiency assessor for a language-learning app, assessing SPOKEN production only.

You will be given several recent, real speaking turns a learner produced, in the target language below, usually spanning more than one exchange or topic. Judge their SPEAKING proficiency against CEFR A1-C2 descriptors using:
- Grammatical range and accuracy
- Vocabulary range and precision
- Fluency and ability to develop ideas
- Coherence and organisation
- Interaction and responsiveness to the conversation

Be conservative. Only report a level the transcripts clearly and consistently demonstrate. If the sample is too short, too repetitive, too simple a topic, or otherwise insufficient to judge confidently, say evidence is insufficient instead of guessing — a wrong but confident-sounding level is worse than admitting you can't tell yet.

Do not infer a level from message length, turn count, or vocabulary list size alone — judge actual language USE: how correctly and naturally ideas are expressed, not how much was written.

Respond with ONLY valid JSON, no markdown, in exactly this shape:
{
  "level": "A1" | "A2" | "B1" | "B2" | "C1" | "C2" | null,
  "confidence": "low" | "medium" | "high",
  "evidenceSufficient": boolean,
  "evidence": [string, ...],
  "strengths": [string, ...],
  "areasToImprove": [string, ...],
  "independentlyProduced": boolean
}
- "evidence": 2-4 short, specific observations referencing the learner's own words (not generic statements).
- "independentlyProduced": false if responses look copied, templated, or otherwise not spontaneous.
- If you cannot responsibly judge a level, set "level" to null and "evidenceSufficient" to false (still fill "evidence"/"strengths"/"areasToImprove" if you have partial observations).`;

function buildAssessmentUserPrompt({ languageCode, languageLabel, currentLevel, transcripts }) {
  const lines = transcripts
    .map((t, i) => {
      const note = t.hasCorrections ? ' [tutor made grammar corrections on this turn]' : '';
      return `${i + 1}. "${t.text}"${note}`;
    })
    .join('\n');

  const rubricNotes = languageRubricNotes(languageCode);
  const rubricSection = rubricNotes ? `\n${rubricNotes}\n` : '';

  return `Target language: ${languageLabel}
Learner's current committed speaking level (context only — do not just confirm it; judge the transcripts): ${currentLevel || 'not yet assessed'}
${rubricSection}
Recent speaking turns, in order (most recent last):
${lines}

Assess the learner's spoken ${languageLabel} proficiency based only on these turns.`;
}

/** Pure parser/validator — no network call — so it's directly unit-testable. */
function parseAssessmentResponse(raw) {
  let parsed;
  try {
    parsed = typeof raw === 'string' ? JSON.parse(raw) : raw;
  } catch {
    return null;
  }
  if (!parsed || typeof parsed !== 'object') return null;

  const confidence = VALID_CONFIDENCE.has(parsed.confidence) ? parsed.confidence : null;
  if (!confidence) return null;

  const evidenceSufficient = parsed.evidenceSufficient === true;
  const rawLevel = String(parsed.level ?? '').toUpperCase();
  const level = VALID_LEVELS.has(rawLevel) ? rawLevel : null;

  // Contradictory response (claims sufficient evidence but gives no level,
  // or vice versa gives a level while claiming insufficient evidence is
  // fine — we just don't commit a level in that case) — only the first
  // combination is actually invalid/unusable.
  if (evidenceSufficient && !level) return null;

  const asStringArray = (value) =>
    Array.isArray(value) ? value.filter((s) => typeof s === 'string' && s.trim()).slice(0, 6) : [];

  return {
    level: evidenceSufficient ? level : null,
    confidence,
    evidenceSufficient,
    evidence: asStringArray(parsed.evidence),
    strengths: asStringArray(parsed.strengths),
    areasToImprove: asStringArray(parsed.areasToImprove),
    independentlyProduced: parsed.independentlyProduced !== false,
  };
}

/**
 * Calls the LLM to assess speaking proficiency for one batch of transcripts.
 * Never throws for provider/parsing failures — returns a tagged failure
 * result instead, so callers can safely treat "assessment unavailable" as
 * "no change" rather than needing their own try/catch around every call.
 */
async function assessSpeakingProficiency({ languageCode, transcripts, currentLevel }) {
  if (!Array.isArray(transcripts) || transcripts.length === 0) {
    return { ok: false, reason: 'no_transcripts' };
  }

  const languageLabel = practiceLanguageLabel(languageCode);
  let completion;
  try {
    const openai = getOpenAIClient();
    completion = await openai.chat.completions.create({
      model: ASSESSMENT_MODEL,
      response_format: { type: 'json_object' },
      messages: [
        { role: 'system', content: ASSESSMENT_SYSTEM_PROMPT },
        {
          role: 'user',
          content: buildAssessmentUserPrompt({
            languageCode,
            languageLabel,
            currentLevel,
            transcripts,
          }),
        },
      ],
      temperature: 0.2,
      max_tokens: 600,
    });
  } catch (err) {
    return { ok: false, reason: 'provider_error', error: err };
  }

  const raw = completion.choices?.[0]?.message?.content;
  const parsed = parseAssessmentResponse(raw);
  if (!parsed) {
    return { ok: false, reason: 'invalid_response', raw };
  }
  return { ok: true, result: parsed };
}

module.exports = {
  assessSpeakingProficiency,
  parseAssessmentResponse,
  buildAssessmentUserPrompt,
  languageRubricNotes,
  LANGUAGE_RUBRIC_NOTES,
  ASSESSMENT_SYSTEM_PROMPT,
};
