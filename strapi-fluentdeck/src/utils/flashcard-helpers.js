'use strict';

const {
  initialReviewState,
  formatReviewState,
  applySm2Rating,
  isDue,
  isAvailableForReview,
  endOfLocalDay,
} = require('./sm2');
const { getFeatureConfig, isPremiumUser } = require('./app-feature-config');

async function getAuthenticatedUserId(ctx, strapi) {
  const token = await strapi.plugins['users-permissions'].services.jwt.getToken(
    ctx,
  );
  return token?.id ?? null;
}

function resolveCefrLevelFromTags(tags = []) {
  for (const t of tags) {
    const raw = String(t).trim().toLowerCase();
    if (raw.startsWith('cefr:')) {
      const level = raw.slice(5).trim().toUpperCase();
      if (level) return level;
    }
  }
  return null;
}

function formatCard(row, reviewRow, extras = {}) {
  const deck = row.deck ?? row.deck_id;
  const note = row.flashcardNote ?? row.flashcard_note;
  const userNote = row.userNote ?? row.user_note;
  const noteId =
    typeof note === 'object'
      ? note?.id
      : note ?? row.flashcard_note_id ?? row.noteId ?? null;
  const noteTags = typeof note === 'object' ? note?.tags ?? [] : [];
  const cefrFromTags = resolveCefrLevelFromTags([...(row.tags ?? []), ...noteTags]);
  const cefrLevel =
    cefrFromTags ??
    (typeof userNote === 'object' && userNote?.cefrLevel
      ? String(userNote.cefrLevel).trim().toUpperCase()
      : null);
  return {
    id: row.id,
    front: row.front,
    back: row.back,
    cardType: row.cardType ?? row.card_type ?? 'basic',
    clozeText: row.clozeText ?? row.cloze_text ?? null,
    clozeIndex: row.clozeIndex ?? row.cloze_index ?? null,
    templateName: row.templateName ?? row.template_name ?? 'Card 1',
    templateOrdinal: row.templateOrdinal ?? row.template_ordinal ?? 0,
    noteId,
    noteTypeId:
      typeof note === 'object' ? note?.noteType ?? note?.note_type ?? null : null,
    noteMarked: typeof note === 'object' ? note?.marked === true : false,
    siblingCardCount: extras.siblingCardCount ?? null,
    tags: row.tags ?? [],
    mediaUrl: row.mediaUrl ?? row.media_url ?? null,
    flag: row.flag ?? 0,
    languageCode: row.languageCode ?? row.language_code ?? 'en',
    cefrLevel,
    occlusionData: row.occlusionData ?? row.occlusion_data ?? null,
    deckId:
      typeof deck === 'object'
        ? deck?.id
        : deck ?? row.deck_id ?? row.deckId ?? null,
    deckName: typeof deck === 'object' ? deck?.name ?? null : null,
    reviewState: formatReviewState(reviewRow),
  };
}

function formatDeck(row, stats = {}) {
  return {
    id: row.id,
    name: row.name,
    deckSlug: row.deckSlug ?? row.deck_slug ?? '',
    isDefault: row.isDefault ?? row.is_default ?? false,
    isFiltered: row.isFiltered ?? row.is_filtered ?? false,
    filterQuery: row.filterQuery ?? row.filter_query ?? null,
    description: row.description ?? '',
    parentDeckId: row.parentDeck?.id ?? row.parent_deck?.id ?? row.parentDeck ?? row.parent_deck ?? null,
    deckOptions: row.deckOptions ?? row.deck_options ?? null,
    ...stats,
  };
}

async function ensureReviewState(strapi, userId, flashcardId) {
  const existing = await strapi.db.query('api::card-review-state.card-review-state').findOne({
    where: { flashcard: flashcardId, user: userId },
  });
  if (existing) return existing;

  const init = initialReviewState();
  return strapi.db.query('api::card-review-state.card-review-state').create({
    data: {
      ...init,
      flashcard: flashcardId,
      user: userId,
    },
  });
}

async function countCustomDecks(strapi, userId) {
  return strapi.db.query('api::flashcard-deck.flashcard-deck').count({
    where: { user: userId, isDefault: false },
  });
}

async function countNewCardsToday(strapi, userId) {
  const start = new Date();
  start.setHours(0, 0, 0, 0);
  return strapi.db.query('api::card-review-state.card-review-state').count({
    where: {
      user: userId,
      firstStudiedAt: { $gte: start },
    },
  });
}

async function deckStats(strapi, userId, deckId) {
  const cards = await strapi.db.query('api::flashcard.flashcard').findMany({
    where: { user: userId, deck: deckId },
  });
  const cardIds = cards.map((c) => c.id);
  if (!cardIds.length) {
    return { total: 0, newCount: 0, learningCount: 0, reviewDueCount: 0 };
  }

  const states = await strapi.db.query('api::card-review-state.card-review-state').findMany({
    where: { user: userId, flashcard: { $in: cardIds } },
    populate: ['flashcard'],
  });

  const now = new Date();
  let newCount = 0;
  let learningCount = 0;
  let reviewDueCount = 0;

  for (const card of cards) {
    const st = states.find((s) => {
      const fc = s.flashcard?.id ?? s.flashcard;
      return fc === card.id;
    });
    if (st && !isAvailableForReview(st, now)) {
      continue;
    }

    if (!st || st.state === 'new') {
      newCount += 1;
      continue;
    }
    if (st.state === 'learning' || st.state === 'relearning') {
      if (isDue(st, now)) learningCount += 1;
      continue;
    }
    if (st.state === 'review' && isDue(st, now)) {
      reviewDueCount += 1;
    }
  }

  return {
    total: cards.length,
    newCount,
    learningCount,
    reviewDueCount,
  };
}

async function canCreateCustomDeck(strapi, userId) {
  const premium = await isPremiumUser(strapi, userId);
  if (premium) return { ok: true };

  const config = await getFeatureConfig(strapi);
  const count = await countCustomDecks(strapi, userId);
  if (count >= config.freeMaxDecks) {
    return {
      ok: false,
      reason: `Free tier limit: ${config.freeMaxDecks} custom deck(s). Upgrade for unlimited decks.`,
    };
  }
  return { ok: true };
}

async function canIntroduceNewCard(strapi, userId) {
  const premium = await isPremiumUser(strapi, userId);
  if (premium) return { ok: true };

  const config = await getFeatureConfig(strapi);
  const studiedToday = await countNewCardsToday(strapi, userId);
  if (studiedToday >= config.freeMaxNewCardsPerDay) {
    return {
      ok: false,
      reason: `Free tier limit: ${config.freeMaxNewCardsPerDay} new cards per day.`,
    };
  }
  return { ok: true };
}

module.exports = {
  getAuthenticatedUserId,
  formatCard,
  formatDeck,
  ensureReviewState,
  countCustomDecks,
  deckStats,
  canCreateCustomDeck,
  canIntroduceNewCard,
  applySm2Rating,
  isDue,
  isAvailableForReview,
  endOfLocalDay,
  formatReviewState,
};
