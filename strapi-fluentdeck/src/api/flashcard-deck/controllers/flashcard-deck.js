'use strict';

const { createCoreController } = require('@strapi/strapi').factories;
const {
  getAuthenticatedUserId,
  formatCard,
  formatDeck,
  ensureReviewState,
  deckStats,
  canCreateCustomDeck,
  canIntroduceNewCard,
  applySm2Rating,
  isDue,
  isAvailableForReview,
  endOfLocalDay,
} = require('../../../utils/flashcard-helpers');
const { getFeatureConfig, isPremiumUser } = require('../../../utils/app-feature-config');
const { createNoteAndCards, deleteNoteAndCards, updateNoteAndCards, repairCardsDeckFromNotes, ensureCardHasNote } = require('../../../utils/flashcard-note-sync');
const { formatNote } = require('../../../utils/flashcard-note-types');
const { recordFlashcardReviewStreak,
  getFlashcardReviewStreak,
} = require('../../../utils/flashcard-streak');
const { recordReviewLog } = require('../../../utils/flashcard-review-log');
const { buildDetailedStats, listReviewLog } = require('../../../utils/flashcard-detailed-stats');
const { filteredDeckStats, filteredReviewQueue } = require('../../../utils/flashcard-filtered-deck');
const { cardMatchesFilter } = require('../../../utils/flashcard-browse-filter');
const { importCsv, importTxt } = require('../../../utils/flashcard-import');
const { importApkgFile, buildApkgBuffer } = require('../../../utils/flashcard-apkg');
const { pullSyncData, getSyncMeta, setSyncMeta } = require('../../../utils/flashcard-cloud-sync');
const {
  runFullCheck,
  checkDatabaseIntegrity,
  checkMedia,
  findEmptyCards,
  deleteEmptyCards,
} = require('../../../utils/flashcard-maintenance');
const {
  getCardInfo: fetchCardInfo,
  setCardDue: applySetCardDue,
  resetCardProgress: applyResetCardProgress,
  gradeCardNow: applyGradeCardNow,
  repositionCard: applyRepositionCard,
  exportCardJson: buildExportCardJson,
} = require('../../../utils/flashcard-card-actions');
const { importJsonBackup } = require('../../../utils/flashcard-import-json');
const { uploadFlashcardMedia, absoluteMediaUrl } = require('../../../utils/flashcard-media');
const {
  reviewStateSnapshot,
  maybeAutoSuspendLeech,
  burySiblingCards,
  unburyCard,
  undoLastReview,
  normalizeDeckOptions,
} = require('../../../utils/flashcard-review-actions');
const {
  isDueWithLearnAhead,
  orderReviewQueue,
  parseNewCardOrder,
} = require('../../../utils/flashcard-review-queue');
const fs = require('fs');

module.exports = createCoreController(
  'api::flashcard-deck.flashcard-deck',
  ({ strapi }) => ({
    async listDecks(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const { ensureUserDefaultDecks } = require('../../../utils/flashcard-auto-create');
      await ensureUserDefaultDecks(strapi, userId);

      const decks = await strapi.db.query('api::flashcard-deck.flashcard-deck').findMany({
        where: { user: userId },
        populate: ['parentDeck'],
        orderBy: [{ isDefault: 'desc' }, { name: 'asc' }],
      });

      const data = [];
      for (const deck of decks) {
        const stats =
          deck.isFiltered ?? deck.is_filtered
            ? await filteredDeckStats(strapi, userId, deck.filterQuery ?? deck.filter_query ?? {})
            : await deckStats(strapi, userId, deck.id);
        data.push(formatDeck(deck, stats));
      }

      ctx.body = { data };
    },

    async deckDetail(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const deckId = parseInt(String(ctx.params.id), 10);
      const deck = await strapi.db.query('api::flashcard-deck.flashcard-deck').findOne({
        where: { id: deckId, user: userId },
      });
      if (!deck) return ctx.notFound('Deck not found');

      await repairCardsDeckFromNotes(strapi, userId, deckId);

      const cards = await strapi.db.query('api::flashcard.flashcard').findMany({
        where: { deck: deckId, user: userId },
        populate: ['deck', 'flashcardNote'],
        orderBy: { id: 'desc' },
      });

      const cardIds = cards.map((c) => c.id);
      const states =
        cardIds.length
          ? await strapi.db.query('api::card-review-state.card-review-state').findMany({
              where: { user: userId, flashcard: { $in: cardIds } },
            })
          : [];

      const stats = await deckStats(strapi, userId, deckId);

      ctx.body = {
        deck: formatDeck(deck, stats),
        cards: cards.map((card) => {
          const st = states.find((s) => (s.flashcard?.id ?? s.flashcard) === card.id);
          return formatCard(card, st);
        }),
      };
    },

    async createDeck(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const { name, description, parentDeckId } = ctx.request.body ?? {};
      if (!name || !String(name).trim()) {
        return ctx.badRequest('name is required');
      }

      const allowed = await canCreateCustomDeck(strapi, userId);
      if (!allowed.ok) return ctx.forbidden(allowed.reason);

      const slug = `custom_${Date.now()}`;
      const deck = await strapi.db.query('api::flashcard-deck.flashcard-deck').create({
        data: {
          name: String(name).trim(),
          deckSlug: slug,
          isDefault: false,
          description: description ?? '',
          user: userId,
          ...(parentDeckId ? { parentDeck: parentDeckId } : {}),
        },
      });

      ctx.body = { ok: true, deck: formatDeck(deck, { total: 0, newCount: 0, learningCount: 0, reviewDueCount: 0 }) };
    },

    async updateDeck(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const deckId = parseInt(String(ctx.params.id), 10);
      const deck = await strapi.db.query('api::flashcard-deck.flashcard-deck').findOne({
        where: { id: deckId, user: userId },
        populate: ['parentDeck'],
      });
      if (!deck) return ctx.notFound('Deck not found');

      const { name, description, parentDeckId, deckOptions } = ctx.request.body ?? {};
      const data = {};

      if (description !== undefined) data.description = String(description);
      if (name != null && !deck.isDefault) {
        const trimmed = String(name).trim();
        if (!trimmed) return ctx.badRequest('name cannot be empty');
        data.name = trimmed;
      }
      if (parentDeckId !== undefined && !deck.isDefault && !(deck.isFiltered ?? deck.is_filtered)) {
        if (parentDeckId === null || parentDeckId === '') {
          data.parentDeck = null;
        } else {
          const parentId = parseInt(String(parentDeckId), 10);
          if (parentId === deckId) return ctx.badRequest('Deck cannot be its own parent');
          data.parentDeck = parentId;
        }
      }
      if (deckOptions !== undefined && !deck.isDefault) {
        const { normalizeDeckOptions } = require('../../../utils/flashcard-review-actions');
        data.deckOptions = normalizeDeckOptions(deckOptions);
      }

      const updated = await strapi.db.query('api::flashcard-deck.flashcard-deck').update({
        where: { id: deckId },
        data,
        populate: ['parentDeck'],
      });

      const stats =
        updated.isFiltered ?? updated.is_filtered
          ? await filteredDeckStats(strapi, userId, updated.filterQuery ?? updated.filter_query ?? {})
          : await deckStats(strapi, userId, deckId);

      ctx.body = { ok: true, deck: formatDeck(updated, stats) };
    },

    async createFilteredDeck(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const { name, filterQuery } = ctx.request.body ?? {};
      if (!name || !String(name).trim()) {
        return ctx.badRequest('name is required');
      }
      if (!filterQuery || typeof filterQuery !== 'object') {
        return ctx.badRequest('filterQuery object is required');
      }

      const allowed = await canCreateCustomDeck(strapi, userId);
      if (!allowed.ok) return ctx.forbidden(allowed.reason);

      const deck = await strapi.db.query('api::flashcard-deck.flashcard-deck').create({
        data: {
          name: String(name).trim(),
          deckSlug: `filtered_${Date.now()}`,
          isDefault: false,
          isFiltered: true,
          filterQuery,
          description: 'Filtered deck',
          user: userId,
        },
      });

      const stats = await filteredDeckStats(strapi, userId, filterQuery);
      ctx.body = { ok: true, deck: formatDeck(deck, stats) };
    },

    async deleteDeck(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const deckId = parseInt(String(ctx.params.id), 10);
      const deck = await strapi.db.query('api::flashcard-deck.flashcard-deck').findOne({
        where: { id: deckId, user: userId },
      });
      if (!deck) return ctx.notFound('Deck not found');

      if (deck.isDefault) {
        return ctx.forbidden('Default decks (Saved words, From speaking) cannot be deleted.');
      }

      if (deck.isFiltered ?? deck.is_filtered) {
        await strapi.db.query('api::flashcard-deck.flashcard-deck').delete({ where: { id: deckId } });
        ctx.body = { ok: true };
        return;
      }

      const notes = await strapi.db.query('api::flashcard-note.flashcard-note').findMany({
        where: { deck: deckId, user: userId },
      });

      for (const note of notes) {
        await deleteNoteAndCards(strapi, userId, note.id);
      }

      const orphanCards = await strapi.db.query('api::flashcard.flashcard').findMany({
        where: { deck: deckId, user: userId },
      });

      for (const card of orphanCards) {
        const review = await strapi.db.query('api::card-review-state.card-review-state').findOne({
          where: { flashcard: card.id, user: userId },
        });
        if (review) {
          await strapi.db.query('api::card-review-state.card-review-state').delete({
            where: { id: review.id },
          });
        }
        await strapi.db.query('api::flashcard.flashcard').delete({ where: { id: card.id } });
      }

      await strapi.db.query('api::flashcard-deck.flashcard-deck').delete({ where: { id: deckId } });
      ctx.body = { ok: true };
    },

    async createCard(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const {
        deckId,
        front,
        back,
        noteType,
        cardType = 'basic',
        clozeText,
        fields,
        tags,
        mediaUrl,
        createReverse,
      } = ctx.request.body ?? {};

      if (!deckId) return ctx.badRequest('deckId is required');

      const resolvedNoteType =
        noteType ??
        (cardType === 'cloze' ? 'cloze' : 'basic');

      const resolvedFields =
        fields ??
        (resolvedNoteType === 'cloze'
            ? { Text: clozeText || front, Back: back }
            : { Front: front, Back: back });

      if (!resolvedFields.Front && !resolvedFields.Text && !front) {
        return ctx.badRequest('front or fields are required');
      }
      if (resolvedNoteType !== 'cloze' && !resolvedFields.Back && !back) {
        return ctx.badRequest('back is required');
      }

      try {
        const result = await createNoteAndCards(strapi, userId, {
          deckId,
          noteType: resolvedNoteType,
          fields: resolvedFields,
          tags,
          createReverse,
          mediaUrl,
        });
        ctx.body = {
          ok: true,
          note: result.note,
          card: result.cards[0] ?? null,
          cards: result.cards,
        };
      } catch (e) {
        return ctx.badRequest(e.message);
      }
    },

    async updateCard(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const cardId = parseInt(String(ctx.params.cardId), 10);
      const existing = await strapi.db.query('api::flashcard.flashcard').findOne({
        where: { id: cardId, user: userId },
      });
      if (!existing) return ctx.notFound('Card not found');

      const { front, back, cardType, clozeText, tags, mediaUrl } = ctx.request.body ?? {};
      const noteId = existing.flashcardNote?.id ?? existing.flashcardNote ?? existing.flashcard_note;

      if (noteId) {
        const note = await strapi.db.query('api::flashcard-note.flashcard-note').findOne({
          where: { id: noteId, user: userId },
        });
        if (note) {
          const fields = { ...(note.fields ?? {}) };
          if (front != null) {
            if (note.noteType === 'cloze') fields.Text = String(front).trim();
            else fields.Front = String(front).trim();
          }
          if (back != null) fields.Back = String(back).trim();
          if (clozeText !== undefined && note.noteType === 'cloze') {
            fields.Text = String(clozeText).trim();
          }

          const payload = { fields };
          if (tags != null) payload.tags = Array.isArray(tags) ? tags : [];
          if (mediaUrl !== undefined) payload.mediaUrl = mediaUrl;

          try {
            const result = await updateNoteAndCards(strapi, userId, noteId, payload);
            const card = result.cards.find((c) => c.id === cardId) ?? result.cards[0];
            ctx.body = { ok: true, card, note: result.note, cards: result.cards };
            return;
          } catch (e) {
            return ctx.badRequest(e.message);
          }
        }
      }

      const data = {};
      if (front != null) data.front = String(front).trim();
      if (back != null) data.back = String(back).trim();
      if (cardType != null) data.cardType = cardType === 'cloze' ? 'cloze' : 'basic';
      if (clozeText !== undefined) data.clozeText = clozeText;
      if (tags != null) data.tags = Array.isArray(tags) ? tags : [];
      if (mediaUrl !== undefined) data.mediaUrl = mediaUrl;

      const updated = await strapi.db.query('api::flashcard.flashcard').update({
        where: { id: cardId },
        data,
      });

      const review = await ensureReviewState(strapi, userId, cardId);
      ctx.body = { ok: true, card: formatCard(updated, review) };
    },

    async deleteCard(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const cardId = parseInt(String(ctx.params.cardId), 10);
      const existing = await strapi.db.query('api::flashcard.flashcard').findOne({
        where: { id: cardId, user: userId },
        populate: ['flashcardNote'],
      });
      if (!existing) return ctx.notFound('Card not found');

      const noteId = existing.flashcardNote?.id ?? existing.flashcardNote ?? existing.flashcard_note;
      if (noteId) {
        const siblings = await strapi.db.query('api::flashcard.flashcard').findMany({
          where: { flashcardNote: noteId, user: userId },
        });
        if (siblings.length <= 1) {
          try {
            ctx.body = await deleteNoteAndCards(strapi, userId, noteId);
            return;
          } catch (e) {
            const isMissingNote =
              e.status === 404 || String(e.message ?? '').includes('Note not found');
            if (!isMissingNote) {
              return ctx.notFound(e.message);
            }
          }
        }
      }

      const review = await strapi.db.query('api::card-review-state.card-review-state').findOne({
        where: { flashcard: cardId, user: userId },
      });
      if (review) {
        await strapi.db.query('api::card-review-state.card-review-state').delete({
          where: { id: review.id },
        });
      }

      await strapi.db.query('api::flashcard.flashcard').delete({ where: { id: cardId } });
      ctx.body = { ok: true };
    },

    async reviewQueue(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const deckId = ctx.query.deckId ? parseInt(String(ctx.query.deckId), 10) : null;
      const limit = Math.min(50, Math.max(1, parseInt(String(ctx.query.limit ?? '20'), 10) || 20));
      const learnAheadMinutes = Math.min(
        120,
        Math.max(0, parseInt(String(ctx.query.learnAheadMinutes ?? '0'), 10) || 0),
      );
      const newCardOrder = parseNewCardOrder(ctx.query.newCardOrder);

      if (deckId) {
        const deck = await strapi.db.query('api::flashcard-deck.flashcard-deck').findOne({
          where: { id: deckId, user: userId },
        });
        if (deck && (deck.isFiltered ?? deck.is_filtered)) {
          const queue = await filteredReviewQueue(
            strapi,
            userId,
            deck.filterQuery ?? deck.filter_query ?? {},
            limit,
          );
          ctx.body = {
            queue,
            counts: {
              due: queue.length,
              newAvailable: queue.length,
              newIncluded: queue.length,
            },
          };
          return;
        }
      }

      const where = { user: userId };
      if (deckId) where.deck = deckId;

      const cards = await strapi.db.query('api::flashcard.flashcard').findMany({
        where,
        populate: ['deck', 'flashcardNote'],
      });

      const now = new Date();
      const due = [];
      const newCards = [];

      for (const card of cards) {
        let review = await strapi.db.query('api::card-review-state.card-review-state').findOne({
          where: { flashcard: card.id, user: userId },
        });
        if (!review) {
          review = await ensureReviewState(strapi, userId, card.id);
        }

        if (!isAvailableForReview(review, now)) continue;

        if (review.state === 'new') {
          newCards.push(formatCard(card, review));
        } else if (
          isDue(review, now) ||
          isDueWithLearnAhead(review, now, learnAheadMinutes)
        ) {
          due.push(formatCard(card, review));
        }
      }

      let deckOpts = null;
      if (deckId) {
        const deckRow = await strapi.db.query('api::flashcard-deck.flashcard-deck').findOne({
          where: { id: deckId, user: userId },
        });
        deckOpts = normalizeDeckOptions(deckRow?.deckOptions ?? deckRow?.deck_options);
      }

      const config = await getFeatureConfig(strapi);
      const premium = await isPremiumUser(strapi, userId);
      const maxReviews = deckOpts?.maxReviewsPerDay ?? limit;
      const reviewCap = Math.min(limit, maxReviews);
      const newCap = deckOpts?.newCardsPerDay ?? reviewCap;
      const newLimit = premium
        ? Math.min(reviewCap, newCap)
        : Math.min(reviewCap, newCap, config.freeMaxNewCardsPerDay);
      const selectedNew = newCards.slice(0, newLimit);
      const queue = orderReviewQueue(
        [...due, ...selectedNew].slice(0, reviewCap),
        newCardOrder,
      );

      ctx.body = {
        queue,
        counts: {
          due: due.length,
          newAvailable: newCards.length,
          newIncluded: selectedNew.length,
        },
      };
    },

    async submitReview(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const { flashcardId, rating, durationMs } = ctx.request.body ?? {};
      const cardId = parseInt(String(flashcardId), 10);
      const validRatings = ['again', 'hard', 'good', 'easy'];
      if (!cardId || !validRatings.includes(rating)) {
        return ctx.badRequest('flashcardId and rating (again|hard|good|easy) are required');
      }

      const card = await strapi.db.query('api::flashcard.flashcard').findOne({
        where: { id: cardId, user: userId },
        populate: ['deck'],
      });
      if (!card) return ctx.notFound('Card not found');

      let review = await strapi.db.query('api::card-review-state.card-review-state').findOne({
        where: { flashcard: cardId, user: userId },
      });
      if (!review) {
        review = await ensureReviewState(strapi, userId, cardId);
      }

      const wasNew = review.state === 'new';
      if (wasNew && rating !== 'again') {
        const allowed = await canIntroduceNewCard(strapi, userId);
        if (!allowed.ok) return ctx.forbidden(allowed.reason);
      }

      const now = new Date();
      const intervalBefore = review.intervalDays ?? review.interval_days ?? 0;
      const stateBefore = review.state ?? 'new';
      const undoSnapshot = reviewStateSnapshot(review);

      const deckRow = card.deck?.id
        ? await strapi.db.query('api::flashcard-deck.flashcard-deck').findOne({
            where: { id: card.deck?.id ?? card.deck, user: userId },
          })
        : null;
      const deckOpts = normalizeDeckOptions(deckRow?.deckOptions ?? deckRow?.deck_options);

      const next = applySm2Rating(review, rating, now, deckOpts);
      if (wasNew && !next.firstStudiedAt) {
        next.firstStudiedAt = now;
      }

      let updated = await strapi.db.query('api::card-review-state.card-review-state').update({
        where: { id: review.id },
        data: next,
      });

      updated = await maybeAutoSuspendLeech(strapi, userId, cardId, updated, deckOpts.leechThreshold);

      const streak = await recordFlashcardReviewStreak(strapi, userId, now);

      await recordReviewLog(strapi, userId, {
        flashcardId: cardId,
        deckId: card.deck?.id ?? card.deck,
        rating,
        durationMs,
        intervalBefore,
        intervalAfter: updated.intervalDays ?? next.intervalDays ?? 0,
        stateBefore,
        stateAfter: updated.state ?? next.state,
        reviewedAt: now,
        undoSnapshot,
      });

      try {
        const user = await strapi.db.query('plugin::users-permissions.user').findOne({
          where: { id: userId },
          select: ['practice_language'],
        });
        const { recordDeckReviewActivity } = require('../../../utils/language-level-analytics');
        await recordDeckReviewActivity(strapi, userId, {
          languageCode: user?.practice_language ?? 'en',
        });
      } catch (analyticsErr) {
        strapi.log.warn('[submitReview] language analytics failed', analyticsErr);
      }

      ctx.body = {
        ok: true,
        card: formatCard(card, updated),
        reviewState: formatCard(card, updated).reviewState,
        reviewStreakDays: streak,
        leechSuspended: updated.suspended === true && undoSnapshot.suspended !== true,
      };
    },

    async detailedStats(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const deckId = ctx.query.deckId ? parseInt(String(ctx.query.deckId), 10) : null;
      const range = ctx.query.range === 'all' ? 'all' : '12m';

      ctx.body = await buildDetailedStats(strapi, userId, { deckId, range });
    },

    async reviewLog(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const deckId = ctx.query.deckId ? parseInt(String(ctx.query.deckId), 10) : null;
      const limit = parseInt(String(ctx.query.limit ?? '50'), 10) || 50;
      const offset = parseInt(String(ctx.query.offset ?? '0'), 10) || 0;

      ctx.body = await listReviewLog(strapi, userId, { deckId, limit, offset });
    },

    async studyStats(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const decks = await strapi.db.query('api::flashcard-deck.flashcard-deck').findMany({
        where: { user: userId },
      });

      let totalDue = 0;
      let totalNew = 0;
      let totalCards = 0;

      for (const deck of decks) {
        const stats =
          deck.isFiltered ?? deck.is_filtered
            ? await filteredDeckStats(strapi, userId, deck.filterQuery ?? deck.filter_query ?? {})
            : await deckStats(strapi, userId, deck.id);
        totalDue += stats.learningCount + stats.reviewDueCount;
        totalNew += stats.newCount;
        if (!(deck.isFiltered ?? deck.is_filtered)) {
          totalCards += stats.total;
        }
      }

      const config = await getFeatureConfig(strapi);
      const premium = await isPremiumUser(strapi, userId);
      const streak = await getFlashcardReviewStreak(strapi, userId);
      const detailed = await buildDetailedStats(strapi, userId, { range: '12m' });

      ctx.body = {
        totalCards,
        dueNow: totalDue,
        newCards: totalNew,
        newCardsDailyLimit: premium ? null : config.freeMaxNewCardsPerDay,
        reviewStreakDays: streak,
        isPremium: premium,
        todayReviews: detailed.today?.reviews ?? 0,
        todayDurationMs: detailed.today?.durationMs ?? 0,
      };
    },

    async browseCards(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const { q, deckId, tag, state: stateFilter, marked, flag, languageCode, language } = ctx.query ?? {};
      const where = { user: userId };
      if (deckId) {
        const parsedDeckId = parseInt(String(deckId), 10);
        where.deck = parsedDeckId;
        await repairCardsDeckFromNotes(strapi, userId, parsedDeckId);
      }

      let cards = await strapi.db.query('api::flashcard.flashcard').findMany({
        where,
        populate: ['deck', 'flashcardNote'],
        orderBy: { id: 'desc' },
      });

      const cardIds = cards.map((c) => c.id);
      const reviews =
        cardIds.length
          ? await strapi.db.query('api::card-review-state.card-review-state').findMany({
              where: { user: userId, flashcard: { $in: cardIds } },
            })
          : [];

      const filter = {
        q,
        tag,
        state: stateFilter,
        marked: marked === 'true' || marked === '1' ? true : marked === 'false' ? false : null,
        flag: flag != null && flag !== '' ? (flag === 'none' ? 0 : parseInt(String(flag), 10)) : null,
        languageCode: languageCode ?? language,
      };

      const now = new Date();

      const noteSiblingCounts = {};
      for (const card of cards) {
        const nid = card.flashcardNote?.id ?? card.flashcard_note;
        if (nid) noteSiblingCounts[nid] = (noteSiblingCounts[nid] ?? 0) + 1;
      }

      const data = cards
        .map((card) => {
          const st = reviews.find((r) => (r.flashcard?.id ?? r.flashcard) === card.id);
          const nid = card.flashcardNote?.id ?? card.flashcard_note;
          return formatCard(card, st, {
            siblingCardCount: nid ? noteSiblingCounts[nid] ?? 1 : 1,
          });
        })
        .filter((card) => cardMatchesFilter(card, card.reviewState, filter, now));

      ctx.body = { data, total: data.length };
    },

    async setCardFlag(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const cardId = parseInt(String(ctx.params.cardId), 10);
      const flag = parseInt(String(ctx.request.body?.flag ?? 0), 10);
      if (Number.isNaN(flag) || flag < 0 || flag > 7) {
        return ctx.badRequest('flag must be 0–7');
      }

      const card = await strapi.db.query('api::flashcard.flashcard').findOne({
        where: { id: cardId, user: userId },
        populate: ['deck', 'flashcardNote'],
      });
      if (!card) return ctx.notFound('Card not found');

      const updated = await strapi.db.query('api::flashcard.flashcard').update({
        where: { id: cardId },
        data: { flag },
      });

      const review = await ensureReviewState(strapi, userId, cardId);
      ctx.body = { ok: true, card: formatCard({ ...card, ...updated, flag }, review) };
    },

    async suspendCard(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const cardId = parseInt(String(ctx.params.cardId), 10);
      const card = await strapi.db.query('api::flashcard.flashcard').findOne({
        where: { id: cardId, user: userId },
      });
      if (!card) return ctx.notFound('Card not found');

      const review = await ensureReviewState(strapi, userId, cardId);
      const updated = await strapi.db.query('api::card-review-state.card-review-state').update({
        where: { id: review.id },
        data: { suspended: true },
      });

      ctx.body = { ok: true, card: formatCard(card, updated) };
    },

    async unsuspendCard(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const cardId = parseInt(String(ctx.params.cardId), 10);
      const card = await strapi.db.query('api::flashcard.flashcard').findOne({
        where: { id: cardId, user: userId },
      });
      if (!card) return ctx.notFound('Card not found');

      const review = await ensureReviewState(strapi, userId, cardId);
      const updated = await strapi.db.query('api::card-review-state.card-review-state').update({
        where: { id: review.id },
        data: { suspended: false, buriedUntil: null },
      });

      ctx.body = { ok: true, card: formatCard(card, updated) };
    },

    async buryCard(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const cardId = parseInt(String(ctx.params.cardId), 10);
      const card = await strapi.db.query('api::flashcard.flashcard').findOne({
        where: { id: cardId, user: userId },
      });
      if (!card) return ctx.notFound('Card not found');

      const review = await ensureReviewState(strapi, userId, cardId);
      const updated = await strapi.db.query('api::card-review-state.card-review-state').update({
        where: { id: review.id },
        data: { buriedUntil: endOfLocalDay() },
      });

      ctx.body = { ok: true, card: formatCard(card, updated) };
    },

    async exportJson(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const deckId = ctx.query.deckId ? parseInt(String(ctx.query.deckId), 10) : null;

      const deckWhere = { user: userId };
      const cardWhere = { user: userId };
      if (deckId) {
        deckWhere.id = deckId;
        cardWhere.deck = deckId;
      }

      const decks = await strapi.db.query('api::flashcard-deck.flashcard-deck').findMany({
        where: deckWhere,
      });
      const cards = await strapi.db.query('api::flashcard.flashcard').findMany({
        where: cardWhere,
      });
      const cardIds = cards.map((c) => c.id);
      const reviews =
        cardIds.length
          ? await strapi.db.query('api::card-review-state.card-review-state').findMany({
              where: { user: userId, flashcard: { $in: cardIds } },
            })
          : [];

      ctx.body = {
        format: 'english-app-flashcards-v1',
        exportedAt: new Date().toISOString(),
        decks: decks.map((d) => formatDeck(d)),
        cards: cards.map((c) => {
          const st = reviews.find((r) => (r.flashcard?.id ?? r.flashcard) === c.id);
          return formatCard(c, st);
        }),
      };
    },

    async syncPull(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const since = ctx.query?.since ?? null;
      const payload = await pullSyncData(strapi, userId, { since });
      ctx.body = payload;
    },

    async syncStatus(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const meta = await getSyncMeta(strapi, userId);
      ctx.body = {
        lastPullAt: meta.lastPullAt,
        lastPushAt: meta.lastPushAt,
        serverTime: new Date().toISOString(),
      };
    },

    async syncPush(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const { reviews } = ctx.request.body ?? {};
      if (!Array.isArray(reviews)) {
        return ctx.badRequest('reviews array is required');
      }

      // Conflict policy (5E-3): server wins when it already has a newer review.
      let applied = 0;
      let skipped = 0;
      const appliedReviews = [];

      for (const item of reviews) {
        const cardId = parseInt(String(item.flashcardId), 10);
        const rating = item.rating;
        if (!cardId || !rating) continue;

        const card = await strapi.db.query('api::flashcard.flashcard').findOne({
          where: { id: cardId, user: userId },
          populate: ['deck'],
        });
        if (!card) {
          skipped += 1;
          continue;
        }

        let review = await strapi.db.query('api::card-review-state.card-review-state').findOne({
          where: { flashcard: cardId, user: userId },
        });
        if (!review) {
          review = await ensureReviewState(strapi, userId, cardId);
        }

        const clientTime = item.reviewedAt ? new Date(item.reviewedAt) : new Date();
        const serverLast = review.lastReviewedAt ?? review.last_reviewed_at;
        if (serverLast && new Date(serverLast) > clientTime) {
          skipped += 1;
          continue;
        }

        const intervalBefore = review.intervalDays ?? review.interval_days ?? 0;
        const stateBefore = review.state ?? 'new';

        const deckRow = card.deck?.id
          ? await strapi.db.query('api::flashcard-deck.flashcard-deck').findOne({
              where: { id: card.deck?.id ?? card.deck, user: userId },
            })
          : null;
        const deckOpts = normalizeDeckOptions(deckRow?.deckOptions ?? deckRow?.deck_options);
        const next = applySm2Rating(review, rating, clientTime, deckOpts);

        const updated = await strapi.db.query('api::card-review-state.card-review-state').update({
          where: { id: review.id },
          data: next,
        });

        await recordReviewLog(strapi, userId, {
          flashcardId: cardId,
          deckId: card.deck?.id ?? card.deck,
          rating,
          durationMs: item.durationMs ?? 0,
          intervalBefore,
          intervalAfter: updated.intervalDays ?? next.intervalDays ?? 0,
          stateBefore,
          stateAfter: updated.state ?? next.state,
          reviewedAt: clientTime,
        });

        applied += 1;
        appliedReviews.push({
          flashcardId: cardId,
          reviewedAt: clientTime.toISOString(),
        });
      }

      ctx.body = { ok: true, applied, skipped, appliedReviews, conflicts: skipped };
      await setSyncMeta(strapi, userId, { lastPushAt: new Date().toISOString() });
    },

    async importCsv(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const { csv, deckId, createDecks } = ctx.request.body ?? {};
      if (!csv || !String(csv).trim()) {
        return ctx.badRequest('csv text is required');
      }

      const result = await importCsv(strapi, userId, String(csv), {
        defaultDeckId: deckId ? parseInt(String(deckId), 10) : null,
        createDecks: createDecks !== false,
      });

      ctx.body = { ok: true, ...result };
    },

    async importTxt(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const { text, deckId, createDecks } = ctx.request.body ?? {};
      if (!text || !String(text).trim()) {
        return ctx.badRequest('text is required');
      }

      const result = await importTxt(strapi, userId, String(text), {
        defaultDeckId: deckId ? parseInt(String(deckId), 10) : null,
        createDecks: createDecks !== false,
      });

      ctx.body = { ok: true, ...result };
    },

    async importApkg(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const files = ctx.request.files;
      const upload =
        files?.file ?? files?.apkg ?? (Array.isArray(files) ? files[0] : null);
      if (!upload) {
        return ctx.badRequest('Missing .apkg file. Send multipart field "file".');
      }

      const filePath = upload.filepath || upload.path;
      if (!filePath) return ctx.badRequest('Invalid file upload');

      const deckIdRaw = ctx.request.body?.deckId;
      const createDecks = ctx.request.body?.createDecks !== 'false';
      const importScheduling = ctx.request.body?.importScheduling === 'true' || ctx.request.body?.importScheduling === true;

      try {
        const result = await importApkgFile(strapi, userId, filePath, {
          defaultDeckId: deckIdRaw ? parseInt(String(deckIdRaw), 10) : null,
          createDecks,
          importScheduling,
        });
        ctx.body = { ok: true, ...result };
      } catch (err) {
        strapi.log.error('[flashcards.importApkg]', err);
        return ctx.badRequest(err.message ?? 'Failed to import .apkg');
      } finally {
        try {
          if (filePath && fs.existsSync(filePath)) fs.unlinkSync(filePath);
        } catch (_) {
          // ignore
        }
      }
    },

    async exportApkg(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const deckId = ctx.query.deckId ? parseInt(String(ctx.query.deckId), 10) : null;

      try {
        const buffer = await buildApkgBuffer(strapi, userId, { deckId });
        const filename = deckId
          ? `deck_${deckId}_${Date.now()}.apkg`
          : `flashcards_${Date.now()}.apkg`;

        ctx.set('Content-Type', 'application/octet-stream');
        ctx.set('Content-Disposition', `attachment; filename="${filename}"`);
        ctx.body = buffer;
      } catch (err) {
        strapi.log.error('[flashcards.exportApkg]', err);
        return ctx.internalServerError('Failed to export .apkg');
      }
    },

    async uploadMedia(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const files = ctx.request.files;
      const upload =
        files?.file ?? files?.media ?? (Array.isArray(files) ? files[0] : null);
      if (!upload) return ctx.badRequest('Missing file. Send multipart field "file".');

      const filePath = upload.filepath || upload.path;
      try {
        const result = await uploadFlashcardMedia(strapi, upload);
        ctx.body = {
          ok: true,
          ...result,
          url: absoluteMediaUrl(strapi, result.url),
        };
      } catch (err) {
        strapi.log.error('[flashcards.uploadMedia]', err);
        return ctx.badRequest(err.message ?? 'Upload failed');
      } finally {
        try {
          if (filePath && fs.existsSync(filePath)) fs.unlinkSync(filePath);
        } catch (_) {}
      }
    },

    async importJson(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const { data, createDecks } = ctx.request.body ?? {};
      if (!data || typeof data !== 'object') {
        return ctx.badRequest('data object is required');
      }

      const result = await importJsonBackup(strapi, userId, data, {
        createDecks: createDecks !== false,
      });
      ctx.body = { ok: true, ...result };
    },

    async undoReview(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      try {
        const result = await undoLastReview(strapi, userId);
        ctx.body = { ok: true, ...result };
      } catch (err) {
        const status = err.status ?? 400;
        ctx.status = status;
        ctx.body = { error: err.message };
      }
    },

    async burySiblings(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const cardId = parseInt(String(ctx.params.cardId), 10);
      try {
        const result = await burySiblingCards(strapi, userId, cardId);
        ctx.body = { ok: true, ...result };
      } catch (err) {
        const status = err.status ?? 400;
        ctx.status = status;
        ctx.body = { error: err.message };
      }
    },

    async unburyCard(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const cardId = parseInt(String(ctx.params.cardId), 10);
      const card = await strapi.db.query('api::flashcard.flashcard').findOne({
        where: { id: cardId, user: userId },
        populate: ['deck', 'flashcardNote'],
      });
      if (!card) return ctx.notFound('Card not found');

      const updated = await unburyCard(strapi, userId, cardId);
      const review = await ensureReviewState(strapi, userId, cardId);
      ctx.body = { ok: true, card: formatCard(card, updated ?? review) };
    },

    async checkCollection(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');
      ctx.body = await runFullCheck(strapi, userId);
    },

    async checkDatabase(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');
      ctx.body = await checkDatabaseIntegrity(strapi, userId);
    },

    async checkMediaFiles(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');
      ctx.body = await checkMedia(strapi, userId);
    },

    async listEmptyCards(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');
      ctx.body = await findEmptyCards(strapi, userId);
    },

    async deleteEmptyCards(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');
      ctx.body = await deleteEmptyCards(strapi, userId);
    },

    async cardInfo(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const cardId = parseInt(String(ctx.params.cardId), 10);
      try {
        ctx.body = await fetchCardInfo(strapi, userId, cardId);
      } catch (err) {
        const status = err.status ?? 400;
        return ctx.throw(status, err.message);
      }
    },

    async setCardDue(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const cardId = parseInt(String(ctx.params.cardId), 10);
      const { dueAt } = ctx.request.body ?? {};
      if (!dueAt) return ctx.badRequest('dueAt is required');
      try {
        const card = await applySetCardDue(strapi, userId, cardId, dueAt);
        ctx.body = { ok: true, card };
      } catch (err) {
        const status = err.status ?? 400;
        return ctx.throw(status, err.message);
      }
    },

    async resetCardProgress(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const cardId = parseInt(String(ctx.params.cardId), 10);
      try {
        const card = await applyResetCardProgress(strapi, userId, cardId);
        ctx.body = { ok: true, card };
      } catch (err) {
        const status = err.status ?? 400;
        return ctx.throw(status, err.message);
      }
    },

    async gradeCardNow(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const cardId = parseInt(String(ctx.params.cardId), 10);
      const { rating } = ctx.request.body ?? {};
      if (!rating) return ctx.badRequest('rating is required');
      try {
        const card = await applyGradeCardNow(strapi, userId, cardId, rating);
        ctx.body = { ok: true, card };
      } catch (err) {
        const status = err.status ?? 400;
        return ctx.throw(status, err.message);
      }
    },

    async repositionCard(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const cardId = parseInt(String(ctx.params.cardId), 10);
      const direction = ctx.request.body?.direction === 'down' ? 'down' : 'up';
      try {
        const card = await applyRepositionCard(strapi, userId, cardId, direction);
        ctx.body = { ok: true, card };
      } catch (err) {
        const status = err.status ?? 400;
        return ctx.throw(status, err.message);
      }
    },

    async ensureCardNote(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const cardId = parseInt(String(ctx.params.cardId), 10);
      const card = await strapi.db.query('api::flashcard.flashcard').findOne({
        where: { id: cardId, user: userId },
        populate: ['deck', 'flashcardNote'],
      });
      if (!card) return ctx.notFound('Card not found');

      try {
        const noteId = await ensureCardHasNote(strapi, userId, card);
        const note = await strapi.db.query('api::flashcard-note.flashcard-note').findOne({
          where: { id: noteId, user: userId },
          populate: ['deck'],
        });
        const siblings = await strapi.db.query('api::flashcard.flashcard').findMany({
          where: { flashcardNote: noteId, user: userId },
          orderBy: { templateOrdinal: 'asc' },
        });
        const siblingIds = siblings.map((c) => c.id);
        const reviews =
          siblingIds.length
            ? await strapi.db.query('api::card-review-state.card-review-state').findMany({
                where: { user: userId, flashcard: { $in: siblingIds } },
              })
            : [];
        const formattedCards = siblings.map((c) => {
          const st = reviews.find((r) => (r.flashcard?.id ?? r.flashcard) === c.id);
          return formatCard(c, st, { siblingCardCount: siblings.length });
        });
        const review = await ensureReviewState(strapi, userId, cardId);
        const formattedCard = formatCard(
          siblings.find((c) => c.id === cardId) ?? card,
          review,
          { siblingCardCount: siblings.length },
        );
        ctx.body = {
          ok: true,
          noteId,
          note: note ? formatNote(note, formattedCards) : null,
          card: formattedCard,
        };
      } catch (err) {
        const status = err.status ?? 400;
        return ctx.throw(status, err.message);
      }
    },

    async exportCardJson(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const cardId = parseInt(String(ctx.params.cardId), 10);
      try {
        const info = await fetchCardInfo(strapi, userId, cardId);
        ctx.body = buildExportCardJson(info.card, info.note);
      } catch (err) {
        const status = err.status ?? 400;
        return ctx.throw(status, err.message);
      }
    },
  }),
);
