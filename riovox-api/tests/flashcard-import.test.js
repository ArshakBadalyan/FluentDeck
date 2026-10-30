'use strict';

// Import pipeline (CSV / TXT / JSON backup / .apkg) and the .apkg export
// round-trip. DB writes go through a small in-memory strapi stub; note/card
// creation and premium/config lookups are stubbed via require.cache so the
// real parsers, deck resolution and Anki packaging run unchanged.

const test = require('node:test');
const assert = require('node:assert/strict');
const path = require('path');

const created = [];
let premium = false;
let freeMaxDecks = 2;

function stubModule(relPath, exports) {
  const file = require.resolve(path.join('../src/utils', relPath));
  require.cache[file] = { id: file, filename: file, loaded: true, exports };
}

stubModule('flashcard-note-sync', {
  createNoteAndCards: async (_strapi, userId, payload) => {
    if (payload.fields?.Front === 'boom') throw new Error('create failed');
    created.push({ userId, ...payload });
    return { note: { id: created.length }, cards: [] };
  },
});
stubModule('app-feature-config', {
  isPremiumUser: async () => premium,
  getFeatureConfig: async () => ({ freeMaxDecks }),
});

const { parseCsvRows, parseTxtRows, importRows, importCsv } = require('../src/utils/flashcard-import');
const { importJsonBackup } = require('../src/utils/flashcard-import-json');
const { buildApkgBuffer, readApkgRows } = require('../src/utils/flashcard-apkg');
const { cardMatchesFilter, normalizeSourceDeckIds } = require('../src/utils/flashcard-browse-filter');

const DECK = 'api::flashcard-deck.flashcard-deck';

/** Just enough of strapi.db.query for deck lookups/creation and export reads. */
function makeStrapi({ decks = [], cards = [], reviews = [] } = {}) {
  const tables = {
    [DECK]: decks.map((d) => ({ isDefault: false, isFiltered: false, ...d })),
    'api::flashcard.flashcard': cards,
    'api::card-review-state.card-review-state': reviews,
  };
  const matches = (row, where = {}) =>
    Object.entries(where).every(([k, v]) => (typeof v === 'object' && v !== null) || row[k] === v);
  return {
    tables,
    db: {
      query: (uid) => ({
        findMany: async ({ where } = {}) => (tables[uid] ?? []).filter((r) => matches(r, where)),
        findOne: async ({ where } = {}) => (tables[uid] ?? []).find((r) => matches(r, where)) ?? null,
        count: async ({ where } = {}) => (tables[uid] ?? []).filter((r) => matches(r, where)).length,
        create: async ({ data }) => {
          const row = { id: 1000 + tables[uid].length, isFiltered: false, ...data };
          tables[uid].push(row);
          return row;
        },
      }),
    },
  };
}

test.beforeEach(() => {
  created.length = 0;
  premium = false;
  freeMaxDecks = 2;
});

// ── CSV ────────────────────────────────────────────────────────────────

test('parseCsvRows maps header aliases, strips BOM, splits tags', () => {
  const rows = parseCsvRows('﻿Word,Definition,Deck,Tags\nhello,hola,Spanish,"greet; basic"\n');
  assert.deepEqual(rows, [
    { front: 'hello', back: 'hola', deckName: 'Spanish', tags: ['greet', 'basic'], noteType: 'basic' },
  ]);
});

test('parseCsvRows handles quoted commas and escaped quotes', () => {
  const rows = parseCsvRows('Front,Back\n"a, b","say ""hi"""\n');
  assert.equal(rows[0].front, 'a, b');
  assert.equal(rows[0].back, 'say "hi"');
});

test('parseCsvRows falls back to first two columns and skips blank rows', () => {
  const rows = parseCsvRows('x,y\ncat,Katze\n,\n\ndog,Hund\n');
  assert.deepEqual(rows.map((r) => [r.front, r.back]), [['cat', 'Katze'], ['dog', 'Hund']]);
});

// Known limitation, not something this change touches: lines are split
// before quote-aware parsing, so a quoted cell can't contain a newline —
// it becomes two rows instead. Documented here so a future fix is a
// visible behavior change, not a silent one.
test('parseCsvRows splits a newline inside a quoted cell into two rows', () => {
  const rows = parseCsvRows('Front,Back\n"run","line one\nline two"\nwalk,gehen\n');
  assert.equal(rows.length, 3);
  assert.equal(rows[0].back, 'line one');
  assert.equal(rows[1].front, 'line two');
  assert.equal(rows[2].front, 'walk');
});

test('parseCsvRows reads the app\'s own CSV export format', () => {
  const exported =
    '﻿Deck,Front,Back,Type,Tags,State,Due\n' +
    '"Verbs","go","gehen","basic","v; a1","new",""\n';
  const [row] = parseCsvRows(exported);
  assert.equal(row.deckName, 'Verbs');
  assert.equal(row.front, 'go');
  assert.equal(row.back, 'gehen');
  assert.deepEqual(row.tags, ['v', 'a1']);
});

test('parseCsvRows returns nothing for empty input', () => {
  assert.deepEqual(parseCsvRows(''), []);
  assert.deepEqual(parseCsvRows(null), []);
});

// ── TXT (Anki "Notes in plain text") ───────────────────────────────────

test('parseTxtRows applies #deck, #tags and #columns directives', () => {
  const rows = parseTxtRows('#deck: French\n#tags: fr a1\n#columns: Back\tFront\nchat\tcat\n');
  assert.deepEqual(rows, [
    { front: 'cat', back: 'chat', deckName: 'French', tags: ['fr', 'a1'], noteType: 'basic' },
  ]);
});

test('parseTxtRows detects cloze and skips lines without a tab', () => {
  const rows = parseTxtRows('no tab here\n{{c1::Paris}} is the capital\tFrance\n');
  assert.equal(rows.length, 1);
  assert.equal(rows[0].noteType, 'cloze');
});

// ── importRows / deck resolution ───────────────────────────────────────

test('importRows creates each named deck once and imports every row', async () => {
  const strapi = makeStrapi();
  const result = await importRows(strapi, 7, [
    { front: 'a', back: '1', deckName: 'Imported' },
    { front: 'b', back: '2', deckName: 'Imported' },
  ]);
  assert.deepEqual(result, { imported: 2, skipped: 0, errors: [] });
  assert.equal(strapi.tables[DECK].length, 1);
  assert.equal(strapi.tables[DECK][0].name, 'Imported');
  assert.ok(created.every((c) => c.deckId === strapi.tables[DECK][0].id && c.userId === 7));
});

test('importRows reuses an existing deck with the same name', async () => {
  const strapi = makeStrapi({ decks: [{ id: 5, name: 'Verbs', user: 7 }] });
  await importRows(strapi, 7, [{ front: 'go', back: 'gehen', deckName: 'Verbs' }]);
  assert.equal(strapi.tables[DECK].length, 1);
  assert.equal(created[0].deckId, 5);
});

test('importRows uses defaultDeckId when a row has no deck name', async () => {
  const strapi = makeStrapi();
  await importRows(strapi, 7, [{ front: 'x', back: 'y' }], { defaultDeckId: 42 });
  assert.equal(created[0].deckId, 42);
});

test('importRows strips HTML and skips rows that end up empty', async () => {
  const strapi = makeStrapi();
  const result = await importRows(
    strapi,
    7,
    [{ front: '<b>bold</b>', back: '<i>it</i>' }, { front: '<br>', back: ' ' }],
    { defaultDeckId: 1 },
  );
  assert.equal(result.imported, 1);
  assert.equal(result.skipped, 1);
  assert.deepEqual(created[0].fields, { Front: 'bold', Back: 'it' });
});

test('importRows counts failed rows as skipped with their error', async () => {
  const strapi = makeStrapi();
  const result = await importRows(strapi, 7, [{ front: 'boom', back: 'x' }], { defaultDeckId: 1 });
  assert.equal(result.skipped, 1);
  assert.deepEqual(result.errors, ['create failed']);
});

test('free deck limit falls back to defaultDeckId instead of failing', async () => {
  freeMaxDecks = 0;
  const strapi = makeStrapi();
  const result = await importRows(strapi, 7, [{ front: 'a', back: 'b', deckName: 'New' }], {
    defaultDeckId: 9,
  });
  assert.equal(result.imported, 1);
  assert.equal(created[0].deckId, 9);
  assert.equal(strapi.tables[DECK].length, 0);
});

test('free deck limit without a fallback reports the limit', async () => {
  freeMaxDecks = 0;
  const result = await importRows(makeStrapi(), 7, [{ front: 'a', back: 'b', deckName: 'New' }]);
  assert.equal(result.imported, 0);
  assert.match(result.errors[0], /Free tier limit/);
});

test('createDecks=false refuses unknown decks', async () => {
  const result = await importRows(makeStrapi(), 7, [{ front: 'a', back: 'b', deckName: 'Nope' }], {
    createDecks: false,
  });
  assert.match(result.errors[0], /does not exist/);
});

test('importCsv parses then imports', async () => {
  const result = await importCsv(makeStrapi(), 7, 'Front,Back\nja,yes\n', { defaultDeckId: 3 });
  assert.equal(result.imported, 1);
  assert.deepEqual(created[0].fields, { Front: 'ja', Back: 'yes' });
});

// ── JSON backup ────────────────────────────────────────────────────────

test('importJsonBackup rejects payloads without a cards array', async () => {
  await assert.rejects(importJsonBackup(makeStrapi(), 7, null), /Invalid backup JSON/);
  await assert.rejects(importJsonBackup(makeStrapi(), 7, { decks: [] }), /cards array/);
});

test('importJsonBackup maps deck ids to names and card types to note types', async () => {
  premium = true;
  const strapi = makeStrapi();
  const result = await importJsonBackup(strapi, 7, {
    decks: [{ id: 1, name: 'Backup deck' }],
    cards: [
      { deckId: 1, front: 'f', back: 'b', tags: ['t'] },
      { deckId: 1, front: '{{c1::x}}', back: '', cardType: 'cloze' },
      { deckId: 1, front: 'q', back: 'a', cardType: 'type_answer' },
    ],
  });
  assert.equal(result.imported, 3);
  assert.equal(strapi.tables[DECK][0].name, 'Backup deck');
  assert.deepEqual(created.map((c) => c.noteType), ['basic', 'cloze', 'basic_type_answer']);
  assert.deepEqual(created[0].tags, ['t']);
});

// ── .apkg export → import round trip ───────────────────────────────────

test('buildApkgBuffer exports cards that readApkgRows can import back', async () => {
  const strapi = makeStrapi({
    decks: [{ id: 5, name: 'Verbs', user: 7 }, { id: 6, name: 'Nouns', user: 7 }],
    cards: [
      { id: 1, user: 7, front: 'go', back: 'gehen', deck: { id: 5 }, flashcardNote: { id: 11 }, tags: ['v'] },
      { id: 2, user: 7, front: 'house', back: 'Haus', deck: { id: 6 }, flashcardNote: { id: 12 }, tags: [] },
    ],
  });
  const buffer = await buildApkgBuffer(strapi, 7);
  assert.ok(buffer.length > 0);

  const rows = await readApkgRows(buffer);
  const byFront = Object.fromEntries(rows.map((r) => [r.front, r]));
  assert.equal(rows.length, 2);
  assert.equal(byFront.go.back, 'gehen');
  assert.equal(byFront.go.deckName, 'Verbs');
  assert.equal(byFront.house.deckName, 'Nouns');
});

test('buildApkgBuffer works for an empty collection', async () => {
  const buffer = await buildApkgBuffer(makeStrapi(), 7);
  const rows = await readApkgRows(buffer);
  assert.deepEqual(rows, []);
});

test('readApkgRows rejects a zip without a collection database', async () => {
  const AdmZip = require('adm-zip');
  const zip = new AdmZip();
  zip.addFile('media', Buffer.from('{}'));
  await assert.rejects(readApkgRows(zip.toBuffer()), /missing collection database/);
});

// ── Filtered deck source decks ─────────────────────────────────────────

test('filtered decks accept several source decks and legacy sourceDeckId', () => {
  assert.deepEqual(normalizeSourceDeckIds({ sourceDeckIds: [3, '4', 3], sourceDeckId: 5 }), [3, 4, 5]);
  assert.deepEqual(normalizeSourceDeckIds({}), []);

  const card = { deckId: 4, front: 'a', back: 'b', tags: [] };
  assert.equal(cardMatchesFilter(card, null, { sourceDeckIds: [3, 4] }), true);
  assert.equal(cardMatchesFilter(card, null, { sourceDeckIds: [3] }), false);
  assert.equal(cardMatchesFilter(card, null, { sourceDeckId: 4 }), true);
  assert.equal(cardMatchesFilter(card, null, {}), true);
});
