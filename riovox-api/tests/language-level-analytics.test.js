'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');
const {
  emptyLanguageEntry,
  normalizeLanguageLevels,
  recordSpeakingTurn,
  recordDeckReview,
  isSpeakingAssessmentDue,
  applySpeakingAssessmentResult,
  pushLevelHistory,
  ASSESSMENT_TURN_THRESHOLD,
  MAX_EVIDENCE_RECORDS,
} = require('../src/utils/language-level-analytics');

function sufficientResult(level, confidence = 'high') {
  return {
    ok: true,
    result: {
      level,
      confidence,
      evidenceSufficient: true,
      evidence: [`sample evidence for ${level}`],
      strengths: [],
      areasToImprove: [],
      independentlyProduced: true,
    },
  };
}

function insufficientResult(confidence = 'low') {
  return {
    ok: true,
    result: {
      level: null,
      confidence,
      evidenceSufficient: false,
      evidence: [],
      strengths: [],
      areasToImprove: [],
      independentlyProduced: true,
    },
  };
}

// --- Regression test for the original bug ----------------------------------

test('regression: adding deck words alone never changes estimatedLevel (was: activity-count formula bumped level)', () => {
  let entry = emptyLanguageEntry('A1');
  for (let i = 0; i < 50; i += 1) {
    entry = recordDeckReview(entry, 1);
  }
  assert.equal(entry.activity.deckWordsReviewed, 50);
  assert.equal(entry.skills.speaking.estimatedLevel, null);
  assert.equal(entry.skills.speaking.status, 'insufficient_evidence');
});

test('regression: many speaking turns alone (no assessment run) never change estimatedLevel', () => {
  let entry = emptyLanguageEntry('A1');
  for (let i = 0; i < 30; i += 1) {
    entry = recordSpeakingTurn(entry, { text: 'This is a reasonably long sentence I am saying.', wordCount: 9 });
  }
  assert.equal(entry.activity.speakingTurns, 30);
  assert.equal(entry.skills.speaking.estimatedLevel, null);
  assert.equal(entry.skills.speaking.status, 'insufficient_evidence');
});

// --- Cross-language and activity/skill isolation ----------------------------

test('cross-language isolation: Japanese deck activity never touches English state', () => {
  const levels = normalizeLanguageLevels({});
  levels.ja = emptyLanguageEntry('A1');
  levels.en = emptyLanguageEntry('B2');
  levels.en.skills.speaking.estimatedLevel = 'B2';
  levels.en.skills.speaking.status = 'assessed';

  for (let i = 0; i < 100; i += 1) {
    levels.ja = recordDeckReview(levels.ja, 1);
  }

  assert.equal(levels.ja.activity.deckWordsReviewed, 100);
  assert.equal(levels.en.activity.deckWordsReviewed, 0);
  assert.equal(levels.en.skills.speaking.estimatedLevel, 'B2');
});

test('cross-language isolation: speaking Spanish never changes Italian estimate', () => {
  const levels = normalizeLanguageLevels({});
  levels.es = emptyLanguageEntry('A1');
  levels.it = emptyLanguageEntry('A1');
  levels.it.skills.speaking.estimatedLevel = 'B1';
  levels.it.skills.speaking.status = 'assessed';

  for (let i = 0; i < 10; i += 1) {
    levels.es = recordSpeakingTurn(levels.es, { text: 'Hola, como estas hoy amigo mio', wordCount: 6 });
  }

  assert.equal(levels.es.activity.speakingTurns, 10);
  assert.equal(levels.it.activity.speakingTurns, 0);
  assert.equal(levels.it.skills.speaking.estimatedLevel, 'B1');
});

// --- Conservative, evidence-based updates -----------------------------------

test('a single strong assessment alone does not commit a level change', () => {
  let entry = emptyLanguageEntry('A1');
  entry = applySpeakingAssessmentResult(entry, sufficientResult('C2'));
  assert.equal(entry.skills.speaking.estimatedLevel, null, 'not committed yet');
  assert.equal(entry.skills.speaking.status, 'insufficient_evidence');
  assert.equal(entry.skills.speaking.pendingSuggestedLevel, 'C2');
  assert.equal(entry.levelHistory.length, 0);
});

test('two consecutive agreeing assessments commit the level', () => {
  let entry = emptyLanguageEntry('A1');
  entry = applySpeakingAssessmentResult(entry, sufficientResult('B1'));
  entry = applySpeakingAssessmentResult(entry, sufficientResult('B1'));
  assert.equal(entry.skills.speaking.estimatedLevel, 'B1');
  assert.equal(entry.skills.speaking.status, 'assessed');
  assert.equal(entry.skills.speaking.pendingSuggestedLevel, null);
  assert.equal(entry.levelHistory.length, 1);
  assert.deepEqual(
    { previousLevel: entry.levelHistory[0].previousLevel, newLevel: entry.levelHistory[0].newLevel },
    { previousLevel: null, newLevel: 'B1' },
  );
});

test('a disagreeing second assessment restarts corroboration instead of committing', () => {
  let entry = emptyLanguageEntry('A1');
  entry = applySpeakingAssessmentResult(entry, sufficientResult('B1'));
  entry = applySpeakingAssessmentResult(entry, sufficientResult('C1')); // disagrees
  assert.equal(entry.skills.speaking.estimatedLevel, null, 'still not committed');
  assert.equal(entry.skills.speaking.pendingSuggestedLevel, 'C1', 'latest suggestion replaces the old one');

  entry = applySpeakingAssessmentResult(entry, sufficientResult('C1')); // agrees with pending now
  assert.equal(entry.skills.speaking.estimatedLevel, 'C1');
});

test('downward reassessment is allowed once two consecutive assessments agree', () => {
  let entry = emptyLanguageEntry('A1');
  entry = applySpeakingAssessmentResult(entry, sufficientResult('B2'));
  entry = applySpeakingAssessmentResult(entry, sufficientResult('B2'));
  assert.equal(entry.skills.speaking.estimatedLevel, 'B2');

  entry = applySpeakingAssessmentResult(entry, sufficientResult('A2'));
  assert.equal(entry.skills.speaking.estimatedLevel, 'B2', 'first lower suggestion alone does not commit');
  entry = applySpeakingAssessmentResult(entry, sufficientResult('A2'));
  assert.equal(entry.skills.speaking.estimatedLevel, 'A2', 'second agreeing lower suggestion commits');
});

test('insufficient evidence produces the explicit status, not a default A1', () => {
  let entry = emptyLanguageEntry('A1');
  entry = applySpeakingAssessmentResult(entry, insufficientResult());
  assert.equal(entry.skills.speaking.estimatedLevel, null);
  assert.equal(entry.skills.speaking.status, 'insufficient_evidence');
  assert.notEqual(entry.skills.speaking.status, 'A1');
});

test('insufficient evidence on a later sample does not erase an already-committed level', () => {
  let entry = emptyLanguageEntry('A1');
  entry = applySpeakingAssessmentResult(entry, sufficientResult('B1'));
  entry = applySpeakingAssessmentResult(entry, sufficientResult('B1'));
  assert.equal(entry.skills.speaking.estimatedLevel, 'B1');

  entry = applySpeakingAssessmentResult(entry, insufficientResult());
  assert.equal(entry.skills.speaking.estimatedLevel, 'B1', 'stays committed');
  assert.equal(entry.skills.speaking.status, 'assessed');
});

test('repeated identical assessments do not create duplicate history entries', () => {
  let entry = emptyLanguageEntry('A1');
  entry = applySpeakingAssessmentResult(entry, sufficientResult('B1'));
  entry = applySpeakingAssessmentResult(entry, sufficientResult('B1'));
  assert.equal(entry.levelHistory.length, 1);

  // Reconfirm the same committed level repeatedly.
  entry = applySpeakingAssessmentResult(entry, sufficientResult('B1'));
  entry = applySpeakingAssessmentResult(entry, sufficientResult('B1'));
  assert.equal(entry.levelHistory.length, 1, 'no duplicate entries for an unchanged level');
});

test('a failed/malformed assessment result does not change any stored level or consume the pending batch', () => {
  let entry = emptyLanguageEntry('A1');
  entry = recordSpeakingTurn(entry, { text: 'hello there friend', wordCount: 3 });
  const before = JSON.stringify(entry);

  entry = applySpeakingAssessmentResult(entry, { ok: false, reason: 'provider_error' });
  assert.equal(JSON.stringify(entry), before, 'entry is byte-for-byte unchanged on failure');
});

test('assessment is due only once the turn threshold is reached with a non-empty pending batch', () => {
  let entry = emptyLanguageEntry('A1');
  assert.equal(isSpeakingAssessmentDue(entry), false);
  for (let i = 0; i < ASSESSMENT_TURN_THRESHOLD - 1; i += 1) {
    entry = recordSpeakingTurn(entry, { text: 'a short turn here', wordCount: 4 });
  }
  assert.equal(isSpeakingAssessmentDue(entry), false, 'one turn short of threshold');
  entry = recordSpeakingTurn(entry, { text: 'one more turn to cross it', wordCount: 5 });
  assert.equal(isSpeakingAssessmentDue(entry), true);
});

test('committing an assessment resets the turn counter and clears the pending batch', () => {
  let entry = emptyLanguageEntry('A1');
  for (let i = 0; i < ASSESSMENT_TURN_THRESHOLD; i += 1) {
    entry = recordSpeakingTurn(entry, { text: 'turn number ' + i, wordCount: 3 });
  }
  assert.equal(isSpeakingAssessmentDue(entry), true);
  entry = applySpeakingAssessmentResult(entry, sufficientResult('A2'));
  assert.equal(entry.skills.speaking.turnsSinceLastAssessment, 0);
  assert.deepEqual(entry.skills.speaking.pendingTranscripts, []);
  assert.equal(isSpeakingAssessmentDue(entry), false);
});

// --- tutorLevel vs estimatedLevel independence ------------------------------

test('tutorLevel and skills.speaking.estimatedLevel can legitimately differ with no auto-sync', () => {
  let entry = emptyLanguageEntry('C1'); // manual tutor-level setting
  entry = applySpeakingAssessmentResult(entry, sufficientResult('A2'));
  entry = applySpeakingAssessmentResult(entry, sufficientResult('A2'));
  assert.equal(entry.tutorLevel, 'C1', 'manual setting untouched by assessment');
  assert.equal(entry.skills.speaking.estimatedLevel, 'A2');
});

// --- Legacy data migration ---------------------------------------------------

test('legacy (pre-skills) entries are relabeled as unassessed, not treated as real CEFR levels', () => {
  const normalized = normalizeLanguageLevels({
    en: {
      tutorLevel: 'B2',
      estimatedLevel: 'C2', // the old activity-formula output
      speakingTurns: 120,
      perfectSentences: 90,
      correctionCount: 30,
      uniqueWordsSpoken: 600,
      deckWordsReviewed: 300,
      levelHistory: [{ estimatedLevel: 'C2', recordedAt: '2026-01-01T00:00:00.000Z', source: 'analytics' }],
    },
  });

  assert.equal(normalized.en.skills.speaking.estimatedLevel, null, 'old estimate is not trusted as a real assessment');
  assert.equal(normalized.en.skills.speaking.status, 'legacy_unassessed');
  assert.equal(normalized.en.skills.speaking.legacyEstimatedLevel, 'C2', 'preserved for transparency only');
  assert.equal(normalized.en.activity.speakingTurns, 120, 'activity counters are preserved');
  assert.equal(normalized.en.tutorLevel, 'B2', 'manual tutor setting is preserved');
  assert.equal(normalized.en.levelHistory[0].method, 'legacy-activity-formula');
});

test('already-new-shape entries pass through normalizeLanguageLevels unchanged in meaning', () => {
  let entry = emptyLanguageEntry('A1');
  entry = applySpeakingAssessmentResult(entry, sufficientResult('B1'));
  entry = applySpeakingAssessmentResult(entry, sufficientResult('B1'));
  const normalized = normalizeLanguageLevels({ en: entry });
  assert.equal(normalized.en.skills.speaking.estimatedLevel, 'B1');
  assert.equal(normalized.en.skills.speaking.status, 'assessed');
});

// --- History plumbing --------------------------------------------------------

test('pushLevelHistory dedups consecutive identical skill+level entries', () => {
  let history = [];
  history = pushLevelHistory(history, { skill: 'speaking', previousLevel: null, newLevel: 'A1', method: 'test' });
  history = pushLevelHistory(history, { skill: 'speaking', previousLevel: 'A1', newLevel: 'A1', method: 'test' });
  assert.equal(history.length, 1);
});

// --- Phase 2: evidence-record persistence -----------------------------------

test('every assessment run appends an evidence record, even inconclusive ones', () => {
  let entry = emptyLanguageEntry('A1');
  entry = applySpeakingAssessmentResult(entry, insufficientResult());
  assert.equal(entry.skills.speaking.evidenceRecords.length, 1);
  const record = entry.skills.speaking.evidenceRecords[0];
  assert.equal(record.suggestedLevel, null);
  assert.equal(record.committed, false);
  assert.ok(record.id);
});

test('evidence record ids are generated and unique across multiple runs', () => {
  let entry = emptyLanguageEntry('A1');
  entry = applySpeakingAssessmentResult(entry, sufficientResult('B1'));
  entry = applySpeakingAssessmentResult(entry, sufficientResult('B1'));
  entry = applySpeakingAssessmentResult(entry, insufficientResult());
  const ids = entry.skills.speaking.evidenceRecords.map((r) => r.id);
  assert.equal(ids.length, 3);
  assert.equal(new Set(ids).size, 3);
});

test('a held (not-yet-corroborated) suggestion records its evidence id as pendingEvidenceId', () => {
  let entry = emptyLanguageEntry('A1');
  entry = applySpeakingAssessmentResult(entry, sufficientResult('B1'));
  assert.equal(entry.skills.speaking.estimatedLevel, null); // not committed yet
  assert.equal(entry.skills.speaking.pendingSuggestedLevel, 'B1');
  const pendingRecord = entry.skills.speaking.evidenceRecords[0];
  assert.equal(entry.skills.speaking.pendingEvidenceId, pendingRecord.id);
  assert.equal(pendingRecord.committed, false);
});

test('a committed level change produces a levelHistory row referencing both corroborating evidence ids', () => {
  let entry = emptyLanguageEntry('A1');
  entry = applySpeakingAssessmentResult(entry, sufficientResult('B1'));
  const firstId = entry.skills.speaking.pendingEvidenceId;
  entry = applySpeakingAssessmentResult(entry, sufficientResult('B1'));
  const secondRecord = entry.skills.speaking.evidenceRecords[entry.skills.speaking.evidenceRecords.length - 1];

  assert.equal(entry.skills.speaking.estimatedLevel, 'B1');
  assert.equal(entry.skills.speaking.pendingEvidenceId, null);
  assert.equal(secondRecord.committed, true);

  const historyRow = entry.levelHistory[entry.levelHistory.length - 1];
  assert.deepEqual(historyRow.evidenceIds, [firstId, secondRecord.id]);
});

test('reconfirming an already-committed level appends a committed:true record but no new history row', () => {
  let entry = emptyLanguageEntry('A1');
  entry = applySpeakingAssessmentResult(entry, sufficientResult('B1'));
  entry = applySpeakingAssessmentResult(entry, sufficientResult('B1')); // commits B1
  const historyLengthAfterCommit = entry.levelHistory.length;

  entry = applySpeakingAssessmentResult(entry, sufficientResult('B1')); // reconfirms
  assert.equal(entry.levelHistory.length, historyLengthAfterCommit); // no duplicate entry
  const lastRecord = entry.skills.speaking.evidenceRecords[entry.skills.speaking.evidenceRecords.length - 1];
  assert.equal(lastRecord.committed, true);
  assert.equal(lastRecord.suggestedLevel, 'B1');
});

test('evidenceRecords is capped at MAX_EVIDENCE_RECORDS, oldest dropped first', () => {
  let entry = emptyLanguageEntry('A1');
  // Every insufficient-evidence run appends exactly one record (the
  // "inconclusive" branch), so MAX_EVIDENCE_RECORDS+5 runs must still cap
  // at MAX_EVIDENCE_RECORDS stored records.
  for (let i = 0; i < MAX_EVIDENCE_RECORDS + 5; i += 1) {
    entry = applySpeakingAssessmentResult(entry, insufficientResult());
  }
  assert.equal(entry.skills.speaking.evidenceRecords.length, MAX_EVIDENCE_RECORDS);
});

test('normalizeLanguageLevels does not crash on an entry missing evidenceRecords (pre-Phase-2 shape)', () => {
  const preShapeEntry = emptyLanguageEntry('A1');
  delete preShapeEntry.skills.speaking.evidenceRecords;
  delete preShapeEntry.skills.speaking.pendingEvidenceId;
  const normalized = normalizeLanguageLevels({ en: preShapeEntry });
  assert.deepEqual(normalized.en.skills.speaking.evidenceRecords, []);
  assert.equal(normalized.en.skills.speaking.pendingEvidenceId, null);
});

test('normalizeLanguageLevels does not crash on a legacy (pre-skills) entry — evidenceRecords defaults to empty', () => {
  const normalized = normalizeLanguageLevels({
    en: { tutorLevel: 'B1', estimatedLevel: 'C2', speakingTurns: 40, deckWordsReviewed: 100 },
  });
  assert.deepEqual(normalized.en.skills.speaking.evidenceRecords, []);
  assert.equal(normalized.en.skills.speaking.status, 'legacy_unassessed');
});

test('normalizeLanguageLevels drops malformed evidence-record entries (missing id) rather than crashing', () => {
  const entry = emptyLanguageEntry('A1');
  entry.skills.speaking.evidenceRecords = [
    { id: 'real-id', recordedAt: new Date().toISOString(), suggestedLevel: 'B1', confidence: 'high', evidence: [], committed: true },
    { recordedAt: new Date().toISOString(), suggestedLevel: 'B1' }, // no id — must be dropped
    null,
    'not-an-object',
  ];
  const normalized = normalizeLanguageLevels({ en: entry });
  assert.equal(normalized.en.skills.speaking.evidenceRecords.length, 1);
  assert.equal(normalized.en.skills.speaking.evidenceRecords[0].id, 'real-id');
});

test('history rows written before Phase 2 (no evidenceIds) normalize to an empty array, not a crash', () => {
  const normalized = normalizeLanguageLevels({
    en: {
      ...emptyLanguageEntry('A1'),
      levelHistory: [
        { skill: 'speaking', previousLevel: 'A1', newLevel: 'A2', recordedAt: new Date().toISOString(), method: 'ai-assessment-v1', evidenceSummary: 'old row, no evidenceIds field' },
      ],
    },
  });
  assert.deepEqual(normalized.en.levelHistory[0].evidenceIds, []);
  assert.equal(normalized.en.levelHistory[0].evidenceSummary, 'old row, no evidenceIds field');
});
