'use strict';

// .apkg import: rows → decks/notes/cards, "Import review scheduling", a full
// file round trip, and plain-text (.txt) import end to end. Uses the same
// in-memory strapi stub approach as flashcard-import.test.js.

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');

const created = [];
let premium = false;
let freeMaxDecks = 2;
let nextCardId = 500;

function stubModule(relPath, exports) {
  const file = require.resolve(path.join('../src/utils', relPath));
  require.cache[file] = { id: file, filename: file, loaded: true, exports };
}

stubModule('flashcard-note-sync', {
  createNoteAndCards: async (_strapi, userId, payload) => {
    if (payload.fields?.Front === 'boom') throw new Error('create failed');
    created.push({ userId, ...payload });
    const cardCount = payload.createReverse ? 2 : 1;
    const cards = Array.from({ length: cardCount }, () => ({ id: nextCardId++ }));
    return { note: { id: created.length }, cards };
  },
});
stubModule('app-feature-config', {
  isPremiumUser: async () => premium,
  getFeatureConfig: async () => ({ freeMaxDecks }),
});

const { importApkgRows, importApkgFile, buildApkgBuffer } = require('../src/utils/flashcard-apkg');
const { importTxt } = require('../src/utils/flashcard-import');

const DECK = 'api::flashcard-deck.flashcard-deck';
const REVIEW = 'api::card-review-state.card-review-state';

function makeStrapi({ decks = [], cards = [], reviews = [] } = {}) {
  const tables = {
    [DECK]: decks.map((d) => ({ isDefault: false, isFiltered: false, ...d })),
    'api::flashcard.flashcard': cards,
    [REVIEW]: reviews,
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
        update: async ({ where, data }) => {
          const row = (tables[uid] ?? []).find((r) => matches(r, where));
          Object.assign(row, data);
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

// ── importApkgRows ─────────────────────────────────────────────────────

test('importApkgRows creates each deck once and keeps note type, fields, tags, media', async () => {
  const strapi = makeStrapi();
  const result = await importApkgRows(strapi, 7, [
    { front: 'go', back: 'gehen', deckName: 'Verbs', tags: ['v'], mediaUrl: '/u/go.mp3' },
    { front: 'run', back: 'laufen', deckName: 'Verbs' },
    {
      front: 'cloze',
      back: '',
      deckName: 'Cloze',
      noteType: 'cloze',
      fields: { Text: '{{c1::Paris}} is in France', Back: '' },
    },
  ]);

  assert.deepEqual(result, { imported: 3, skipped: 0, errors: [] });
  assert.deepEqual(strapi.tables[DECK].map((d) => d.name).sort(), ['Cloze', 'Verbs']);
  assert.equal(created[0].noteType, 'basic');
  assert.deepEqual(created[0].fields, { Front: 'go', Back: 'gehen' });
  assert.deepEqual(created[0].tags, ['v']);
  assert.equal(created[0].mediaUrl, '/u/go.mp3');
  assert.equal(created[2].noteType, 'cloze');
  assert.equal(created[2].fields.Text, '{{c1::Paris}} is in France');
});

test('importApkgRows asks for a reverse card only for optional-reversed notes', async () => {
  await importApkgRows(makeStrapi(), 7, [
    { front: 'a', back: 'b', deckName: 'D', noteType: 'basic_optional_reversed' },
    { front: 'c', back: 'd', deckName: 'D', noteType: 'basic' },
  ]);
  assert.equal(created[0].createReverse, true);
  assert.equal(created[1].createReverse, false);
});

test('scheduling is written to every card of the note when present', async () => {
  const strapi = makeStrapi();
  const scheduling = { state: 'review', intervalDays: 12, easeFactor: 2.5 };
  await importApkgRows(strapi, 7, [
    { front: 'a', back: 'b', deckName: 'D', noteType: 'basic_optional_reversed', scheduling },
  ]);
  const reviews = strapi.tables[REVIEW];
  assert.equal(reviews.length, 2);
  for (const r of reviews) {
    assert.equal(r.state, 'review');
    assert.equal(r.intervalDays, 12);
    assert.equal(r.user, 7);
  }
});

test('scheduling updates an existing review state instead of duplicating it', async () => {
  const strapi = makeStrapi({
    reviews: [{ id: 1, flashcard: 500, user: 7, state: 'new', intervalDays: 0 }],
  });
  nextCardId = 500;
  await importApkgRows(strapi, 7, [
    { front: 'a', back: 'b', deckName: 'D', scheduling: { state: 'review', intervalDays: 3 } },
  ]);
  assert.equal(strapi.tables[REVIEW].length, 1);
  assert.equal(strapi.tables[REVIEW][0].state, 'review');
  assert.equal(strapi.tables[REVIEW][0].intervalDays, 3);
});

test('no scheduling → no review states written', async () => {
  const strapi = makeStrapi();
  await importApkgRows(strapi, 7, [{ front: 'a', back: 'b', deckName: 'D', scheduling: null }]);
  assert.equal(strapi.tables[REVIEW].length, 0);
});

test('failed rows are skipped and errors are capped at 20', async () => {
  const rows = Array.from({ length: 25 }, () => ({ front: 'boom', back: '', deckName: 'D' }));
  rows.push({ front: 'ok', back: 'fine', deckName: 'D' });
  const result = await importApkgRows(makeStrapi(), 7, rows);
  assert.equal(result.imported, 1);
  assert.equal(result.skipped, 25);
  assert.equal(result.errors.length, 20);
  assert.equal(result.errors[0], 'create failed');
});

test('free deck limit: rows land in defaultDeckId instead of failing', async () => {
  freeMaxDecks = 1;
  const strapi = makeStrapi({ decks: [{ id: 5, name: 'Mine', user: 7 }] });
  const result = await importApkgRows(strapi, 7, [{ front: 'a', back: 'b', deckName: 'New deck' }], {
    defaultDeckId: 5,
  });
  assert.equal(result.imported, 1);
  assert.equal(created[0].deckId, 5);
  assert.equal(strapi.tables[DECK].length, 1);
});

// ── .apkg file round trip ──────────────────────────────────────────────

async function exportedApkgFile() {
  const source = makeStrapi({
    decks: [{ id: 5, name: 'Verbs', user: 7 }],
    cards: [{ id: 1, user: 7, front: 'go', back: 'gehen', deck: { id: 5 }, flashcardNote: { id: 11 }, tags: [] }],
    reviews: [
      {
        id: 1,
        flashcard: 1,
        user: 7,
        state: 'review',
        intervalDays: 10,
        easeFactor: 2.5,
        repetitions: 4,
        lapses: 1,
        dueAt: new Date(Date.now() + 5 * 86400000),
      },
    ],
  });
  const buffer = await buildApkgBuffer(source, 7);
  const file = path.join(os.tmpdir(), `apkg-test-${process.pid}-${Date.now()}.apkg`);
  fs.writeFileSync(file, buffer);
  return file;
}

test('importApkgFile imports an exported package into a new deck', async () => {
  const file = await exportedApkgFile();
  try {
    const strapi = makeStrapi();
    const result = await importApkgFile(strapi, 9, file, {});
    assert.equal(result.imported, 1);
    assert.equal(strapi.tables[DECK][0].name, 'Verbs');
    assert.equal(created[0].userId, 9);
    assert.equal(strapi.tables[REVIEW].length, 0, 'scheduling is off by default');
  } finally {
    fs.unlinkSync(file);
  }
});

test('importApkgFile with importScheduling keeps review progress', async () => {
  const file = await exportedApkgFile();
  try {
    const strapi = makeStrapi();
    await importApkgFile(strapi, 9, file, { importScheduling: true });
    const [review] = strapi.tables[REVIEW];
    assert.ok(review, 'a review state was written');
    assert.equal(review.state, 'review');
    assert.equal(review.intervalDays, 10);
  } finally {
    fs.unlinkSync(file);
  }
});

test('importApkgFile rejects a file that is not a deck package', async () => {
  const file = path.join(os.tmpdir(), `not-apkg-${process.pid}.apkg`);
  fs.writeFileSync(file, 'hello');
  try {
    await assert.rejects(importApkgFile(makeStrapi(), 9, file, {}));
  } finally {
    fs.unlinkSync(file);
  }
});

// ── .txt end to end ────────────────────────────────────────────────────

test('importTxt parses directives and imports into the named deck', async () => {
  const strapi = makeStrapi();
  const result = await importTxt(
    strapi,
    7,
    '#deck:Travel\n#tags:trip\nhello\tbonjour\nthanks\tmerci\nno tab here\n',
  );
  assert.equal(result.imported, 2);
  assert.equal(strapi.tables[DECK][0].name, 'Travel');
  assert.deepEqual(
    created.map((c) => c.fields?.Front ?? c.front),
    ['hello', 'thanks'],
  );
});
