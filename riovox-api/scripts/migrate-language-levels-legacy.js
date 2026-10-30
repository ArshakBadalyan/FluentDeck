#!/usr/bin/env node
'use strict';

/**
 * One-time data-cleanup pass: every `user-progress.languageLevels` entry
 * still in the OLD activity-count-formula shape (flat `estimatedLevel`,
 * no `skills` object) gets rewritten into the new shape via
 * `normalizeLanguageLevels()` — the exact same logic the app now applies
 * on every read. Running this script just makes the rewrite permanent in
 * the DB instead of happening implicitly on next read, and prints a
 * before/after report so you can see what changed.
 *
 * Old `estimatedLevel` values are NOT treated as real assessments (see
 * language-level-analytics.js migrateLegacyEntry) — they move to
 * `skills.speaking.legacyEstimatedLevel` for transparency, while the real
 * `skills.speaking.estimatedLevel` becomes null with status
 * 'legacy_unassessed' until a genuine AI assessment runs.
 *
 * This script makes no SQL schema changes — languageLevels is a JSON field.
 *
 * Usage (must run on the project's Node 20, see .nvmrc):
 *   /Users/arshak/.nvm/versions/node/v20.20.2/bin/node scripts/migrate-language-levels-legacy.js [--dry-run]
 */

const { compileStrapi, createStrapi } = require('@strapi/strapi');
const { normalizeLanguageLevels } = require('../src/utils/language-level-analytics');

const DRY_RUN = process.argv.includes('--dry-run');

(async () => {
  const app = await createStrapi(await compileStrapi()).load();
  try {
    const rows = await app.db.query('api::user-progress.user-progress').findMany({
      select: ['id', 'languageLevels'],
    });

    let touched = 0;
    let languagesMigrated = 0;

    for (const row of rows) {
      const raw = row.languageLevels;
      if (!raw || typeof raw !== 'object' || Array.isArray(raw) || Object.keys(raw).length === 0) {
        continue;
      }

      const before = raw;
      const after = normalizeLanguageLevels(raw);

      const legacyCodes = Object.entries(before)
        .filter(([, entry]) => entry && typeof entry === 'object' && !entry.skills)
        .map(([code]) => code);

      if (legacyCodes.length === 0) {
        continue; // already in the new shape
      }

      touched += 1;
      languagesMigrated += legacyCodes.length;

      console.log(`user-progress #${row.id}: migrating ${legacyCodes.join(', ')}`);
      for (const code of legacyCodes) {
        const oldLevel = before[code]?.estimatedLevel ?? before[code]?.estimated_level ?? '?';
        console.log(
          `  ${code}: legacy estimatedLevel "${oldLevel}" -> skills.speaking.legacyEstimatedLevel ` +
            `(status: legacy_unassessed, estimatedLevel: null until reassessed)`,
        );
      }

      if (!DRY_RUN) {
        await app.db.query('api::user-progress.user-progress').update({
          where: { id: row.id },
          data: { languageLevels: after },
        });
      }
    }

    console.log(
      `\n${DRY_RUN ? '[dry run] would have updated' : 'Updated'} ${touched} user-progress row(s), ` +
        `${languagesMigrated} legacy language entr${languagesMigrated === 1 ? 'y' : 'ies'}.`,
    );
  } finally {
    await app.destroy();
  }
})();
