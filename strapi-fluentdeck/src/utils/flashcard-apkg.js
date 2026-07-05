'use strict';

const fs = require('fs');
const os = require('os');
const path = require('path');
const crypto = require('crypto');
const AdmZip = require('adm-zip');
const Database = require('better-sqlite3');
const { decompress } = require('fzstd');
const { importRows, stripHtml } = require('./flashcard-import');
const { uploadFlashcardMedia, absoluteMediaUrl } = require('./flashcard-media');

const MEDIA_REF_RE = /(?:src|href)\s*=\s*["']([^"']+)["']/gi;
const SOUND_TAG_RE = /\[sound:([^\]]+)\]/gi;

const FIELD_SEP = '\x1f';
const BASIC_MODEL_ID = 1;
const CLOZE_MODEL_ID = 2;
const SQLITE_MAGIC = Buffer.from('SQLite format 3');

function extractCollectionSqlite(buffer) {
  if (buffer.subarray(0, 15).equals(SQLITE_MAGIC)) {
    return buffer;
  }

  // zstd-compressed collection.anki21 (protobuf wrapper with embedded sqlite)
  if (buffer.length > 4 && buffer[0] === 0x28 && buffer[1] === 0xb5) {
    const decompressed = Buffer.from(decompress(buffer));
    const idx = decompressed.indexOf(SQLITE_MAGIC);
    if (idx >= 0) return decompressed.subarray(idx);
  }

  const embedded = buffer.indexOf(SQLITE_MAGIC);
  if (embedded >= 0) return buffer.subarray(embedded);

  throw new Error('Unsupported .apkg collection format (expected SQLite or zstd-compressed anki21)');
}

function mapImportedModelToNoteType(model) {
  if (model?.type === 1) return 'cloze';
  const name = String(model?.name ?? '').toLowerCase();
  if (name.includes('cloze')) return 'cloze';
  if (name.includes('optional') && name.includes('reversed')) return 'basic_optional_reversed';
  if (name.includes('reversed')) return 'basic_reversed';
  if (name.includes('type') && name.includes('answer')) return 'basic_type_answer';
  return 'basic';
}

function buildFieldsMap(model, fieldValues) {
  const names = (model?.flds ?? []).map((f) => f.name);
  const fields = {};
  names.forEach((name, idx) => {
    fields[name] = fieldValues[idx] ?? '';
  });
  if (!names.length) {
    fields.Front = fieldValues[0] ?? '';
    fields.Back = fieldValues[1] ?? '';
  }
  return fields;
}

function importedCardToReviewState(sourceCard, colCrt) {
  const queue = sourceCard.queue ?? 0;
  const factor = (sourceCard.factor ?? 2500) / 1000;
  const now = new Date();

  if (queue === -1) {
    return { state: 'review', suspended: true, intervalDays: sourceCard.ivl ?? 0, easeFactor: factor, dueAt: now, repetitions: sourceCard.reps ?? 0, lapses: sourceCard.lapses ?? 0, learningStep: 0 };
  }

  if (queue === 0 || sourceCard.type === 0) {
    return { state: 'new', intervalDays: 0, easeFactor: factor, dueAt: now, repetitions: 0, lapses: sourceCard.lapses ?? 0, learningStep: 0 };
  }

  if (queue === 1 || queue === 3) {
    let dueAt = now;
    if (sourceCard.due > 1_000_000_000) {
      dueAt = new Date(sourceCard.due * 1000);
    } else if (sourceCard.due > 0) {
      dueAt = new Date(now.getTime() + sourceCard.due * 60 * 1000);
    }
    return {
      state: queue === 3 ? 'relearning' : 'learning',
      intervalDays: 0,
      easeFactor: factor,
      dueAt,
      repetitions: sourceCard.reps ?? 0,
      lapses: sourceCard.lapses ?? 0,
      learningStep: 0,
    };
  }

  if (queue === 2) {
    let dueAt = now;
    if (sourceCard.due > 1_000_000_000) {
      dueAt = new Date(sourceCard.due * 1000);
    } else if (colCrt && sourceCard.due > 0) {
      dueAt = new Date((colCrt + sourceCard.due * 86400) * 1000);
    }
    return {
      state: 'review',
      intervalDays: sourceCard.ivl ?? 0,
      easeFactor: factor,
      dueAt,
      repetitions: sourceCard.reps ?? 0,
      lapses: sourceCard.lapses ?? 0,
      learningStep: 0,
    };
  }

  return null;
}

function reviewStateToImportedCard(review, colCrt) {
  const rs = review ?? {};
  const ease = Math.round((rs.easeFactor ?? 2.5) * 1000);
  const now = Math.floor(Date.now() / 1000);

  if (rs.suspended) {
    return { type: 2, queue: -1, due: 0, ivl: rs.intervalDays ?? 0, factor: ease, reps: rs.repetitions ?? 0, lapses: rs.lapses ?? 0 };
  }

  if (rs.state === 'new') {
    return { type: 0, queue: 0, due: 0, ivl: 0, factor: ease, reps: 0, lapses: rs.lapses ?? 0 };
  }

  if (rs.state === 'learning' || rs.state === 'relearning') {
    const dueTs = rs.dueAt ? Math.floor(new Date(rs.dueAt).getTime() / 1000) : now + 600;
    return {
      type: 1,
      queue: rs.state === 'relearning' ? 3 : 1,
      due: dueTs,
      ivl: 0,
      factor: ease,
      reps: rs.repetitions ?? 0,
      lapses: rs.lapses ?? 0,
    };
  }

  const ivl = Math.max(1, Math.round(rs.intervalDays ?? 1));
  const dueDay = rs.dueAt && colCrt
    ? Math.max(1, Math.floor(new Date(rs.dueAt).getTime() / 86400000) - Math.floor(colCrt / 86400))
    : ivl;
  return {
    type: 2,
    queue: 2,
    due: dueDay,
    ivl,
    factor: ease,
    reps: rs.repetitions ?? 0,
    lapses: rs.lapses ?? 0,
  };
}

async function applyImportedReviewState(strapi, userId, flashcardId, scheduling) {
  if (!scheduling) return;
  let review = await strapi.db.query('api::card-review-state.card-review-state').findOne({
    where: { flashcard: flashcardId, user: userId },
  });
  if (!review) {
    review = await strapi.db.query('api::card-review-state.card-review-state').create({
      data: { ...scheduling, flashcard: flashcardId, user: userId },
    });
    return;
  }
  await strapi.db.query('api::card-review-state.card-review-state').update({
    where: { id: review.id },
    data: scheduling,
  });
}

function nowSecs() {
  return Math.floor(Date.now() / 1000);
}

function randomGuid() {
  return crypto.randomBytes(8).toString('base64url').slice(0, 10);
}

function fieldChecksum(text) {
  const hash = crypto.createHash('sha1').update(String(text)).digest();
  return hash.readUInt32BE(0);
}

function readMediaMap(zip) {
  const entry = zip.getEntry('media');
  if (!entry) return {};
  try {
    return JSON.parse(entry.getData().toString('utf8'));
  } catch (_) {
    return {};
  }
}

function filenameToMediaIndex(mediaMap) {
  const map = {};
  for (const [idx, name] of Object.entries(mediaMap)) {
    map[String(name)] = String(idx);
  }
  return map;
}

function filenameFromRef(ref, index) {
  try {
    const base = path.basename(new URL(ref, 'http://local').pathname);
    if (base && base !== '/') return base;
  } catch (_) {
    // ignore
  }
  const ext = path.extname(ref);
  return `media-${index}${ext || ''}`;
}

async function loadMediaBytes(strapi, ref) {
  if (!ref || ref.startsWith('data:')) return null;

  const uploadsMatch = ref.match(/\/uploads\/(.+)$/);
  if (uploadsMatch) {
    const localPath = path.join(process.cwd(), 'public', 'uploads', uploadsMatch[1]);
    if (fs.existsSync(localPath)) return fs.readFileSync(localPath);
  }

  const serverUrl = strapi?.config?.get?.('server.url') ?? '';
  if (serverUrl && ref.startsWith('/')) {
    const localPath = path.join(process.cwd(), 'public', ref.replace(/^\//, ''));
    if (fs.existsSync(localPath)) return fs.readFileSync(localPath);
  }

  if (ref.startsWith('http://') || ref.startsWith('https://')) {
    const res = await fetch(ref);
    if (res.ok) return Buffer.from(await res.arrayBuffer());
  }

  return null;
}

function rewriteHtmlMediaRefs(html, refToFilename) {
  if (!html) return html;
  return String(html).replace(MEDIA_REF_RE, (match, ref) => {
    if (ref.startsWith('data:')) return match;
    const filename = refToFilename.get(ref);
    return filename ? match.replace(ref, filename) : match;
  });
}

function resolveMediaFilename(ref, mediaMap, filenameToIndex) {
  if (!ref) return null;
  const base = path.basename(ref);
  if (filenameToIndex[base] != null) return base;
  if (filenameToIndex[ref] != null) return ref;
  for (const [filename, idx] of Object.entries(filenameToIndex)) {
    if (filename === base || filename.endsWith(`/${base}`)) return filename;
    if (mediaMap[idx] === base || mediaMap[idx] === ref) return mediaMap[idx];
  }
  return base;
}

async function importSoundTags(strapi, html, zip, mediaMap, filenameToIndex) {
  if (!html || !Object.keys(filenameToIndex).length) {
    return { html: html ?? '', mediaUrl: null };
  }

  let result = String(html);
  let mediaUrl = null;
  const matches = [...String(html).matchAll(SOUND_TAG_RE)];

  for (const match of matches) {
    const soundFile = match[1];
    const resolved = resolveMediaFilename(soundFile, mediaMap, filenameToIndex);
    const idx = resolved ? filenameToIndex[resolved] : filenameToIndex[soundFile];
    if (idx == null) continue;
    const entry = zip.getEntry(String(idx));
    if (!entry) continue;

    const tmpPath = path.join(os.tmpdir(), `apkg-sound-${Date.now()}-${idx}`);
    fs.writeFileSync(tmpPath, entry.getData());
    try {
      const uploaded = await uploadFlashcardMedia(strapi, {
        filepath: tmpPath,
        originalFilename: soundFile,
        name: soundFile,
      });
      const url = absoluteMediaUrl(strapi, uploaded.url);
      mediaUrl = mediaUrl ?? url;
      result = result.split(match[0]).join(`<audio src="${url}"></audio>`);
    } finally {
      try { fs.unlinkSync(tmpPath); } catch (_) { /* ignore */ }
    }
  }

  return { html: result, mediaUrl };
}

async function importHtmlMedia(strapi, html, zip, filenameToIndex, mediaMap = {}) {
  if (!html || !Object.keys(filenameToIndex).length) {
    return { html: html ?? '', mediaUrl: null };
  }

  let result = String(html);
  let mediaUrl = null;
  const refs = new Set();
  let match;
  const re = new RegExp(MEDIA_REF_RE.source, 'gi');
  while ((match = re.exec(html)) !== null) {
    if (match[1]) refs.add(match[1]);
  }

  for (const ref of refs) {
    const resolved = resolveMediaFilename(ref, mediaMap, filenameToIndex);
    const idx = resolved ? filenameToIndex[resolved] : filenameToIndex[ref];
    if (idx == null) continue;
    const entry = zip.getEntry(String(idx));
    if (!entry) continue;

    const tmpPath = path.join(os.tmpdir(), `apkg-media-${Date.now()}-${idx}`);
    fs.writeFileSync(tmpPath, entry.getData());
    try {
      const uploaded = await uploadFlashcardMedia(strapi, {
        filepath: tmpPath,
        originalFilename: resolved ?? ref,
        name: resolved ?? ref,
      });
      const url = absoluteMediaUrl(strapi, uploaded.url);
      if (!mediaUrl && (/\.(mp3|wav|m4a|ogg|aac|svg)(\?|$)/i.test(ref) || /\.(mp3|wav|m4a|ogg|aac|svg)(\?|$)/i.test(resolved ?? ''))) {
        mediaUrl = url;
      }
      result = result.split(ref).join(url);
    } finally {
      try {
        fs.unlinkSync(tmpPath);
      } catch (_) {
        // ignore
      }
    }
  }

  return { html: result, mediaUrl };
}

function basicModelJson() {
  return {
    [String(BASIC_MODEL_ID)]: {
      id: BASIC_MODEL_ID,
      name: 'Basic',
      type: 0,
      mod: nowSecs(),
      usn: 0,
      sortf: 0,
      did: 1,
      tmpls: [
        {
          name: 'Card 1',
          ord: 0,
          qfmt: '{{Front}}',
          afmt: '{{FrontSide}}\n\n<hr id=answer>\n\n{{Back}}',
          bqfmt: '',
          bafmt: '',
          did: null,
          bfont: '',
          bsize: 0,
        },
      ],
      flds: [
        { name: 'Front', ord: 0, sticky: false, rtl: false, font: 'Arial', size: 20, media: [] },
        { name: 'Back', ord: 1, sticky: false, rtl: false, font: 'Arial', size: 20, media: [] },
      ],
      css: '.card{font-family:arial;font-size:20px;text-align:center;color:black;background-color:white;}',
      latexPre: '',
      latexPost: '',
      latexsvg: false,
      req: [[0, 'any', [0]]],
    },
    [String(CLOZE_MODEL_ID)]: {
      id: CLOZE_MODEL_ID,
      name: 'Cloze',
      type: 1,
      mod: nowSecs(),
      usn: 0,
      sortf: 0,
      did: 1,
      tmpls: [
        {
          name: 'Cloze',
          ord: 0,
          qfmt: '{{cloze:Text}}',
          afmt: '{{cloze:Text}}<br>{{Back}}',
          bqfmt: '',
          bafmt: '',
          did: null,
          bfont: '',
          bsize: 0,
        },
      ],
      flds: [
        { name: 'Text', ord: 0, sticky: false, rtl: false, font: 'Arial', size: 20, media: [] },
        { name: 'Back', ord: 1, sticky: false, rtl: false, font: 'Arial', size: 20, media: [] },
      ],
      css: '.card{font-family:arial;font-size:20px;text-align:center;color:black;background-color:white;}',
      latexPre: '',
      latexPost: '',
      latexsvg: false,
      req: [[0, 'any', [0]]],
    },
  };
}

function defaultDecksJson(deckName = 'Imported') {
  const ts = nowSecs();
  return {
    '1': {
      id: 1,
      mod: ts,
      name: deckName,
      usn: 0,
      lrnToday: [0, 0],
      revToday: [0, 0],
      newToday: [0, 0],
      timeToday: [0, 0],
      collapsed: false,
      browserCollapsed: false,
      desc: '',
      dyn: 0,
      conf: 1,
      extendNew: 0,
      extendRev: 0,
    },
  };
}

function initEmptyCollection(dbPath, deckName = 'Imported') {
  if (fs.existsSync(dbPath)) fs.unlinkSync(dbPath);

  const db = new Database(dbPath);
  db.pragma('foreign_keys = OFF');

  db.exec(`
    CREATE TABLE col (
      id integer PRIMARY KEY,
      crt integer NOT NULL,
      mod integer NOT NULL,
      scm integer NOT NULL,
      ver integer NOT NULL,
      dty integer NOT NULL,
      usn integer NOT NULL,
      ls integer NOT NULL,
      conf text NOT NULL,
      models text NOT NULL,
      decks text NOT NULL,
      dconf text NOT NULL,
      tags text NOT NULL
    );
    CREATE TABLE notes (
      id integer PRIMARY KEY,
      guid text NOT NULL,
      mid integer NOT NULL,
      mod integer NOT NULL,
      usn integer NOT NULL,
      tags text NOT NULL,
      flds text NOT NULL,
      sfld text NOT NULL,
      csum integer NOT NULL,
      flags integer NOT NULL,
      data text NOT NULL
    );
    CREATE TABLE cards (
      id integer PRIMARY KEY,
      nid integer NOT NULL,
      did integer NOT NULL,
      ord integer NOT NULL,
      mod integer NOT NULL,
      usn integer NOT NULL,
      type integer NOT NULL,
      queue integer NOT NULL,
      due integer NOT NULL,
      ivl integer NOT NULL,
      factor integer NOT NULL,
      reps integer NOT NULL,
      lapses integer NOT NULL,
      left integer NOT NULL,
      odue integer NOT NULL,
      odid integer NOT NULL,
      flags integer NOT NULL,
      data text NOT NULL
    );
    CREATE TABLE revlog (
      id integer PRIMARY KEY,
      cid integer NOT NULL,
      usn integer NOT NULL,
      ease integer NOT NULL,
      ivl integer NOT NULL,
      lastIvl integer NOT NULL,
      factor integer NOT NULL,
      time integer NOT NULL,
      type integer NOT NULL
    );
    CREATE TABLE graves (
      usn integer NOT NULL,
      oid integer NOT NULL,
      type integer NOT NULL
    );
  `);

  const ts = nowSecs();
  const conf = JSON.stringify({
    activeDecks: [1],
    curDeck: 1,
    newSpread: 0,
    collapseTime: 1200,
    addToCur: true,
  });
  const dconf = JSON.stringify({
    '1': {
      id: 1,
      name: 'Default',
      mod: ts,
      usn: 0,
      maxTaken: 60,
      autoplay: true,
      replayq: true,
      new: { bury: false, delays: [1, 10], initialFactor: 2500, ints: [1, 4, 0], order: 1, perDay: 20 },
      rev: { bury: false, ease4: 1.3, ivlFct: 1, maxIvl: 36500, minSpace: 1, perDay: 200 },
      lapse: { delays: [10], leechAction: 1, leechFails: 8, minInt: 1, mult: 0 },
    },
  });

  db.prepare(
    `INSERT INTO col (id,crt,mod,scm,ver,dty,usn,ls,conf,models,decks,dconf,tags)
     VALUES (1,?,?,?,11,0,0,0,?,?,?,?,?)`,
  ).run(
    ts,
    ts,
    ts,
    conf,
    JSON.stringify(basicModelJson()),
    JSON.stringify(defaultDecksJson(deckName)),
    dconf,
    '',
  );

  db.close();
}

async function readApkgRows(apkgPath, { strapi, importScheduling = false } = {}) {
  const zip = new AdmZip(apkgPath);
  const entries = zip.getEntries();
  const mediaMap = readMediaMap(zip);
  const filenameToIndex = filenameToMediaIndex(mediaMap);
  const dbEntry =
    entries.find((e) => e.entryName === 'collection.anki2') ??
    entries.find((e) => e.entryName.endsWith('collection.anki21'));

  if (!dbEntry) {
    throw new Error('Invalid .apkg: missing collection database');
  }

  const sqliteBuffer = extractCollectionSqlite(dbEntry.getData());
  const tmpDb = path.join(os.tmpdir(), `apkg-import-${Date.now()}.anki2`);
  fs.writeFileSync(tmpDb, sqliteBuffer);

  try {
    const db = new Database(tmpDb, { readonly: true });
    db.pragma('foreign_keys = OFF');

    const col = db.prepare('SELECT crt, models, decks FROM col LIMIT 1').get();
    const colCrt = col?.crt ?? nowSecs();
    const models = col?.models ? JSON.parse(col.models) : {};
    const decksJson = col?.decks ? JSON.parse(col.decks) : {};

    const deckNames = {};
    for (const deck of Object.values(decksJson)) {
      if (deck?.id != null) deckNames[deck.id] = deck.name ?? `Deck ${deck.id}`;
    }

    let deckTable = [];
    try {
      deckTable = db.prepare('SELECT id, name FROM decks').all();
    } catch (_) {
      // older schema without decks table
    }
    for (const deck of deckTable) {
      deckNames[deck.id] = deck.name;
    }

    const notes = db.prepare('SELECT id, mid, tags, flds FROM notes').all();
    const cards = db.prepare(
      'SELECT id, nid, did, ord, type, queue, due, ivl, factor, reps, lapses FROM cards',
    ).all();
    const cardsByNote = new Map();
    for (const card of cards) {
      if (!cardsByNote.has(card.nid)) cardsByNote.set(card.nid, []);
      cardsByNote.get(card.nid).push(card);
    }
    const deckByNote = new Map();
    for (const card of cards) {
      if (!deckByNote.has(card.nid)) {
        deckByNote.set(card.nid, card.did);
      }
    }

    const rows = [];
    for (const note of notes) {
      const model = models[String(note.mid)] ?? Object.values(models)[0];
      const fieldNames = (model?.flds ?? []).map((f) => f.name);
      const fieldValues = String(note.flds ?? '').split(FIELD_SEP);
      const fieldsMap = buildFieldsMap(model, fieldValues);

      const noteType = mapImportedModelToNoteType(model);
      const isCloze = noteType === 'cloze';
      let frontRaw = isCloze
        ? fieldsMap.Text ?? fieldsMap.text ?? fieldValues[0] ?? ''
        : fieldsMap.Front ?? fieldsMap.front ?? fieldValues[0] ?? '';
      let backRaw =
        fieldsMap.Back ?? fieldsMap.back ?? fieldsMap.Extra ?? fieldsMap.extra ?? fieldValues[1] ?? '';

      let noteMediaUrl = null;
      if (strapi && Object.keys(filenameToIndex).length) {
        for (const key of Object.keys(fieldsMap)) {
          const sound = await importSoundTags(strapi, fieldsMap[key], zip, mediaMap, filenameToIndex);
          fieldsMap[key] = sound.html;
          noteMediaUrl = noteMediaUrl ?? sound.mediaUrl;
        }
        const frontMedia = await importHtmlMedia(strapi, frontRaw, zip, filenameToIndex, mediaMap);
        const backMedia = await importHtmlMedia(strapi, backRaw, zip, filenameToIndex, mediaMap);
        frontRaw = frontMedia.html;
        backRaw = backMedia.html;
        noteMediaUrl = noteMediaUrl ?? frontMedia.mediaUrl ?? backMedia.mediaUrl;
      }

      const preserveHtml = strapi && Object.keys(filenameToIndex).length > 0;
      const front = preserveHtml && /<[a-z]/i.test(frontRaw)
        ? String(frontRaw).trim()
        : stripHtml(frontRaw);
      const back = preserveHtml && /<[a-z]/i.test(backRaw)
        ? String(backRaw).trim()
        : stripHtml(backRaw);

      if (!front && !back && !Object.values(fieldsMap).some((v) => String(v).trim())) continue;

      const deckId = deckByNote.get(note.id);
      const deckName = deckNames[deckId] ?? '';
      const tags = String(note.tags ?? '')
        .trim()
        .split(/\s+/)
        .filter(Boolean);

      const noteCards = cardsByNote.get(note.id) ?? [];
      const primaryCard = noteCards.sort((a, b) => (a.ord ?? 0) - (b.ord ?? 0))[0];
      const scheduling =
        importScheduling && primaryCard
          ? importedCardToReviewState(primaryCard, colCrt)
          : null;

      const importFields = isCloze
        ? { Text: fieldsMap.Text ?? fieldsMap.text ?? front, Back: fieldsMap.Back ?? fieldsMap.back ?? back }
        : { ...fieldsMap, Front: fieldsMap.Front ?? front, Back: fieldsMap.Back ?? back };

      rows.push({
        front,
        back,
        fields: importFields,
        deckName,
        tags,
        noteType,
        mediaUrl: noteMediaUrl,
        preserveHtml: preserveHtml && (/<[a-z]/i.test(front) || /<[a-z]/i.test(back)),
        scheduling,
        sourceModelName: model?.name ?? '',
      });
    }

    db.close();
    return rows;
  } finally {
    try {
      fs.unlinkSync(tmpDb);
    } catch (_) {
      // ignore
    }
  }
}

async function importApkgFile(strapi, userId, apkgPath, options = {}) {
  const rows = await readApkgRows(apkgPath, {
    strapi,
    importScheduling: options.importScheduling === true,
  });
  return importApkgRows(strapi, userId, rows, options);
}

async function importApkgRows(strapi, userId, rows, options = {}) {
  const { createNoteAndCards } = require('./flashcard-note-sync');
  const { findOrCreateImportDeck } = require('./flashcard-import');
  const deckCache = new Map();
  let imported = 0;
  let skipped = 0;
  const errors = [];

  for (const row of rows) {
    try {
      const deckId = await findOrCreateImportDeck(strapi, userId, row.deckName, {
        ...options,
        deckCache,
      });

      const noteType = row.noteType ?? 'basic';
      const fields = row.fields ?? { Front: row.front, Back: row.back ?? '' };
      const { cards } = await createNoteAndCards(strapi, userId, {
        deckId,
        noteType,
        fields,
        tags: row.tags ?? [],
        mediaUrl: row.mediaUrl ?? null,
        createReverse: noteType === 'basic_optional_reversed',
      });

      if (row.scheduling && cards.length) {
        for (const card of cards) {
          await applyImportedReviewState(strapi, userId, card.id, row.scheduling);
        }
      }

      imported += 1;
    } catch (err) {
      skipped += 1;
      if (errors.length < 20) errors.push(err.message ?? String(err));
    }
  }

  return { imported, skipped, errors };
}

async function buildApkgBuffer(strapi, userId, { deckId = null } = {}) {
  const deckWhere = { user: userId, isFiltered: false };
  const decks = await strapi.db.query('api::flashcard-deck.flashcard-deck').findMany({
    where: deckWhere,
    orderBy: { id: 'asc' },
  });

  const cardWhere = { user: userId };
  if (deckId) cardWhere.deck = deckId;

  const cards = await strapi.db.query('api::flashcard.flashcard').findMany({
    where: cardWhere,
    populate: ['deck', 'flashcardNote'],
    orderBy: { id: 'asc' },
  });

  const cardIds = cards.map((c) => c.id);
  const reviewRows =
    cardIds.length
      ? await strapi.db.query('api::card-review-state.card-review-state').findMany({
          where: { user: userId, flashcard: { $in: cardIds } },
        })
      : [];
  const reviewByCardId = new Map(
    reviewRows.map((r) => [r.flashcard?.id ?? r.flashcard, r]),
  );

  const exportDeckName =
    deckId != null
      ? decks.find((d) => d.id === deckId)?.name ?? 'Deck'
      : 'English App Export';

  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'apkg-export-'));
  const dbPath = path.join(tmpDir, 'collection.anki2');

  try {
    initEmptyCollection(dbPath, exportDeckName);
    const db = new Database(dbPath);
    db.pragma('foreign_keys = OFF');
    const colCrt = nowSecs();

    const deckIdMap = new Map();
    let nextExportDeckId = 1;
    const decksById = {};

    for (const deck of decks) {
      if (deckId != null && deck.id !== deckId) continue;
      deckIdMap.set(deck.id, nextExportDeckId);
      decksById[String(nextExportDeckId)] = {
        ...defaultDecksJson(deck.name)['1'],
        id: nextExportDeckId,
        name: deck.name,
        mod: nowSecs(),
      };
      nextExportDeckId += 1;
    }

    if (!deckIdMap.size) {
      deckIdMap.set(0, 1);
      decksById['1'] = defaultDecksJson(exportDeckName)['1'];
    }

    db.prepare('UPDATE col SET models = ?, decks = ?').run(
      JSON.stringify(basicModelJson()),
      JSON.stringify(decksById),
    );

    const insertNote = db.prepare(`
      INSERT INTO notes (id,guid,mid,mod,usn,tags,flds,sfld,csum,flags,data)
      VALUES (?,?,?,?,?,?,?,?,?,?,?)
    `);
    const insertCard = db.prepare(`
      INSERT INTO cards (id,nid,did,ord,mod,usn,type,queue,due,ivl,factor,reps,lapses,left,odue,odid,flags,data)
      VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
    `);

    let noteId = nowSecs() * 1000;
    let cardId = noteId;

    const noteIdByKey = new Map();
    const mediaMap = {};
    const refToFilename = new Map();
    let mediaIndex = 0;

    const registerMediaRef = (ref) => {
      if (!ref || ref.startsWith('data:') || refToFilename.has(ref)) return;
      const filename = filenameFromRef(ref, mediaIndex);
      refToFilename.set(ref, filename);
      mediaMap[String(mediaIndex)] = filename;
      mediaIndex += 1;
    };

    const exportHtml = (html) => {
      if (!html) return html;
      const re = new RegExp(MEDIA_REF_RE.source, 'gi');
      let match;
      while ((match = re.exec(html)) !== null) {
        registerMediaRef(match[1]);
      }
      return rewriteHtmlMediaRefs(html, refToFilename);
    };

    for (const card of cards) {
      const noteKey =
        card.flashcardNote?.id ??
        card.flashcard_note ??
        `legacy-${card.id}-${card.front}-${card.back}`;

      let exportNoteId = noteIdByKey.get(noteKey);
      if (exportNoteId == null) {
        const isCloze = card.cardType === 'cloze';
        const mid = isCloze ? CLOZE_MODEL_ID : BASIC_MODEL_ID;
        const front = exportHtml(card.front ?? '');
        const back = exportHtml(card.back ?? '');
        const clozeSource = exportHtml(card.clozeText || card.front || '');
        if (card.mediaUrl) registerMediaRef(card.mediaUrl);
        const flds = isCloze
          ? `${clozeSource}${FIELD_SEP}${back}`
          : `${front}${FIELD_SEP}${back}`;
        const tags = (card.tags ?? []).length ? ` ${card.tags.join(' ')} ` : '';
        const sfld = stripHtml(front).slice(0, 200);
        const csum = fieldChecksum(stripHtml(front));

        noteId += 1;
        exportNoteId = noteId;
        noteIdByKey.set(noteKey, exportNoteId);

        insertNote.run(
          exportNoteId,
          randomGuid(),
          mid,
          nowSecs(),
          0,
          tags,
          flds,
          sfld,
          csum,
          0,
          '',
        );
      }

      const sourceDeckId = card.deck?.id ?? card.deck ?? 0;
      const exportDeckId = deckIdMap.get(sourceDeckId) ?? 1;

      const reviewRow = reviewByCardId.get(card.id);
      const scheduling = reviewStateToImportedCard(reviewRow, colCrt);

      cardId += 1;
      insertCard.run(
        cardId,
        exportNoteId,
        exportDeckId,
        card.templateOrdinal ?? 0,
        nowSecs(),
        0,
        scheduling.type,
        scheduling.queue,
        scheduling.due,
        scheduling.ivl,
        scheduling.factor,
        scheduling.reps,
        scheduling.lapses,
        0,
        0,
        0,
        0,
        '',
      );
    }

    db.close();

    const zip = new AdmZip();
    zip.addFile('collection.anki2', fs.readFileSync(dbPath));
    for (const [ref, filename] of refToFilename.entries()) {
      const idx = Object.entries(mediaMap).find(([, name]) => name === filename)?.[0];
      if (idx == null) continue;
      const bytes = await loadMediaBytes(strapi, ref);
      if (bytes) zip.addFile(String(idx), bytes);
    }
    zip.addFile('media', Buffer.from(JSON.stringify(mediaMap)));
    return zip.toBuffer();
  } finally {
    try {
      fs.rmSync(tmpDir, { recursive: true, force: true });
    } catch (_) {
      // ignore
    }
  }
}

module.exports = {
  importApkgFile,
  importApkgRows,
  buildApkgBuffer,
  readApkgRows,
  extractCollectionSqlite,
  mapImportedModelToNoteType,
  importedCardToReviewState,
  reviewStateToImportedCard,
};
