'use strict';

const { createNoteAndCards } = require('./flashcard-note-sync');
const { canCreateCustomDeck } = require('./flashcard-helpers');

function stripHtml(value) {
  return String(value ?? '')
    .replace(/<[^>]+>/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function parseTags(raw) {
  if (Array.isArray(raw)) return raw.map((t) => String(t).trim()).filter(Boolean);
  if (raw == null || raw === '') return [];
  return String(raw)
    .split(/[;,]/)
    .map((t) => t.trim())
    .filter(Boolean);
}

function parseCsvLine(line) {
  const cells = [];
  let current = '';
  let inQuotes = false;

  for (let i = 0; i < line.length; i += 1) {
    const ch = line[i];
    if (inQuotes) {
      if (ch === '"') {
        if (line[i + 1] === '"') {
          current += '"';
          i += 1;
        } else {
          inQuotes = false;
        }
      } else {
        current += ch;
      }
    } else if (ch === '"') {
      inQuotes = true;
    } else if (ch === ',') {
      cells.push(current);
      current = '';
    } else {
      current += ch;
    }
  }
  cells.push(current);
  return cells.map((c) => c.trim());
}

function normalizeHeader(name) {
  return String(name ?? '')
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]/g, '');
}

function parseCsvRows(csvText) {
  const text = String(csvText ?? '').replace(/^\uFEFF/, '');
  const lines = text.split(/\r?\n/).filter((l) => l.trim().length > 0);
  if (!lines.length) return [];

  const headerCells = parseCsvLine(lines[0]);
  const headerMap = {};
  headerCells.forEach((cell, idx) => {
    headerMap[normalizeHeader(cell)] = idx;
  });

  const frontIdx =
    headerMap.front ?? headerMap.question ?? headerMap.term ?? headerMap.word ?? 0;
  const backIdx =
    headerMap.back ?? headerMap.answer ?? headerMap.definition ?? headerMap.translation ?? 1;
  const deckIdx = headerMap.deck ?? headerMap.deckname;
  const tagsIdx = headerMap.tags ?? headerMap.tag;

  const rows = [];
  for (let i = 1; i < lines.length; i += 1) {
    const cells = parseCsvLine(lines[i]);
    const front = cells[frontIdx] ?? '';
    const back = cells[backIdx] ?? '';
    if (!front.trim() && !back.trim()) continue;

    rows.push({
      front: front.trim(),
      back: back.trim(),
      deckName: deckIdx != null ? (cells[deckIdx] ?? '').trim() : '',
      tags: tagsIdx != null ? parseTags(cells[tagsIdx]) : [],
      noteType: 'basic',
    });
  }
  return rows;
}

function parseTxtRows(txtText) {
  const lines = String(txtText ?? '').split(/\r?\n/);
  let deckName = '';
  let tags = [];
  let columns = ['Front', 'Back'];
  const rows = [];

  for (const rawLine of lines) {
    const line = rawLine.trimEnd();
    if (!line.trim()) continue;

    if (line.startsWith('#')) {
      const directive = line.slice(1).trim();
      const lower = directive.toLowerCase();
      if (lower.startsWith('deck:')) {
        deckName = directive.slice(5).trim();
      } else if (lower.startsWith('tags:')) {
        tags = directive
          .slice(5)
          .trim()
          .split(/\s+/)
          .filter(Boolean);
      } else if (lower.startsWith('columns:')) {
        columns = directive
          .slice(8)
          .split('\t')
          .map((c) => c.trim())
          .filter(Boolean);
      }
      continue;
    }

    const parts = line.split('\t');
    if (parts.length < 2) continue;

    const fieldMap = {};
    columns.forEach((name, idx) => {
      fieldMap[name] = parts[idx] ?? '';
    });

    const front = fieldMap.Front ?? fieldMap.front ?? parts[0] ?? '';
    const back = fieldMap.Back ?? fieldMap.back ?? parts[1] ?? '';
    if (!front.trim() && !back.trim()) continue;

    const isCloze = /\{\{c\d+::/.test(front) || /\{\{c\d+::/.test(back);
    rows.push({
      front: front.trim(),
      back: back.trim(),
      deckName,
      tags: [...tags],
      noteType: isCloze ? 'cloze' : 'basic',
    });
  }

  return rows;
}

function rowToNotePayload(row) {
  if (row.fields && typeof row.fields === 'object' && Object.keys(row.fields).length) {
    return {
      noteType: row.noteType ?? 'basic',
      fields: row.fields,
      tags: row.tags ?? [],
      createReverse: row.createReverse === true || row.noteType === 'basic_optional_reversed',
    };
  }
  if (row.noteType === 'cloze') {
    return {
      noteType: 'cloze',
      fields: { Text: row.front, Back: row.back || '' },
      tags: row.tags ?? [],
    };
  }
  return {
    noteType: 'basic',
    fields: { Front: row.front, Back: row.back || '' },
    tags: row.tags ?? [],
  };
}

async function findOrCreateImportDeck(strapi, userId, deckName, {
  defaultDeckId = null,
  createDecks = true,
  deckCache = new Map(),
} = {}) {
  const name = String(deckName ?? '').trim();
  if (!name && defaultDeckId) return defaultDeckId;

  if (!name) {
    const fallback = await strapi.db.query('api::flashcard-deck.flashcard-deck').findOne({
      where: { user: userId, isDefault: true },
      orderBy: { id: 'asc' },
    });
    if (fallback) return fallback.id;
    throw new Error('No target deck specified');
  }

  if (deckCache.has(name)) return deckCache.get(name);

  const existing = await strapi.db.query('api::flashcard-deck.flashcard-deck').findOne({
    where: { user: userId, name, isFiltered: false },
  });
  if (existing) {
    deckCache.set(name, existing.id);
    return existing.id;
  }

  if (!createDecks) {
    if (defaultDeckId) return defaultDeckId;
    throw new Error(`Deck "${name}" does not exist`);
  }

  const allowed = await canCreateCustomDeck(strapi, userId);
  if (!allowed.ok) {
    if (defaultDeckId) return defaultDeckId;
    throw new Error(allowed.reason);
  }

  const slug = `import_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
  const deck = await strapi.db.query('api::flashcard-deck.flashcard-deck').create({
    data: {
      name,
      deckSlug: slug,
      isDefault: false,
      description: 'Imported deck',
      user: userId,
    },
  });
  deckCache.set(name, deck.id);
  return deck.id;
}

async function importRows(strapi, userId, rows, options = {}) {
  const deckCache = new Map();
  let imported = 0;
  let skipped = 0;
  const errors = [];

  for (const row of rows) {
    try {
      const preserveHtml = options.preserveHtml === true || row.preserveHtml === true;
      const front = preserveHtml ? String(row.front ?? '').trim() : stripHtml(row.front);
      const back = preserveHtml ? String(row.back ?? '').trim() : stripHtml(row.back);
      if (!front && !back) {
        skipped += 1;
        continue;
      }

      const deckId = await findOrCreateImportDeck(strapi, userId, row.deckName, {
        ...options,
        deckCache,
      });

      const payload = rowToNotePayload({ ...row, front, back });
      await createNoteAndCards(strapi, userId, {
        deckId,
        ...payload,
        mediaUrl: row.mediaUrl ?? null,
      });
      imported += 1;
    } catch (err) {
      skipped += 1;
      if (errors.length < 20) {
        errors.push(err.message ?? String(err));
      }
    }
  }

  return { imported, skipped, errors };
}

async function importCsv(strapi, userId, csvText, options = {}) {
  const rows = parseCsvRows(csvText);
  return importRows(strapi, userId, rows, options);
}

async function importTxt(strapi, userId, txtText, options = {}) {
  const rows = parseTxtRows(txtText);
  return importRows(strapi, userId, rows, options);
}

module.exports = {
  parseCsvRows,
  parseTxtRows,
  importCsv,
  importTxt,
  importRows,
  findOrCreateImportDeck,
  stripHtml,
};
