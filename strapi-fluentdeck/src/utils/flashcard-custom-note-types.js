'use strict';

const CUSTOM_PREFIX = 'custom:';

function normalizeFields(raw) {
  if (!Array.isArray(raw)) return [];
  return raw
    .map((f) => ({
      name: String(f?.name ?? '').trim(),
      required: f?.required === true,
    }))
    .filter((f) => f.name.length > 0);
}

function normalizeCardTemplates(raw) {
  if (!Array.isArray(raw) || !raw.length) {
    return [
      {
        name: 'Card 1',
        ordinal: 0,
        qfmt: '{{Front}}',
        afmt: '{{FrontSide}}<hr id="answer">{{Back}}',
      },
    ];
  }
  return raw.map((t, i) => ({
    name: String(t?.name ?? `Card ${i + 1}`).trim(),
    ordinal: parseInt(String(t?.ordinal ?? i), 10) || i,
    qfmt: String(t?.qfmt ?? '{{Front}}'),
    afmt: String(t?.afmt ?? '{{Back}}'),
    reversed: t?.reversed === true,
    optional: t?.optional === true,
    typeAnswer: t?.typeAnswer === true,
  }));
}

function formatCustomNoteTypeForApi(row) {
  const fields = normalizeFields(row.fields);
  const cardTemplates = normalizeCardTemplates(row.cardTemplates);
  return {
    id: `${CUSTOM_PREFIX}${row.id}`,
    name: row.name,
    fields,
    cardTemplates,
    cardTemplateNames: cardTemplates.map((t) => t.name),
    css: row.css ?? '',
    themeId: row.themeId ?? 'classic',
    isCustom: true,
    available: true,
  };
}

function customTypeToGeneratorDef(row) {
  const fields = normalizeFields(row.fields);
  const cardTemplates = normalizeCardTemplates(row.cardTemplates);
  return {
    id: `${CUSTOM_PREFIX}${row.id}`,
    name: row.name,
    isCustom: true,
    fields,
    cardTemplates,
  };
}

function renderTemplateString(template, fieldMap, frontSideHtml = '') {
  let html = String(template ?? '');
  for (const [key, val] of Object.entries(fieldMap)) {
    const re = new RegExp(`\\{\\{${key.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\\}\\}`, 'gi');
    html = html.replace(re, String(val ?? ''));
  }
  html = html.replace(/\{\{FrontSide\}\}/gi, frontSideHtml ?? '');
  return html;
}

function generateCardsFromCustomType(typeDef, fields = {}) {
  const f = fields ?? {};
  const templates = typeDef.cardTemplates ?? [];
  if (!templates.length) {
    throw new Error('Custom note type needs at least one card template.');
  }

  let frontSide = '';
  const cards = [];

  for (let i = 0; i < templates.length; i += 1) {
    const tmpl = templates[i];
    if (tmpl.optional) continue;

    const front = renderTemplateString(tmpl.qfmt ?? '{{Front}}', f, frontSide);
    frontSide = front;
    const back = renderTemplateString(tmpl.afmt ?? '{{Back}}', f, front);

    if (tmpl.reversed) {
      cards.push({
        templateName: `${tmpl.name} (rev)`,
        templateOrdinal: tmpl.ordinal * 10 + 1,
        front: back,
        back: front,
        cardType: 'reversed',
        clozeText: null,
        clozeIndex: null,
        occlusionData: null,
      });
    } else {
      cards.push({
        templateName: tmpl.name,
        templateOrdinal: tmpl.ordinal,
        front: tmpl.typeAnswer ? `${front}\n\nType your answer:` : front,
        back,
        cardType: tmpl.typeAnswer ? 'type_answer' : 'basic',
        clozeText: null,
        clozeIndex: null,
        occlusionData: null,
      });
    }
  }

  if (!cards.length) throw new Error('No cards generated from custom templates.');
  return cards;
}

async function listCustomNoteTypes(strapi, userId) {
  const rows = await strapi.db.query('api::custom-flashcard-note-type.custom-flashcard-note-type').findMany({
    where: { user: userId },
    orderBy: { name: 'asc' },
  });
  return rows.map(formatCustomNoteTypeForApi);
}

async function resolveCustomNoteType(strapi, userId, noteTypeId) {
  if (!noteTypeId?.startsWith(CUSTOM_PREFIX)) return null;
  const dbId = parseInt(noteTypeId.slice(CUSTOM_PREFIX.length), 10);
  if (!dbId) return null;

  const row = await strapi.db.query('api::custom-flashcard-note-type.custom-flashcard-note-type').findOne({
    where: { id: dbId, user: userId },
  });
  if (!row) return null;
  return customTypeToGeneratorDef(row);
}

async function createCustomNoteType(strapi, userId, payload) {
  const name = String(payload?.name ?? '').trim();
  if (!name) throw Object.assign(new Error('Name is required'), { status: 400 });

  const fields = normalizeFields(payload?.fields);
  const cardTemplates = normalizeCardTemplates(payload?.cardTemplates);
  if (!fields.length) throw Object.assign(new Error('At least one field is required'), { status: 400 });

  const row = await strapi.db.query('api::custom-flashcard-note-type.custom-flashcard-note-type').create({
    data: {
      name,
      fields,
      cardTemplates,
      css: payload?.css ?? '',
      themeId: String(payload?.themeId ?? 'classic'),
      user: userId,
    },
  });
  return formatCustomNoteTypeForApi(row);
}

async function updateCustomNoteType(strapi, userId, id, payload) {
  const existing = await strapi.db.query('api::custom-flashcard-note-type.custom-flashcard-note-type').findOne({
    where: { id, user: userId },
  });
  if (!existing) throw Object.assign(new Error('Custom note type not found'), { status: 404 });

  const data = {};
  if (payload?.name !== undefined) {
    const name = String(payload.name).trim();
    if (!name) throw Object.assign(new Error('Name cannot be empty'), { status: 400 });
    data.name = name;
  }
  if (payload?.fields !== undefined) {
    const fields = normalizeFields(payload.fields);
    if (!fields.length) throw Object.assign(new Error('At least one field is required'), { status: 400 });
    data.fields = fields;
  }
  if (payload?.cardTemplates !== undefined) {
    data.cardTemplates = normalizeCardTemplates(payload.cardTemplates);
  }
  if (payload?.css !== undefined) data.css = String(payload.css ?? '');
  if (payload?.themeId !== undefined) data.themeId = String(payload.themeId ?? 'classic');

  const row = await strapi.db.query('api::custom-flashcard-note-type.custom-flashcard-note-type').update({
    where: { id },
    data,
  });
  return formatCustomNoteTypeForApi(row);
}

async function deleteCustomNoteType(strapi, userId, id) {
  const existing = await strapi.db.query('api::custom-flashcard-note-type.custom-flashcard-note-type').findOne({
    where: { id, user: userId },
  });
  if (!existing) throw Object.assign(new Error('Custom note type not found'), { status: 404 });

  await strapi.db.query('api::custom-flashcard-note-type.custom-flashcard-note-type').delete({
    where: { id },
  });
  return { ok: true };
}

module.exports = {
  CUSTOM_PREFIX,
  normalizeFields,
  normalizeCardTemplates,
  formatCustomNoteTypeForApi,
  customTypeToGeneratorDef,
  generateCardsFromCustomType,
  listCustomNoteTypes,
  resolveCustomNoteType,
  createCustomNoteType,
  updateCustomNoteType,
  deleteCustomNoteType,
};
