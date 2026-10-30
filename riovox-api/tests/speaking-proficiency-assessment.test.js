'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');
const {
  parseAssessmentResponse,
  buildAssessmentUserPrompt,
  languageRubricNotes,
  LANGUAGE_RUBRIC_NOTES,
} = require('../src/utils/speaking-proficiency-assessment');

test('parses a valid sufficient-evidence response', () => {
  const parsed = parseAssessmentResponse(
    JSON.stringify({
      level: 'b1',
      confidence: 'high',
      evidenceSufficient: true,
      evidence: ['used past tense correctly twice'],
      strengths: ['good vocabulary range'],
      areasToImprove: ['article usage'],
      independentlyProduced: true,
    }),
  );
  assert.equal(parsed.level, 'B1');
  assert.equal(parsed.confidence, 'high');
  assert.equal(parsed.evidenceSufficient, true);
  assert.equal(parsed.evidence.length, 1);
});

test('parses a valid insufficient-evidence response', () => {
  const parsed = parseAssessmentResponse({
    level: null,
    confidence: 'low',
    evidenceSufficient: false,
    evidence: [],
    strengths: [],
    areasToImprove: [],
    independentlyProduced: true,
  });
  assert.equal(parsed.level, null);
  assert.equal(parsed.evidenceSufficient, false);
});

test('rejects malformed JSON', () => {
  assert.equal(parseAssessmentResponse('not json at all {'), null);
});

test('rejects a response missing confidence', () => {
  assert.equal(
    parseAssessmentResponse(JSON.stringify({ level: 'B1', evidenceSufficient: true })),
    null,
  );
});

test('rejects a contradictory response (sufficient evidence but no level)', () => {
  assert.equal(
    parseAssessmentResponse(
      JSON.stringify({ level: null, confidence: 'high', evidenceSufficient: true }),
    ),
    null,
  );
});

test('rejects an invalid level string', () => {
  assert.equal(
    parseAssessmentResponse(
      JSON.stringify({ level: 'Z9', confidence: 'high', evidenceSufficient: true }),
    ),
    null,
  );
});

test('forces evidenceSufficient:false responses to a null level even if one was provided', () => {
  const parsed = parseAssessmentResponse(
    JSON.stringify({ level: 'C2', confidence: 'low', evidenceSufficient: false }),
  );
  assert.ok(parsed);
  assert.equal(parsed.level, null);
});

test('buildAssessmentUserPrompt includes the target language and transcripts', () => {
  const prompt = buildAssessmentUserPrompt({
    languageLabel: 'Japanese',
    currentLevel: 'A2',
    transcripts: [{ text: 'konnichiwa', hasCorrections: false }],
  });
  assert.match(prompt, /Japanese/);
  assert.match(prompt, /konnichiwa/);
  assert.match(prompt, /A2/);
});

// --- Phase 2: per-language rubric nuance ------------------------------------

test('languageRubricNotes returns the right notes for each of the 5 tuned languages', () => {
  for (const code of ['ja', 'zh', 'en', 'es', 'it']) {
    assert.equal(languageRubricNotes(code), LANGUAGE_RUBRIC_NOTES[code]);
    assert.ok(languageRubricNotes(code).length > 0);
  }
});

test('languageRubricNotes falls back to null for a practice language with no tuned notes', () => {
  // 'fr' is a real supported practice language (practice-languages.js) but
  // has no entry in LANGUAGE_RUBRIC_NOTES — must fall back cleanly, not throw.
  assert.equal(languageRubricNotes('fr'), null);
});

test('languageRubricNotes never throws on unknown/garbage/missing codes (practice-languages.js itself falls back unrecognized codes to "en", which happens to be tuned — so this asserts no-throw/valid-shape, not null)', () => {
  for (const code of ['xx-not-real', undefined, null, '', 123]) {
    const notes = languageRubricNotes(code);
    assert.ok(notes === null || typeof notes === 'string');
  }
});

test('buildAssessmentUserPrompt injects Japanese-specific notes for languageCode ja', () => {
  const prompt = buildAssessmentUserPrompt({
    languageCode: 'ja',
    languageLabel: 'Japanese',
    currentLevel: null,
    transcripts: [{ text: 'konnichiwa', hasCorrections: false }],
  });
  assert.match(prompt, /particle/i);
  assert.match(prompt, /keigo/i);
});

test('buildAssessmentUserPrompt injects Chinese-specific notes and explicitly excludes tone/pronunciation', () => {
  const prompt = buildAssessmentUserPrompt({
    languageCode: 'zh',
    languageLabel: 'Mandarin Chinese',
    currentLevel: null,
    transcripts: [{ text: 'ni hao', hasCorrections: false }],
  });
  assert.match(prompt, /measure-word/i);
  assert.match(prompt, /Do NOT assess tone accuracy or pronunciation/);
});

test('buildAssessmentUserPrompt injects notes for English, Spanish, and Italian', () => {
  const en = buildAssessmentUserPrompt({
    languageCode: 'en',
    languageLabel: 'English',
    transcripts: [{ text: 'hi', hasCorrections: false }],
  });
  assert.match(en, /register appropriate to a spoken conversational context/);

  const es = buildAssessmentUserPrompt({
    languageCode: 'es',
    languageLabel: 'Spanish',
    transcripts: [{ text: 'hola', hasCorrections: false }],
  });
  assert.match(es, /subjunctive/i);
  assert.match(es, /ser\/estar/);

  const it = buildAssessmentUserPrompt({
    languageCode: 'it',
    languageLabel: 'Italian',
    transcripts: [{ text: 'ciao', hasCorrections: false }],
  });
  assert.match(it, /congiuntivo/i);
});

test('buildAssessmentUserPrompt adds no rubric-notes section for an unlisted language code', () => {
  const withNotes = buildAssessmentUserPrompt({
    languageCode: 'ja',
    languageLabel: 'Japanese',
    transcripts: [{ text: 'x', hasCorrections: false }],
  });
  const withoutNotes = buildAssessmentUserPrompt({
    languageCode: 'fr',
    languageLabel: 'French',
    transcripts: [{ text: 'x', hasCorrections: false }],
  });
  assert.notEqual(withNotes.length - 'Japanese'.length, withoutNotes.length - 'French'.length);
  assert.doesNotMatch(withoutNotes, /particle/i);
  assert.doesNotMatch(withoutNotes, /congiuntivo/i);
});

test('buildAssessmentUserPrompt response-shape instructions are unaffected by rubric notes (still generic schema)', () => {
  // The per-language section lives in the user prompt; the JSON response
  // shape itself is defined only in ASSESSMENT_SYSTEM_PROMPT and must stay
  // identical regardless of language — buildAssessmentUserPrompt must not
  // duplicate or override schema instructions.
  const prompt = buildAssessmentUserPrompt({
    languageCode: 'ja',
    languageLabel: 'Japanese',
    transcripts: [{ text: 'x', hasCorrections: false }],
  });
  assert.doesNotMatch(prompt, /"level"/);
  assert.doesNotMatch(prompt, /"evidenceSufficient"/);
});
