'use strict';

/**
 * Shared card filter logic for browse API and filtered decks (Phase 4F).
 */
function normalizeFilter(filter = {}) {
  return {
    q: filter.q ? String(filter.q).trim().toLowerCase() : '',
    tag: filter.tag ? String(filter.tag).trim().toLowerCase() : '',
    state: filter.state ? String(filter.state).trim() : '',
    marked:
      filter.marked === true || filter.marked === 'true' || filter.marked === '1'
        ? true
        : filter.marked === false || filter.marked === 'false' || filter.marked === '0'
          ? false
          : null,
    flag:
      filter.flag != null && filter.flag !== ''
        ? filter.flag === 'none'
          ? 0
          : parseInt(String(filter.flag), 10)
        : null,
    sourceDeckId: filter.sourceDeckId ? parseInt(String(filter.sourceDeckId), 10) : null,
  };
}

function cardMatchesFilter(card, reviewState, filter, now = new Date()) {
  const f = normalizeFilter(filter);

  if (f.sourceDeckId && card.deckId !== f.sourceDeckId) return false;

  if (f.q) {
    const haystack = `${card.front} ${card.back}`.toLowerCase();
    if (!haystack.includes(f.q)) return false;
  }

  if (f.tag) {
    const tags = (card.tags ?? []).map((t) => String(t).toLowerCase());
    if (!tags.some((t) => t.includes(f.tag))) return false;
  }

  if (f.marked != null && card.noteMarked !== f.marked) return false;
  if (f.flag != null && (card.flag ?? 0) !== f.flag) return false;

  const rs = reviewState;
  const st = rs?.state ?? 'new';
  const buried = rs?.buriedUntil && new Date(rs.buriedUntil).getTime() > now.getTime();

  if (f.state) {
    if (f.state === 'suspended' && rs?.suspended !== true) return false;
    if (f.state === 'buried' && !buried) return false;
    if (f.state === 'relearning' && st !== 'relearning') return false;
    if (!['suspended', 'buried', 'relearning'].includes(f.state) && st !== f.state) {
      return false;
    }
  }

  return true;
}

module.exports = {
  normalizeFilter,
  cardMatchesFilter,
};
