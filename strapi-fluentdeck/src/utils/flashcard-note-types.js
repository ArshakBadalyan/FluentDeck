'use strict';

/**
 * Built-in Anki-style note types. HTML templates are applied in Phase 4H;
 * Phase 4B stores rendered front/back on each generated card.
 */

const NOTE_TYPE_IDS = [
  'basic',
  'basic_reversed',
  'basic_optional_reversed',
  'basic_type_answer',
  'cloze',
  'image_occlusion',
];

const NOTE_TYPES = {
  basic: {
    id: 'basic',
    name: 'Basic',
    fields: [
      { name: 'Front', required: true },
      { name: 'Back', required: true },
    ],
    cardTemplates: [{ name: 'Card 1', ordinal: 0 }],
  },
  basic_reversed: {
    id: 'basic_reversed',
    name: 'Basic (and reversed card)',
    fields: [
      { name: 'Front', required: true },
      { name: 'Back', required: true },
    ],
    cardTemplates: [
      { name: 'Card 1', ordinal: 0 },
      { name: 'Card 2', ordinal: 1, reversed: true },
    ],
  },
  basic_optional_reversed: {
    id: 'basic_optional_reversed',
    name: 'Basic (optional reversed card)',
    fields: [
      { name: 'Front', required: true },
      { name: 'Back', required: true },
    ],
    cardTemplates: [
      { name: 'Card 1', ordinal: 0 },
      { name: 'Card 2', ordinal: 1, reversed: true, optional: true },
    ],
  },
  basic_type_answer: {
    id: 'basic_type_answer',
    name: 'Basic (type in the answer)',
    fields: [
      { name: 'Front', required: true },
      { name: 'Back', required: true },
    ],
    cardTemplates: [{ name: 'Card 1', ordinal: 0, typeAnswer: true }],
  },
  cloze: {
    id: 'cloze',
    name: 'Cloze',
    fields: [{ name: 'Text', required: true }, { name: 'Back', required: false }],
    cardTemplates: [{ name: 'Cloze', ordinal: 0, dynamicCloze: true }],
  },
  image_occlusion: {
    id: 'image_occlusion',
    name: 'Image Occlusion',
    fields: [
      { name: 'Image', required: true },
      { name: 'Occlusion', required: true },
      { name: 'Header', required: false },
    ],
    cardTemplates: [{ name: 'IO Card', ordinal: 0, dynamicOcclusion: true }],
  },
};

function listNoteTypes() {
  return NOTE_TYPE_IDS.map((id) => {
    const t = NOTE_TYPES[id];
    return {
      id: t.id,
      name: t.name,
      fields: t.fields,
      cardTemplateNames: t.cardTemplates.map((c) => c.name),
      available: !t.deferred,
    };
  });
}

function getNoteType(id) {
  if (id == null || id === '') return null;
  const key = String(id).trim();
  if (NOTE_TYPES[key]) return NOTE_TYPES[key];
  const lower = key.toLowerCase();
  if (NOTE_TYPES[lower]) return NOTE_TYPES[lower];
  return Object.values(NOTE_TYPES).find((t) => t.name === key) ?? null;
}

function stripHtml(text) {
  return String(text ?? '')
    .replace(/<[^>]+>/g, '')
    .trim();
}

function extractClozeIndices(text) {
  const regex = /\{\{c(\d+)::/g;
  const indices = new Set();
  let m;
  while ((m = regex.exec(text)) !== null) {
    indices.add(parseInt(m[1], 10));
  }
  return [...indices].sort((a, b) => a - b);
}

function renderClozeFront(text, activeIndex) {
  return String(text).replace(
    /\{\{c(\d+)::([^}]+?)(?:::[^}]+)?\}\}/g,
    (match, n, content) => {
      if (parseInt(n, 10) === activeIndex) return '[...]';
      return content;
    },
  );
}

function renderClozeBack(text, activeIndex) {
  return String(text).replace(
    /\{\{c(\d+)::([^}]+?)(?:::[^}]+)?\}\}/g,
    (match, n, content) => {
      if (parseInt(n, 10) === activeIndex) return `<b>${content}</b>`;
      return content;
    },
  );
}

function parseOcclusionRegions(raw) {
  if (!raw) return [];
  let parsed = raw;
  if (typeof raw === 'string') {
    try {
      parsed = JSON.parse(raw);
    } catch (_) {
      return [];
    }
  }
  const regions = Array.isArray(parsed) ? parsed : parsed?.regions;
  if (!Array.isArray(regions)) return [];

  return regions
    .map((r, idx) => ({
      id: r.id ?? idx + 1,
      x: Number(r.x ?? 0),
      y: Number(r.y ?? 0),
      w: Number(r.w ?? 0),
      h: Number(r.h ?? 0),
      label: String(r.label ?? r.answer ?? '').trim(),
    }))
    .filter((r) => r.w > 0 && r.h > 0);
}

/**
 * @returns {Array<{ templateName, templateOrdinal, front, back, cardType, clozeText, clozeIndex, occlusionData }>}
 */
function generateCardsFromNote({ noteType, fields, createReverse = false }) {
  const type = getNoteType(noteType);
  if (!type) throw new Error(`Unknown note type: ${noteType}`);

  const f = fields ?? {};
  const front = stripHtml(f.Front ?? f.front ?? '');
  const back = stripHtml(f.Back ?? f.back ?? '');
  const text = String(f.Text ?? f.text ?? f.Front ?? f.front ?? '').trim();

  if (noteType === 'image_occlusion') {
    const imageUrl = String(f.Image ?? f.image ?? '').trim();
    const header = String(f.Header ?? f.header ?? '').trim();
    const regions = parseOcclusionRegions(f.Occlusion ?? f.occlusion ?? '[]');
    if (!imageUrl) throw new Error('Image Occlusion notes require an Image URL.');
    if (!regions.length) {
      throw new Error('Add at least one occlusion region on the image.');
    }

    return regions.map((region, i) => ({
      templateName: `Mask ${region.id}`,
      templateOrdinal: i,
      front: imageUrl,
      back: region.label || header || 'Reveal the hidden region',
      cardType: 'image_occlusion',
      clozeText: null,
      clozeIndex: i,
      occlusionData: {
        imageUrl,
        header,
        regions,
        activeIndex: i,
      },
    }));
  }

  if (noteType === 'cloze') {
    if (!text) throw new Error('Cloze notes require a Text field.');
    const indices = extractClozeIndices(text);
    if (!indices.length) {
      throw new Error('Cloze notes need at least one {{c1::answer}} deletion.');
    }
    return indices.map((clozeIndex, i) => ({
      templateName: `Cloze ${clozeIndex}`,
      templateOrdinal: i,
      front: renderClozeFront(text, clozeIndex),
      back: renderClozeBack(text, clozeIndex) || back || text,
      cardType: 'cloze',
      clozeText: renderClozeFront(text, clozeIndex),
      clozeIndex,
      occlusionData: null,
    }));
  }

  if (!front || !back) {
    throw new Error('Front and Back are required for this note type.');
  }

  const cards = [];
  for (const tmpl of type.cardTemplates) {
    if (tmpl.optional && !createReverse) continue;

    if (tmpl.reversed) {
      cards.push({
        templateName: tmpl.name,
        templateOrdinal: tmpl.ordinal,
        front: back,
        back: front,
        cardType: 'reversed',
        clozeText: null,
        clozeIndex: null,
        occlusionData: null,
      });
    } else if (tmpl.typeAnswer) {
      cards.push({
        templateName: tmpl.name,
        templateOrdinal: tmpl.ordinal,
        front: `${front}\n\nType your answer:`,
        back,
        cardType: 'type_answer',
        clozeText: null,
        clozeIndex: null,
        occlusionData: null,
      });
    } else {
      cards.push({
        templateName: tmpl.name,
        templateOrdinal: tmpl.ordinal,
        front,
        back,
        cardType: 'basic',
        clozeText: null,
        clozeIndex: null,
        occlusionData: null,
      });
    }
  }

  return cards;
}

function formatNote(row, cards = []) {
  return {
    id: row.id,
    noteType: row.noteType ?? row.note_type,
    fields: row.fields ?? {},
    tags: row.tags ?? [],
    marked: row.marked === true,
    createReverse: row.createReverse ?? row.create_reverse ?? false,
    deckId: row.deck?.id ?? row.deck ?? null,
    mediaUrl: row.mediaUrl ?? row.media_url ?? null,
    cards,
    createdAt: row.createdAt ?? row.created_at,
  };
}

module.exports = {
  NOTE_TYPE_IDS,
  NOTE_TYPES,
  listNoteTypes,
  getNoteType,
  generateCardsFromNote,
  formatNote,
  extractClozeIndices,
  parseOcclusionRegions,
};
