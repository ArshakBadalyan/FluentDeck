'use strict';

const { randomUUID } = require('node:crypto');

const CEFR_LEVELS = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
const VALID_LEVELS = new Set(CEFR_LEVELS);
const VALID_CONFIDENCE = new Set(['low', 'medium', 'high']);

// Speaking turns since the last assessment (or since the language was first
// selected) before a new AI proficiency assessment is triggered. Chosen to
// span more than one conversation/topic, not just one lucky exchange.
const ASSESSMENT_TURN_THRESHOLD = 8;
// How many recent turn transcripts we keep buffered for the next assessment
// call. Capped so the prompt stays bounded even if a user talks a lot
// between assessments (the batch assessed is still the most recent N turns).
const MAX_PENDING_TRANSCRIPTS = 12;
const MAX_HISTORY_ENTRIES = 24;
// Caps the per-skill evidence-record audit trail. One record is appended
// per assessment run (roughly one per ASSESSMENT_TURN_THRESHOLD turns), so
// 20 covers ~160 turns of history — generous for a long-lived user without
// letting the JSON blob grow unbounded.
const MAX_EVIDENCE_RECORDS = 20;

function levelIndex(level) {
  const idx = CEFR_LEVELS.indexOf(String(level ?? '').toUpperCase());
  return idx >= 0 ? idx : -1;
}

function clampLevel(level) {
  const normalized = String(level ?? 'A1').toUpperCase();
  return VALID_LEVELS.has(normalized) ? normalized : 'A1';
}

/** Like clampLevel, but returns null instead of defaulting to A1 — for
 * fields where "no level" is a meaningful, distinct state (an unassessed
 * skill is not the same thing as a skill assessed at A1). */
function clampLevelOrNull(level) {
  if (level === null || level === undefined) return null;
  const normalized = String(level).toUpperCase();
  return VALID_LEVELS.has(normalized) ? normalized : null;
}

// ---------------------------------------------------------------------------
// Entry shape
//
// languageLevels[code] = {
//   tutorLevel: 'B2',               // manual AI-tutor difficulty setting — never
//                                    // written by assessment logic, see
//                                    // recordLanguageSelection/updateTutorLevelForLanguage.
//   skills: {
//     speaking:  { estimatedLevel, status, confidence, lastAssessedAt,
//                  turnsSinceLastAssessment, pendingSuggestedLevel,
//                  pendingEvidenceId, pendingTranscripts, evidenceRecords,
//                  legacyEstimatedLevel? },
//     listening: { estimatedLevel: null, status: 'insufficient_evidence' },
//     reading:   { estimatedLevel: null, status: 'insufficient_evidence' },
//     writing:   { estimatedLevel: null, status: 'insufficient_evidence' },
//   },
//   activity: { speakingTurns, deckWordsReviewed, uniqueWordsSpoken },  // display-only,
//                                    // never read by assessment/update logic.
//   firstSelectedAt, lastActiveAt,
//   levelHistory: [{ skill, previousLevel, newLevel, recordedAt, confidence,
//                     method, evidenceSummary, evidenceIds }],
// }
//
// skills.speaking.evidenceRecords: [{ id, recordedAt, suggestedLevel,
//   confidence, transcriptExcerpt, evidence, committed }] — one entry per
//   assessment run (committed or not), capped at MAX_EVIDENCE_RECORDS, so
//   there's a full audit trail even for inconclusive/held-pending runs.
//   `committed` is true iff suggestedLevel matches the skill's resulting
//   estimatedLevel after this run (i.e. this evidence agrees with what's
//   currently on record — true for both a fresh corroborated commit and a
//   later reconfirmation of an already-committed level, false for
//   insufficient-evidence runs and for a first, not-yet-corroborated
//   suggestion). levelHistory rows reference the evidenceRecords that
//   produced them via `evidenceIds` (the two corroborating records for a
//   commit).
//
// `status` for speaking is one of:
//   'insufficient_evidence' — no committed level yet (default for a brand
//      new language, or a language whose only assessments so far were
//      inconclusive).
//   'assessed'              — estimatedLevel reflects a committed AI assessment.
//   'legacy_unassessed'     — this entry was migrated from the old
//      activity-count formula; `legacyEstimatedLevel` preserves what that
//      formula used to say, but it is explicitly NOT treated as a real
//      assessment (see migrateLegacyEntry below).
// ---------------------------------------------------------------------------

function emptySpeakingSkill() {
  return {
    estimatedLevel: null,
    status: 'insufficient_evidence',
    confidence: null,
    lastAssessedAt: null,
    turnsSinceLastAssessment: 0,
    pendingSuggestedLevel: null,
    pendingEvidenceId: null,
    pendingTranscripts: [],
    evidenceRecords: [],
  };
}

function emptyUnassessedSkill() {
  // Listening/reading/writing: the app has no exercises that produce
  // evidence for these yet, so they always report insufficient evidence.
  // Kept as real fields (not just absent) so the API/UI shape is already
  // ready for whenever those exercise types exist.
  return { estimatedLevel: null, status: 'insufficient_evidence' };
}

function emptyLanguageEntry(tutorLevel = 'A1') {
  const now = new Date().toISOString();
  return {
    tutorLevel: clampLevel(tutorLevel),
    skills: {
      speaking: emptySpeakingSkill(),
      listening: emptyUnassessedSkill(),
      reading: emptyUnassessedSkill(),
      writing: emptyUnassessedSkill(),
    },
    activity: {
      speakingTurns: 0,
      deckWordsReviewed: 0,
      uniqueWordsSpoken: 0,
    },
    firstSelectedAt: now,
    lastActiveAt: now,
    levelHistory: [],
  };
}

function normalizeHistoryRow(row) {
  return {
    skill: typeof row?.skill === 'string' ? row.skill : 'speaking',
    previousLevel: clampLevelOrNull(row?.previousLevel),
    newLevel: clampLevel(row?.newLevel ?? row?.estimatedLevel),
    recordedAt: row?.recordedAt ?? new Date().toISOString(),
    confidence: VALID_CONFIDENCE.has(row?.confidence) ? row.confidence : null,
    method: typeof row?.method === 'string' ? row.method : (row?.source ?? 'unknown'),
    evidenceSummary: typeof row?.evidenceSummary === 'string' ? row.evidenceSummary : '',
    // References into skills.speaking.evidenceRecords — absent on rows
    // written before evidence records existed (Phase 1 history, or any
    // row predating this field) rather than invented after the fact.
    evidenceIds: Array.isArray(row?.evidenceIds)
      ? row.evidenceIds.filter((id) => typeof id === 'string' && id)
      : [],
  };
}

function normalizeEvidenceRecord(raw) {
  if (!raw || typeof raw !== 'object' || typeof raw.id !== 'string' || !raw.id) {
    return null;
  }
  return {
    id: raw.id,
    recordedAt: raw.recordedAt ?? new Date().toISOString(),
    suggestedLevel: clampLevelOrNull(raw.suggestedLevel),
    confidence: VALID_CONFIDENCE.has(raw.confidence) ? raw.confidence : null,
    transcriptExcerpt: typeof raw.transcriptExcerpt === 'string' ? raw.transcriptExcerpt : '',
    evidence: Array.isArray(raw.evidence)
      ? raw.evidence.filter((s) => typeof s === 'string' && s.trim()).slice(0, 6)
      : [],
    committed: raw.committed === true,
  };
}

function normalizeSpeakingSkill(raw) {
  const base = emptySpeakingSkill();
  if (!raw || typeof raw !== 'object') return base;
  return {
    estimatedLevel: clampLevelOrNull(raw.estimatedLevel),
    status: ['assessed', 'insufficient_evidence', 'legacy_unassessed'].includes(raw.status)
      ? raw.status
      : base.status,
    confidence: VALID_CONFIDENCE.has(raw.confidence) ? raw.confidence : null,
    lastAssessedAt: raw.lastAssessedAt ?? null,
    turnsSinceLastAssessment: Number(raw.turnsSinceLastAssessment ?? 0) || 0,
    pendingSuggestedLevel: clampLevelOrNull(raw.pendingSuggestedLevel),
    pendingEvidenceId: typeof raw.pendingEvidenceId === 'string' ? raw.pendingEvidenceId : null,
    pendingTranscripts: Array.isArray(raw.pendingTranscripts)
      ? raw.pendingTranscripts
          .filter((t) => t && typeof t.text === 'string')
          .slice(-MAX_PENDING_TRANSCRIPTS)
      : [],
    evidenceRecords: Array.isArray(raw.evidenceRecords)
      ? raw.evidenceRecords
          .map(normalizeEvidenceRecord)
          .filter(Boolean)
          .slice(-MAX_EVIDENCE_RECORDS)
      : [],
    ...(raw.legacyEstimatedLevel
      ? { legacyEstimatedLevel: clampLevelOrNull(raw.legacyEstimatedLevel) }
      : {}),
  };
}

function normalizeUnassessedSkill() {
  // Always insufficient evidence for now — see emptyUnassessedSkill.
  return emptyUnassessedSkill();
}

function isNewShapeEntry(entry) {
  return !!entry && typeof entry.skills === 'object' && entry.skills !== null;
}

/**
 * Converts an entry written by the old activity-count formula (flat
 * `estimatedLevel`/`speakingTurns`/`deckWordsReviewed`/... fields, no
 * `skills` object) into the new shape. The old `estimatedLevel` was never a
 * real proficiency assessment — it was a volume score — so it is preserved
 * only as `legacyEstimatedLevel` for transparency/debugging and the real
 * `skills.speaking.estimatedLevel` starts at null with status
 * 'legacy_unassessed' until a genuine AI assessment runs.
 */
function migrateLegacyEntry(entry) {
  const tutorLevel = clampLevel(entry.tutorLevel ?? entry.tutor_level ?? 'A1');
  const legacyEstimatedLevel = clampLevelOrNull(entry.estimatedLevel ?? entry.estimated_level);
  const speaking = emptySpeakingSkill();
  speaking.status = 'legacy_unassessed';
  if (legacyEstimatedLevel) speaking.legacyEstimatedLevel = legacyEstimatedLevel;

  const oldHistory = Array.isArray(entry.levelHistory ?? entry.level_history)
    ? entry.levelHistory ?? entry.level_history
    : [];

  return {
    tutorLevel,
    skills: {
      speaking,
      listening: emptyUnassessedSkill(),
      reading: emptyUnassessedSkill(),
      writing: emptyUnassessedSkill(),
    },
    activity: {
      speakingTurns: Number(entry.speakingTurns ?? entry.speaking_turns ?? 0),
      deckWordsReviewed: Number(entry.deckWordsReviewed ?? entry.deck_words_reviewed ?? 0),
      uniqueWordsSpoken: Number(entry.uniqueWordsSpoken ?? entry.unique_words_spoken ?? 0),
    },
    firstSelectedAt:
      entry.firstSelectedAt ?? entry.first_selected_at ?? new Date().toISOString(),
    lastActiveAt: entry.lastActiveAt ?? entry.last_active_at ?? new Date().toISOString(),
    // Old history rows are kept for transparency (so a user doesn't lose
    // their visible timeline) but tagged with method 'legacy-activity-formula'
    // so nothing downstream mistakes them for a real assessment.
    levelHistory: oldHistory.map((row) =>
      normalizeHistoryRow({
        skill: 'speaking',
        previousLevel: null,
        newLevel: row.estimatedLevel ?? row.estimated_level,
        recordedAt: row.recordedAt ?? row.recorded_at,
        method: 'legacy-activity-formula',
      }),
    ),
  };
}

function normalizeNewEntry(entry) {
  const defaults = emptyLanguageEntry(entry.tutorLevel);
  return {
    tutorLevel: clampLevel(entry.tutorLevel ?? defaults.tutorLevel),
    skills: {
      speaking: normalizeSpeakingSkill(entry.skills?.speaking),
      listening: normalizeUnassessedSkill(),
      reading: normalizeUnassessedSkill(),
      writing: normalizeUnassessedSkill(),
    },
    activity: {
      speakingTurns: Number(entry.activity?.speakingTurns ?? 0) || 0,
      deckWordsReviewed: Number(entry.activity?.deckWordsReviewed ?? 0) || 0,
      uniqueWordsSpoken: Number(entry.activity?.uniqueWordsSpoken ?? 0) || 0,
    },
    firstSelectedAt: entry.firstSelectedAt ?? defaults.firstSelectedAt,
    lastActiveAt: entry.lastActiveAt ?? defaults.lastActiveAt,
    levelHistory: Array.isArray(entry.levelHistory)
      ? entry.levelHistory.slice(-MAX_HISTORY_ENTRIES).map(normalizeHistoryRow)
      : [],
  };
}

function normalizeLanguageLevels(raw) {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) {
    return {};
  }
  const out = {};
  for (const [code, entry] of Object.entries(raw)) {
    if (!entry || typeof entry !== 'object') continue;
    out[code] = isNewShapeEntry(entry) ? normalizeNewEntry(entry) : migrateLegacyEntry(entry);
  }
  return out;
}

// ---------------------------------------------------------------------------
// Pure update logic — no Strapi/DB access, fully unit-testable.
// ---------------------------------------------------------------------------

function pushLevelHistory(history, row) {
  const next = Array.isArray(history) ? [...history] : [];
  const last = next[next.length - 1];
  const normalized = normalizeHistoryRow(row);
  if (last && last.skill === normalized.skill && last.newLevel === normalized.newLevel) {
    // Same skill, same level as the last recorded entry — nothing changed.
    return next;
  }
  next.push(normalized);
  if (next.length > MAX_HISTORY_ENTRIES) {
    return next.slice(next.length - MAX_HISTORY_ENTRIES);
  }
  return next;
}

/**
 * Records one speaking turn as *activity* only — bumps counters and buffers
 * the transcript for the next assessment. Never touches estimatedLevel:
 * practice volume is evidence that an assessment should eventually happen,
 * not evidence of what the assessment should conclude.
 */
function recordSpeakingTurn(entry, { text, hasCorrections = false, wordCount = 0 } = {}) {
  const now = new Date().toISOString();
  const speaking = entry.skills.speaking;
  const pendingTranscripts = [...speaking.pendingTranscripts];
  if (text && String(text).trim()) {
    pendingTranscripts.push({
      text: String(text).trim(),
      hasCorrections: !!hasCorrections,
      wordCount: Number(wordCount) || 0,
      recordedAt: now,
    });
    if (pendingTranscripts.length > MAX_PENDING_TRANSCRIPTS) pendingTranscripts.shift();
  }

  return {
    ...entry,
    activity: { ...entry.activity, speakingTurns: entry.activity.speakingTurns + 1 },
    skills: {
      ...entry.skills,
      speaking: {
        ...speaking,
        turnsSinceLastAssessment: speaking.turnsSinceLastAssessment + 1,
        pendingTranscripts,
      },
    },
    lastActiveAt: now,
  };
}

/** Deck review activity — counters only. Must never influence estimatedLevel:
 * reviewing a word is not the same as having demonstrated you know it. */
function recordDeckReview(entry, wordsDelta = 1) {
  return {
    ...entry,
    activity: {
      ...entry.activity,
      deckWordsReviewed: entry.activity.deckWordsReviewed + Math.max(1, Number(wordsDelta) || 1),
    },
    lastActiveAt: new Date().toISOString(),
  };
}

function recordUniqueWordsSpoken(entry, newWords = 0) {
  if (!newWords) return entry;
  return {
    ...entry,
    activity: {
      ...entry.activity,
      uniqueWordsSpoken: entry.activity.uniqueWordsSpoken + Math.max(0, Number(newWords) || 0),
    },
  };
}

function isSpeakingAssessmentDue(entry) {
  const speaking = entry?.skills?.speaking;
  return (
    !!speaking &&
    speaking.turnsSinceLastAssessment >= ASSESSMENT_TURN_THRESHOLD &&
    speaking.pendingTranscripts.length > 0
  );
}

/**
 * Applies the result of a speaking-proficiency assessment call to an entry.
 *
 * Conservative-update rule (deliberately NOT a numeric score threshold —
 * see spec: avoid "arbitrary activity-count thresholds disguised as CEFR
 * standards"): a level only ever gets committed to `estimatedLevel` once
 * two *consecutive* assessments — each over a fresh batch of turns, since
 * `pendingTranscripts` is cleared after every assessment — agree on the
 * same level. One strong (or weak) sample alone never moves the needle,
 * in either direction, and the same rule naturally allows downward
 * reassessment: it doesn't special-case "up" vs "down", only "agreement".
 *
 * `assessment` is the result of assessSpeakingProficiency():
 *   { ok: false, ... }                      — provider error or malformed
 *                                              JSON; entry is returned
 *                                              unchanged (including NOT
 *                                              consuming the pending
 *                                              batch, so the very next
 *                                              turn retries automatically).
 *   { ok: true, result: { level, confidence, evidenceSufficient, evidence,
 *                          strengths, areasToImprove, independentlyProduced } }
 */
/** Short, size-bounded excerpt for an evidence record — not the full
 * transcript batch (which is already cleared from pendingTranscripts once
 * assessed), just enough to recognize what was judged. */
function buildTranscriptExcerpt(transcripts) {
  if (!Array.isArray(transcripts) || transcripts.length === 0) return '';
  return transcripts
    .slice(-2)
    .map((t) => {
      const text = String(t?.text ?? '').trim();
      return text.length > 80 ? `${text.slice(0, 77)}...` : text;
    })
    .filter(Boolean)
    .join(' / ');
}

function applySpeakingAssessmentResult(entry, assessment) {
  if (!assessment || assessment.ok !== true) {
    return entry;
  }

  const speaking = entry.skills.speaking;
  const now = new Date().toISOString();
  const result = assessment.result;

  // One evidence record per assessment run, committed or not — see the
  // `evidenceRecords` doc comment above the shape block for what
  // `committed` means here. `appendEvidenceRecord` below finalizes each
  // branch's record with the right `committed`/id before pushing it.
  const baseEvidenceRecord = {
    id: randomUUID(),
    recordedAt: now,
    suggestedLevel: result.evidenceSufficient ? (result.level ?? null) : null,
    confidence: result.confidence,
    transcriptExcerpt: buildTranscriptExcerpt(speaking.pendingTranscripts),
    evidence: result.evidence ?? [],
  };

  function appendEvidenceRecord(committed) {
    const record = { ...baseEvidenceRecord, committed };
    const next = [...speaking.evidenceRecords, record];
    const capped = next.length > MAX_EVIDENCE_RECORDS
      ? next.slice(next.length - MAX_EVIDENCE_RECORDS)
      : next;
    return { record, evidenceRecords: capped };
  }

  const consumedBase = {
    ...speaking,
    pendingTranscripts: [],
    turnsSinceLastAssessment: 0,
    lastAssessedAt: now,
    confidence: result.confidence,
  };

  if (!result.evidenceSufficient || !result.level) {
    const { evidenceRecords } = appendEvidenceRecord(false);
    return {
      ...entry,
      skills: {
        ...entry.skills,
        speaking: {
          ...consumedBase,
          // Keep an existing committed level as-is on an inconclusive
          // sample; only entries with no committed level yet stay/remain
          // explicitly unassessed.
          status: speaking.estimatedLevel ? speaking.status : 'insufficient_evidence',
          evidenceRecords,
        },
      },
    };
  }

  const newLevel = result.level;
  const currentLevel = speaking.estimatedLevel;

  if (newLevel === currentLevel) {
    // Reconfirms the level already on record — nothing to commit, no new
    // history entry (an unchanged level must not create duplicate entries).
    // Still recorded, and marked committed: it agrees with what's on file.
    const { evidenceRecords } = appendEvidenceRecord(true);
    return {
      ...entry,
      skills: {
        ...entry.skills,
        speaking: {
          ...consumedBase,
          status: 'assessed',
          pendingSuggestedLevel: null,
          pendingEvidenceId: null,
          evidenceRecords,
        },
      },
    };
  }

  if (speaking.pendingSuggestedLevel === newLevel) {
    // Second consecutive assessment agreeing on a different level — commit.
    const { record, evidenceRecords } = appendEvidenceRecord(true);
    const evidenceIds = [speaking.pendingEvidenceId, record.id].filter(Boolean);
    return {
      ...entry,
      skills: {
        ...entry.skills,
        speaking: {
          ...consumedBase,
          status: 'assessed',
          estimatedLevel: newLevel,
          pendingSuggestedLevel: null,
          pendingEvidenceId: null,
          evidenceRecords,
        },
      },
      levelHistory: pushLevelHistory(entry.levelHistory, {
        skill: 'speaking',
        previousLevel: currentLevel,
        newLevel,
        confidence: result.confidence,
        method: 'ai-assessment-v1',
        evidenceSummary: (result.evidence || []).slice(0, 2).join(' '),
        evidenceIds,
      }),
      lastActiveAt: now,
    };
  }

  // First suggestion of this level (or it disagreed with the previous
  // pending suggestion, which restarts corroboration) — hold, don't commit.
  const { record, evidenceRecords } = appendEvidenceRecord(false);
  return {
    ...entry,
    skills: {
      ...entry.skills,
      speaking: {
        ...consumedBase,
        status: speaking.estimatedLevel ? 'assessed' : 'insufficient_evidence',
        pendingSuggestedLevel: newLevel,
        pendingEvidenceId: record.id,
        evidenceRecords,
      },
    },
  };
}

// ---------------------------------------------------------------------------
// Thin Strapi-backed wrappers
// ---------------------------------------------------------------------------

async function loadUserLanguageContext(strapi, userId) {
  const { getOrCreateUserProgress } = require('./user-progress-utils');
  const user = await strapi.db.query('plugin::users-permissions.user').findOne({
    where: { id: userId },
    select: ['practice_language', 'english_level'],
  });
  const progress = await getOrCreateUserProgress(strapi, userId);
  const practiceLanguage = String(user?.practice_language ?? 'en').trim() || 'en';
  const tutorLevel = clampLevel(user?.english_level ?? 'A1');
  const languageLevels = normalizeLanguageLevels(
    progress.languageLevels ?? progress.language_levels,
  );
  return { progress, practiceLanguage, tutorLevel, languageLevels };
}

async function persistLanguageLevels(strapi, progressId, languageLevels) {
  await strapi.db.query('api::user-progress.user-progress').update({
    where: { id: progressId },
    data: { languageLevels },
  });
}

async function ensureLanguageEntry(strapi, userId, languageCode, tutorLevel = 'A1') {
  const { progress, languageLevels } = await loadUserLanguageContext(strapi, userId);
  const code = String(languageCode ?? 'en').trim() || 'en';
  if (!languageLevels[code]) {
    languageLevels[code] = emptyLanguageEntry(tutorLevel);
  } else if (tutorLevel) {
    languageLevels[code].tutorLevel = clampLevel(tutorLevel);
  }
  await persistLanguageLevels(strapi, progress.id, languageLevels);
  return languageLevels[code];
}

/** Manual language selection / tutor-level change — never touches `skills`. */
async function recordLanguageSelection(strapi, userId, languageCode, tutorLevel = 'A1') {
  const { progress, languageLevels } = await loadUserLanguageContext(strapi, userId);
  const code = String(languageCode ?? 'en').trim() || 'en';
  const level = clampLevel(tutorLevel);
  if (!languageLevels[code]) {
    languageLevels[code] = emptyLanguageEntry(level);
  } else {
    languageLevels[code].tutorLevel = level;
    languageLevels[code].lastActiveAt = new Date().toISOString();
  }
  await persistLanguageLevels(strapi, progress.id, languageLevels);
  return languageLevels[code];
}

async function updateTutorLevelForLanguage(strapi, userId, languageCode, tutorLevel) {
  return recordLanguageSelection(strapi, userId, languageCode, tutorLevel);
}

/**
 * Called after every scored speaking turn. Updates activity counters/buffer
 * only (see recordSpeakingTurn); if enough turns have accumulated since the
 * last assessment, fires a new assessment *without awaiting it* so this
 * never adds AI-call latency to the user's chat response. The assessment's
 * own persistence happens independently once it resolves.
 */
async function recordSpeakingActivity(
  strapi,
  userId,
  { languageCode, isPerfect = false, correctionCount = 0, newWords = 0, userText = '' } = {},
) {
  const { progress, practiceLanguage, tutorLevel, languageLevels } =
    await loadUserLanguageContext(strapi, userId);
  const code = String(languageCode ?? practiceLanguage ?? 'en').trim() || 'en';
  let entry = languageLevels[code] ?? emptyLanguageEntry(tutorLevel);

  const wordCount = String(userText ?? '').trim().split(/\s+/).filter(Boolean).length;
  entry = recordSpeakingTurn(entry, {
    text: userText,
    hasCorrections: correctionCount > 0,
    wordCount,
  });
  entry = recordUniqueWordsSpoken(entry, newWords);

  languageLevels[code] = entry;
  await persistLanguageLevels(strapi, progress.id, languageLevels);

  if (isSpeakingAssessmentDue(entry)) {
    void runSpeakingAssessment(strapi, userId, code).catch((err) => {
      strapi.log.warn('[recordSpeakingActivity] assessment trigger failed', err);
    });
  }

  return entry;
}

/** Deck review activity — counters only, never feeds estimatedLevel. */
async function recordDeckReviewActivity(strapi, userId, { languageCode, wordsDelta = 1 } = {}) {
  const { progress, practiceLanguage, tutorLevel, languageLevels } =
    await loadUserLanguageContext(strapi, userId);
  const code = String(languageCode ?? practiceLanguage ?? 'en').trim() || 'en';
  const entry = languageLevels[code] ?? emptyLanguageEntry(tutorLevel);

  languageLevels[code] = recordDeckReview(entry, wordsDelta);
  await persistLanguageLevels(strapi, progress.id, languageLevels);
  return languageLevels[code];
}

/**
 * Runs one milestone-triggered AI speaking assessment and persists the
 * (possibly unchanged) result. Reloads state fresh rather than reusing the
 * caller's snapshot, since this runs asynchronously after the turn that
 * triggered it. If the pending batch somehow already got consumed (e.g. a
 * concurrent trigger beat us to it), this is a safe no-op.
 */
async function runSpeakingAssessment(strapi, userId, languageCode) {
  const { assessSpeakingProficiency } = require('./speaking-proficiency-assessment');
  const { progress, languageLevels } = await loadUserLanguageContext(strapi, userId);
  const entry = languageLevels[languageCode];
  if (!entry || !isSpeakingAssessmentDue(entry)) {
    return null;
  }

  const assessment = await assessSpeakingProficiency({
    languageCode,
    transcripts: entry.skills.speaking.pendingTranscripts,
    currentLevel: entry.skills.speaking.estimatedLevel,
  });

  if (!assessment.ok) {
    strapi.log.warn(
      `[runSpeakingAssessment] assessment unavailable for user ${userId}/${languageCode}: ${assessment.reason}`,
    );
    return null;
  }

  const updated = applySpeakingAssessmentResult(entry, assessment);
  languageLevels[languageCode] = updated;
  await persistLanguageLevels(strapi, progress.id, languageLevels);
  return updated;
}

function formatSkillForResponse(skill) {
  if (!skill) return { estimatedLevel: null, status: 'insufficient_evidence' };
  const { estimatedLevel, status, confidence, lastAssessedAt } = skill;
  return { estimatedLevel, status, confidence: confidence ?? null, lastAssessedAt: lastAssessedAt ?? null };
}

function formatHistoryForResponse(levelHistory) {
  // Flattened to the shape the Flutter client already expects
  // ({estimatedLevel, recordedAt, source}) so no client changes are needed
  // just to keep reading the timeline — `source` carries the new `method`
  // value (e.g. 'ai-assessment-v1' vs 'legacy-activity-formula') so legacy
  // rows remain visually distinguishable if the UI ever wants to use that.
  return (levelHistory ?? [])
    .filter((row) => row.skill === 'speaking')
    .map((row) => ({
      estimatedLevel: row.newLevel,
      recordedAt: row.recordedAt,
      source: row.method,
    }));
}

function formatLanguageLevelsResponse({
  practiceLanguage,
  tutorLevel,
  languageLevels,
  noteCounts = {},
}) {
  const current = languageLevels[practiceLanguage] ?? emptyLanguageEntry(tutorLevel);
  const currentSpeaking = current.skills.speaking;

  const history = Object.entries(languageLevels)
    .filter(
      ([code, entry]) =>
        code === practiceLanguage ||
        (noteCounts[code] ?? 0) > 0 ||
        (entry.activity.speakingTurns ?? 0) > 0 ||
        (entry.activity.deckWordsReviewed ?? 0) > 0,
    )
    .map(([code, entry]) => ({
      languageCode: code,
      tutorLevel: entry.tutorLevel,
      estimatedLevel: entry.skills.speaking.estimatedLevel,
      estimatedLevelStatus: entry.skills.speaking.status,
      lastActiveAt: entry.lastActiveAt,
      firstSelectedAt: entry.firstSelectedAt,
      speakingTurns: entry.activity.speakingTurns,
      deckWordsReviewed: entry.activity.deckWordsReviewed,
      noteCount: noteCounts[code] ?? 0,
      levelHistory: formatHistoryForResponse(entry.levelHistory),
      skills: {
        speaking: formatSkillForResponse(entry.skills.speaking),
        listening: formatSkillForResponse(entry.skills.listening),
        reading: formatSkillForResponse(entry.skills.reading),
        writing: formatSkillForResponse(entry.skills.writing),
      },
    }))
    .sort((a, b) => String(b.lastActiveAt).localeCompare(String(a.lastActiveAt)));

  return {
    practiceLanguage,
    tutorLevel: current.tutorLevel ?? tutorLevel,
    // Nullable now: null means no committed speaking assessment yet
    // (insufficient evidence or legacy/unassessed) — the client must not
    // assume this is always a valid CEFR string.
    estimatedLevel: currentSpeaking.estimatedLevel,
    estimatedLevelStatus: currentSpeaking.status,
    speakingTurns: current.activity.speakingTurns ?? 0,
    deckWordsReviewed: current.activity.deckWordsReviewed ?? 0,
    uniqueWordsSpoken: current.activity.uniqueWordsSpoken ?? 0,
    levelHistory: formatHistoryForResponse(current.levelHistory),
    languages: history,
  };
}

async function getLanguageLevelsSnapshot(strapi, userId) {
  const { practiceLanguage, tutorLevel, languageLevels } =
    await loadUserLanguageContext(strapi, userId);
  await ensureLanguageEntry(strapi, userId, practiceLanguage, tutorLevel);
  const refreshed = await loadUserLanguageContext(strapi, userId);
  const notes = await strapi.db.query('api::flashcard-note.flashcard-note').findMany({
    where: { user: userId },
    select: ['languageCode'],
  });
  const noteCounts = {};
  for (const note of notes) {
    const code = note.languageCode || 'en';
    noteCounts[code] = (noteCounts[code] ?? 0) + 1;
  }
  return formatLanguageLevelsResponse({
    practiceLanguage: refreshed.practiceLanguage,
    tutorLevel: refreshed.tutorLevel,
    languageLevels: refreshed.languageLevels,
    noteCounts,
  });
}

module.exports = {
  CEFR_LEVELS,
  levelIndex,
  clampLevel,
  clampLevelOrNull,
  ASSESSMENT_TURN_THRESHOLD,
  MAX_PENDING_TRANSCRIPTS,
  MAX_EVIDENCE_RECORDS,
  emptyLanguageEntry,
  normalizeLanguageLevels,
  recordSpeakingTurn,
  recordDeckReview,
  recordUniqueWordsSpoken,
  isSpeakingAssessmentDue,
  applySpeakingAssessmentResult,
  pushLevelHistory,
  recordLanguageSelection,
  updateTutorLevelForLanguage,
  recordSpeakingActivity,
  recordDeckReviewActivity,
  runSpeakingAssessment,
  getLanguageLevelsSnapshot,
  formatLanguageLevelsResponse,
};
