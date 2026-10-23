'use strict';

const { normalizePracticeLanguage } = require('./practice-languages');

/** Multi-select filter values: an array, a comma-separated string, or a single
 *  value (older filtered decks). Empty and 'all' entries are dropped. */
function toValueList(raw) {
  const items = Array.isArray(raw) ? raw : raw == null ? [] : String(raw).split(',');
  const values = items.map((v) => String(v).trim()).filter((v) => v && v !== 'all');
  return [...new Set(values)];
}

/**
 * Shared card filter logic for browse API and filtered decks (Phase 4F).
 * `states`, `cefrLevels` and `flags` match a card when ANY selected value fits.
 */
function normalizeFilter(filter = {}) {
  const rawLang = filter.languageCode ?? filter.language;
  const cefrLevels = toValueList(filter.cefrLevel ?? filter.cefr).map((v) =>
    v.toLowerCase() === 'none' ? 'none' : v.toUpperCase(),
  );
  const flags = toValueList(filter.flag)
    .map((v) => (v === 'none' ? 0 : parseInt(v, 10)))
    .filter((v) => Number.isInteger(v) && v >= 0 && v <= 7);
  return {
    q: filter.q ? String(filter.q).trim().toLowerCase() : '',
    tag: filter.tag ? String(filter.tag).trim().toLowerCase() : '',
    states: toValueList(filter.state),
    languageCode:
      rawLang && String(rawLang).trim() && String(rawLang).trim() !== 'all'
        ? normalizePracticeLanguage(rawLang)
        : '',
    cefrLevels,
    marked:
      filter.marked === true || filter.marked === 'true' || filter.marked === '1'
        ? true
        : filter.marked === false || filter.marked === 'false' || filter.marked === '0'
          ? false
          : null,
    flags: [...new Set(flags)],
    sourceDeckIds: normalizeSourceDeckIds(filter),
  };
}

/** Filtered decks may pick several source decks (`sourceDeckIds`); older ones
 *  stored a single `sourceDeckId`. Empty = cards from any deck. */
function normalizeSourceDeckIds(filter = {}) {
  const raw = Array.isArray(filter.sourceDeckIds) ? [...filter.sourceDeckIds] : [];
  if (filter.sourceDeckId) raw.push(filter.sourceDeckId);
  const ids = raw.map((id) => parseInt(String(id), 10)).filter((id) => id > 0);
  return [...new Set(ids)];
}

function cardMatchesFilter(card, reviewState, filter, now = new Date()) {
  const f = normalizeFilter(filter);

  if (f.sourceDeckIds.length && !f.sourceDeckIds.includes(card.deckId)) return false;

  if (f.q) {
    const haystack = `${card.front} ${card.back}`.toLowerCase();
    if (!haystack.includes(f.q)) return false;
  }

  if (f.tag) {
    const tags = (card.tags ?? []).map((t) => String(t).toLowerCase());
    if (!tags.some((t) => t.includes(f.tag))) return false;
  }

  if (f.languageCode) {
    const cardLang = normalizePracticeLanguage(card.languageCode ?? 'en');
    if (cardLang !== f.languageCode) return false;
  }

  if (f.cefrLevels.length) {
    const cardLevel = card.cefrLevel ? String(card.cefrLevel).trim().toUpperCase() : 'none';
    if (!f.cefrLevels.includes(cardLevel || 'none')) return false;
  }

  if (f.marked != null && card.noteMarked !== f.marked) return false;
  if (f.flags.length && !f.flags.includes(card.flag ?? 0)) return false;

  const rs = reviewState;
  const st = rs?.state ?? 'new';
  const buried = rs?.buriedUntil && new Date(rs.buriedUntil).getTime() > now.getTime();

  if (f.states.length) {
    const matchesState = (state) => {
      if (state === 'suspended') return rs?.suspended === true;
      if (state === 'buried') return Boolean(buried);
      return st === state;
    };
    if (!f.states.some(matchesState)) return false;
  }

  return true;
}

module.exports = {
  toValueList,
  normalizeFilter,
  normalizeSourceDeckIds,
  cardMatchesFilter,
};
