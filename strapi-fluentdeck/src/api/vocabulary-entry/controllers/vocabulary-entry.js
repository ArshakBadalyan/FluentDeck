'use strict';

const { createCoreController } = require('@strapi/strapi').factories;
const {
  getFeatureConfig,
  isPremiumUser,
  countVocabularyProgress,
  canSaveWord,
} = require('../../../utils/app-feature-config');
const {
  buildPlacementQuestions,
  scorePlacementAnswers,
} = require('../../../utils/placement-test');
const {
  createUserNote,
  maybeCreateFlashcard,
  deckSlugForSource,
} = require('../../../utils/flashcard-auto-create');
async function getAuthenticatedUserId(ctx, strapi) {
  const token = await strapi.plugins['users-permissions'].services.jwt.getToken(
    ctx,
  );
  return token?.id ?? null;
}

function readAttr(row, camel, snake) {
  return row[camel] ?? row[snake];
}

function normalizeExamples(raw) {
  if (!Array.isArray(raw)) return [];
  return raw
    .map((item) => {
      if (typeof item === 'string') {
        return { text: item };
      }
      if (item && typeof item === 'object') {
        const text = item.text ?? item.sentence ?? '';
        if (!text) return null;
        return {
          text,
          audioUrl: item.audioUrl ?? item.audio_url ?? null,
        };
      }
      return null;
    })
    .filter(Boolean);
}

function primaryExampleSentence(row) {
  const direct = readAttr(row, 'exampleSentence', 'example_sentence');
  if (direct) return direct;

  const examples = normalizeExamples(readAttr(row, 'examples', 'examples'));
  return examples[0]?.text ?? '';
}

function formatEntry(row, { savedEntryIds = new Set(), previewLimited = false } = {}) {
  const id = row.id;
  const examples = previewLimited
    ? []
    : normalizeExamples(readAttr(row, 'examples', 'examples'));
  const exampleSentence = previewLimited
    ? null
    : primaryExampleSentence(row) || null;

  return {
    id,
    word: readAttr(row, 'word', 'word'),
    lemma: readAttr(row, 'lemma', 'lemma') ?? readAttr(row, 'word', 'word'),
    entryType: readAttr(row, 'entryType', 'entry_type') ?? 'word',
    partOfSpeech: readAttr(row, 'partOfSpeech', 'part_of_speech') ?? '',
    definition: previewLimited ? null : readAttr(row, 'definition', 'definition'),
    exampleSentence,
    examples,
    ipa: previewLimited ? null : readAttr(row, 'ipa', 'ipa') ?? '',
    audioUrl: previewLimited ? null : readAttr(row, 'audioUrl', 'audio_url') ?? '',
    cefrLevel: readAttr(row, 'cefrLevel', 'cefr_level') ?? null,
    topic: readAttr(row, 'topic', 'topic') ?? '',
    frequencyRank: readAttr(row, 'frequencyRank', 'frequency_rank') ?? 0,
    frequencyBucket: readAttr(row, 'frequencyBucket', 'frequency_bucket') ?? '',
    sensePriority: readAttr(row, 'sensePriority', 'sense_priority') ?? null,
    source: readAttr(row, 'source', 'source') ?? '',
    externalId: readAttr(row, 'externalId', 'external_id') ?? '',
    isSaved: savedEntryIds.has(id),
    previewLimited,
  };
}

module.exports = createCoreController(
  'api::vocabulary-entry.vocabulary-entry',
  ({ strapi }) => ({
    async catalogStats(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
      const stats = {};

      for (const level of levels) {
        const count = await strapi.db
          .query('api::vocabulary-entry.vocabulary-entry')
          .count({
            where: { cefrLevel: level, publishedAt: { $notNull: true } },
          });
        stats[level] = count;
      }

      const bucketRows = await strapi.db.connection('vocabulary_entries')
        .whereNotNull('published_at')
        .whereNotNull('frequency_bucket')
        .where('frequency_bucket', '!=', '')
        .groupBy('frequency_bucket')
        .select('frequency_bucket')
        .count('* as count');

      const bucketCounts = {};
      for (const row of bucketRows) {
        bucketCounts[row.frequency_bucket] = Number(row.count) || 0;
      }

      const savedCount = await countVocabularyProgress(strapi, userId);
      const config = await getFeatureConfig(strapi);
      const premium = await isPremiumUser(strapi, userId);

      ctx.body = {
        levelCounts: stats,
        bucketCounts,
        savedCount,
        saveLimit: premium ? null : config.freeMaxSavedWords,
        isPremium: premium,
      };
    },

    async catalogList(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const {
        level,
        topic,
        frequencyBucket,
        page = '1',
        pageSize = '50',
      } = ctx.query ?? {};
      const pageNum = Math.max(1, parseInt(String(page), 10) || 1);
      const size = Math.min(100, Math.max(1, parseInt(String(pageSize), 10) || 50));
      const offset = (pageNum - 1) * size;

      const where = { publishedAt: { $notNull: true } };
      if (level) where.cefrLevel = String(level);
      if (topic) where.topic = String(topic);
      if (frequencyBucket) where.frequencyBucket = String(frequencyBucket);

      const [rows, total] = await Promise.all([
        strapi.db.query('api::vocabulary-entry.vocabulary-entry').findMany({
          where,
          orderBy: [{ frequencyRank: 'asc' }, { word: 'asc' }, { id: 'asc' }],
          limit: size,
          offset,
        }),
        strapi.db.query('api::vocabulary-entry.vocabulary-entry').count({ where }),
      ]);

      const savedRows = await strapi.db
        .query('api::user-vocabulary-progress.user-vocabulary-progress')
        .findMany({
          where: { user: userId },
          populate: ['vocabularyEntry'],
        });
      const savedEntryIds = new Set(
        savedRows
          .map((r) => r.vocabularyEntry?.id ?? r.vocabulary_entry?.id)
          .filter(Boolean),
      );

      const config = await getFeatureConfig(strapi);
      const premium = await isPremiumUser(strapi, userId);
      const advancedLevels = Array.isArray(config.advancedLevelsRequiringPremium)
        ? config.advancedLevelsRequiringPremium
        : ['B2', 'C1', 'C2'];

      const data = rows.map((row, index) => {
        const globalIndex = offset + index;
        const cefrLevel = readAttr(row, 'cefrLevel', 'cefr_level');
        const isAdvanced = cefrLevel && advancedLevels.includes(cefrLevel);
        const previewLimited =
          !premium && isAdvanced && globalIndex >= config.freePreviewWordsPerAdvancedList;
        return formatEntry(row, { savedEntryIds, previewLimited });
      });

      ctx.body = {
        data,
        meta: {
          pagination: {
            page: pageNum,
            pageSize: size,
            pageCount: Math.ceil(total / size) || 1,
            total,
          },
        },
      };
    },

    async saveWord(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const { vocabularyEntryId, status = 'new' } = ctx.request.body ?? {};
      const entryId = parseInt(String(vocabularyEntryId), 10);
      if (!entryId) return ctx.badRequest('vocabularyEntryId is required');

      const entry = await strapi.db
        .query('api::vocabulary-entry.vocabulary-entry')
        .findOne({ where: { id: entryId, publishedAt: { $notNull: true } } });
      if (!entry) return ctx.notFound('Vocabulary entry not found');

      const allowed = await canSaveWord(strapi, userId, entryId);
      if (!allowed.ok) {
        return ctx.forbidden(allowed.reason);
      }

      const existing = await strapi.db
        .query('api::user-vocabulary-progress.user-vocabulary-progress')
        .findOne({
          where: { user: userId, vocabularyEntry: entryId },
        });

      const validStatuses = ['new', 'learning', 'known'];
      const nextStatus = validStatuses.includes(status) ? status : 'new';

      let progressId;
      let alreadySaved = false;

      if (existing) {
        await strapi.db
          .query('api::user-vocabulary-progress.user-vocabulary-progress')
          .update({
            where: { id: existing.id },
            data: { status: nextStatus },
          });
        progressId = existing.id;
        alreadySaved = true;
      } else {
        const created = await strapi.db
          .query('api::user-vocabulary-progress.user-vocabulary-progress')
          .create({
            data: {
              user: userId,
              vocabularyEntry: entryId,
              status: nextStatus,
              savedAt: new Date(),
            },
          });
        progressId = created.id;
      }

      const exampleSentence = primaryExampleSentence(entry);

      const { note } = await createUserNote(strapi, userId, {
        word: entry.word,
        definition: entry.definition,
        exampleSentence,
        source: 'catalog',
        vocabularyEntryId: entryId,
      });

      const flashcardResult = await maybeCreateFlashcard(strapi, userId, {
        word: entry.word,
        definition: entry.definition,
        exampleSentence,
        deckSlug: deckSlugForSource('catalog'),
        noteId: note.id,
      });

      ctx.body = {
        ok: true,
        id: progressId,
        status: nextStatus,
        alreadySaved,
        noteId: note.id,
        ...flashcardResult,
      };
    },

    async unsaveWord(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const { vocabularyEntryId } = ctx.request.body ?? {};
      const entryId = parseInt(String(vocabularyEntryId), 10);
      if (!entryId) return ctx.badRequest('vocabularyEntryId is required');

      const existing = await strapi.db
        .query('api::user-vocabulary-progress.user-vocabulary-progress')
        .findOne({
          where: { user: userId, vocabularyEntry: entryId },
        });

      if (!existing) {
        ctx.body = { ok: true, removed: false };
        return;
      }

      await strapi.db
        .query('api::user-vocabulary-progress.user-vocabulary-progress')
        .delete({ where: { id: existing.id } });

      const linkedNotes = await strapi.db.query('api::user-note.user-note').findMany({
        where: { user: userId, vocabularyEntry: entryId },
      });

      for (const note of linkedNotes) {
        await strapi.db.query('api::user-note.user-note').delete({ where: { id: note.id } });
      }

      ctx.body = { ok: true, removed: true };
    },

    async myWords(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const rows = await strapi.db
        .query('api::user-vocabulary-progress.user-vocabulary-progress')
        .findMany({
          where: { user: userId },
          populate: ['vocabularyEntry'],
          orderBy: { savedAt: 'desc' },
        });

      const data = rows
        .map((row) => {
          const entry = row.vocabularyEntry ?? row.vocabulary_entry;
          if (!entry) return null;
          return {
            progressId: row.id,
            status: row.status,
            savedAt: row.savedAt ?? row.saved_at,
            entry: formatEntry(entry, { savedEntryIds: new Set([entry.id]) }),
          };
        })
        .filter(Boolean);

      ctx.body = { data };
    },

    async placementQuestions(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      let questions = await buildPlacementQuestions(strapi);
      if (!questions.length) {
        const { seedPlacementVocabulary } = require('../../../utils/seed-placement-vocabulary');
        await seedPlacementVocabulary(strapi);
        questions = await buildPlacementQuestions(strapi);
      }
      if (!questions.length) {
        return ctx.serviceUnavailable(
          'Placement vocabulary is not available yet. Please try again later.',
        );
      }
      ctx.body = { questions };
    },

    async submitPlacement(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const { answers } = ctx.request.body ?? {};
      if (!Array.isArray(answers) || answers.length === 0) {
        return ctx.badRequest('answers array is required');
      }

      const config = await getFeatureConfig(strapi);
      const premium = await isPremiumUser(strapi, userId);

      if (!premium) {
        const monthStart = new Date();
        monthStart.setDate(1);
        monthStart.setHours(0, 0, 0, 0);

        const recentCount = await strapi.db
          .query('api::placement-test-result.placement-test-result')
          .count({
            where: {
              user: userId,
              takenAt: { $gte: monthStart },
            },
          });

        if (recentCount >= config.freePlacementRetakesPerMonth) {
          return ctx.forbidden(
            'Free tier placement retake limit reached for this month.',
          );
        }
      }

      const result = scorePlacementAnswers(answers);
      const takenAt = new Date();

      const saved = await strapi.db
        .query('api::placement-test-result.placement-test-result')
        .create({
          data: {
            user: userId,
            suggestedLevel: result.suggestedLevel,
            levelBucket: result.levelBucket,
            score: result.score,
            answersSummary: result.summary,
            takenAt,
          },
        });

      await strapi.db.query('plugin::users-permissions.user').update({
        where: { id: userId },
        data: { english_level: result.suggestedLevel },
      });

      const progressRows = await strapi.db
        .query('api::user-progress.user-progress')
        .findMany({ where: { user: userId }, limit: 1 });
      if (progressRows[0]) {
        await strapi.db.query('api::user-progress.user-progress').update({
          where: { id: progressRows[0].id },
          data: { currentLevel: result.suggestedLevel },
        });
      }

      ctx.body = {
        id: saved.id,
        suggestedLevel: result.suggestedLevel,
        levelBucket: result.levelBucket,
        score: result.score,
        studySuggestions: result.studySuggestions,
        takenAt: takenAt.toISOString(),
      };
    },

    async latestPlacement(ctx) {
      const userId = await getAuthenticatedUserId(ctx, strapi);
      if (!userId) return ctx.unauthorized('Authentication required');

      const rows = await strapi.db
        .query('api::placement-test-result.placement-test-result')
        .findMany({
          where: { user: userId },
          orderBy: { takenAt: 'desc' },
          limit: 1,
        });

      if (!rows.length) {
        ctx.body = { result: null };
        return;
      }

      const row = rows[0];
      ctx.body = {
        result: {
          id: row.id,
          suggestedLevel: row.suggestedLevel ?? row.suggested_level,
          levelBucket: row.levelBucket ?? row.level_bucket,
          score: row.score,
          takenAt: row.takenAt ?? row.taken_at,
        },
      };
    },
  }),
);
