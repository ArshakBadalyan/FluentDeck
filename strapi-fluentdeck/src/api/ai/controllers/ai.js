"use strict";

const fs = require("fs");
const { createCoreController } = require("@strapi/strapi").factories;
const {
  transcribeAudio,
  looksLikeWhisperHallucination,
  getTutorReply,
  translateMessage,
  synthesizeSpeech,
  evaluateSession: evaluateSpeakingSession,
  loadUserTutorContext,
} = require("../../../utils/ai-tutor");
const { resolveTrainingSession } = require("../../../utils/tutor-vocab-context");
const {
  loadUserDeckCatalog,
  processSpeakingNoteAction,
  formatDeckCatalogBlock,
} = require("../../../utils/speaking-note-actions");
const { recordSpeakingTurnStats } = require("../../../utils/speaking-stats-utils");
const {
  getConversationUsage,
  recordConversationTurn,
  validateSessionOpening,
  clampHistory,
  clampTtsText,
  ensureConversationAllowed,
} = require("../../../utils/ai-rate-limit");
const { assertSpeakingSessionAllowed } = require("../../../utils/speaking-session-access");
const {
  autoSaveCorrectionsFromTurn,
} = require("../../../utils/auto-save-corrections");
const { normalizePracticeLanguage } = require("../../../utils/practice-languages");
const {
  loadTutorMemory,
  processMemoryUpdate,
  deleteMemoryFact,
} = require("../../../utils/tutor-memory");
const { generateWordMeaning } = require("../../../utils/word-meaning");
const { isPremiumUser } = require("../../../utils/app-feature-config");

async function getAuthenticatedUserId(ctx, strapi) {
  const token = await strapi.plugins["users-permissions"].services.jwt.getToken(
    ctx,
  );
  return token?.id ?? null;
}

module.exports = createCoreController("api::ai.ai-config", ({ strapi }) => ({
  async usage(ctx) {
    const userId = await getAuthenticatedUserId(ctx, strapi);
    if (!userId) {
      return ctx.unauthorized("Authentication required");
    }

    const usage = await getConversationUsage(strapi, userId);
    ctx.body = usage;
  },

  async memory(ctx) {
    const userId = await getAuthenticatedUserId(ctx, strapi);
    if (!userId) {
      return ctx.unauthorized("Authentication required");
    }

    if (ctx.request.method === "GET") {
      const facts = await loadTutorMemory(strapi, userId);
      ctx.body = { facts };
      return;
    }

    if (ctx.request.method === "DELETE") {
      const index = ctx.query?.index ?? ctx.request.body?.index;
      const result = await deleteMemoryFact(strapi, userId, index);
      if (!result.ok) {
        return ctx.badRequest("Invalid memory index");
      }
      ctx.body = { facts: result.facts };
      return;
    }

    return ctx.methodNotAllowed();
  },

  async transcribe(ctx) {
    const userId = await getAuthenticatedUserId(ctx, strapi);
    if (!userId) {
      return ctx.unauthorized("Authentication required");
    }

    const usageBefore = await ensureConversationAllowed(ctx, strapi, userId);
    if (!usageBefore) return;

    const files = ctx.request.files;
    const audioFile =
      files?.audio ?? files?.file ?? (Array.isArray(files) ? files[0] : null);

    if (!audioFile) {
      return ctx.badRequest('Missing audio file. Send multipart field "audio".');
    }

    const filePath = audioFile.filepath || audioFile.path;
    if (!filePath) {
      return ctx.badRequest("Invalid audio upload");
    }

    try {
      const stats = fs.statSync(filePath);
      const { practiceLanguage } = await loadUserTutorContext(strapi, userId);
      const requestedLanguage = ctx.request.body?.language ?? ctx.request.fields?.language;
      const language = normalizePracticeLanguage(requestedLanguage ?? practiceLanguage);
      const transcription = await transcribeAudio(
        filePath,
        audioFile.originalFilename || audioFile.name || "audio.m4a",
        language,
      );
      strapi.log.info(
        `[ai.transcribe] ${Math.round(stats.size / 1024)}KB audio → ${transcription.text.length} chars`,
      );
      ctx.body = {
        text: transcription.text,
        language,
        segments: transcription.segments,
        usage: await recordConversationTurn(strapi, userId),
      };
    } catch (error) {
      strapi.log.error("[ai.transcribe]", error);
      return ctx.internalServerError("Transcription failed");
    } finally {
      try {
        if (filePath && fs.existsSync(filePath)) {
          fs.unlinkSync(filePath);
        }
      } catch {
        // ignore cleanup errors
      }
    }
  },

  async tutor(ctx) {
    const userId = await getAuthenticatedUserId(ctx, strapi);
    if (!userId) {
      return ctx.unauthorized("Authentication required");
    }

    const usageBefore = await getConversationUsage(strapi, userId);
    if (!usageBefore.allowed) {
      ctx.status = 429;
      ctx.body = {
        error: {
          message: "Daily conversation limit reached",
          status: 429,
        },
        limitReached: true,
        usedToday: usageBefore.usedToday,
        dailyLimit: usageBefore.dailyLimit,
        isPremium: usageBefore.isPremium,
        unlimited: usageBefore.unlimited === true,
      };
      return;
    }

    const {
      message,
      history,
      trainingSession: clientTrainingSession,
      sessionContext,
      sessionStart,
    } = ctx.request.body ?? {};
    if (!message || typeof message !== "string" || !message.trim()) {
      return ctx.badRequest("message is required");
    }

    const openingSession = sessionStart === true;
    const trimmedMessage = message.trim();

    if (openingSession) {
      const openingCheck = await validateSessionOpening(strapi, userId, {
        history: Array.isArray(history) ? history : [],
      });
      if (!openingCheck.allowed) {
        ctx.status = openingCheck.usedToday != null ? 429 : 400;
        ctx.body = {
          error: {
            message: openingCheck.reason ?? 'Invalid session opening',
            status: ctx.status,
          },
          usage: usageBefore,
        };
        return;
      }
    }

    const sessionAccess = await assertSpeakingSessionAllowed(
      strapi,
      userId,
      sessionContext && typeof sessionContext === "object" ? sessionContext : null,
    );
    if (!sessionAccess.ok) {
      ctx.status = sessionAccess.status ?? 402;
      ctx.body = {
        error: {
          status: ctx.status,
          name: "PremiumRequired",
          message: sessionAccess.message,
        },
      };
      return;
    }

    // Only block clear Whisper/YouTube junk on tutor text. Typed short messages
    // like "hi" must pass (hallucination heuristics need Whisper segments).
    if (!openingSession && looksLikeWhisperHallucination(trimmedMessage)) {
      ctx.status = 400;
      ctx.body = {
        error: { message: "No speech detected", status: 400 },
        noSpeech: true,
        usage: usageBefore,
      };
      return;
    }

    try {
      const { userLevel, weakAreas, speakingPreferences, tutorMemory, practiceLanguage } =
        await loadUserTutorContext(strapi, userId);
      const { trainingSession, trainingNotice, trainingStarted } =
        await resolveTrainingSession(
          strapi,
          userId,
          trimmedMessage,
          clientTrainingSession,
        );
      const deckCatalog = await loadUserDeckCatalog(strapi, userId);
      const result = await getTutorReply({
        message: trimmedMessage,
        history: clampHistory(history),
        userLevel,
        weakAreas,
        tutorMemory,
        trainingSession: trainingSession?.active ? trainingSession : null,
        trainingStarted:
          !!trainingStarted || (openingSession && !!trainingSession?.active),
        sessionStart: openingSession,
        sessionContext:
          sessionContext && typeof sessionContext === "object"
            ? sessionContext
            : null,
        speakingPreferences,
        deckCatalogBlock: formatDeckCatalogBlock(deckCatalog),
        practiceLanguage,
      });

      let noteCreated = null;
      let noteLimitReached = false;
      let noteMessage = null;
      if (result.noteAction) {
        const noteResult = await processSpeakingNoteAction(
          strapi,
          userId,
          result.noteAction,
          { activeTrainingSession: trainingSession },
        );
        if (noteResult.noteCreated) {
          noteCreated = noteResult.noteCreated;
        }
        if (noteResult.limitReached) {
          noteLimitReached = true;
          noteMessage = noteResult.message;
        }
      }

      const autoSaveResult = await autoSaveCorrectionsFromTurn(
        strapi,
        userId,
        result.corrections,
      );
      // Auto-saves are marked visually in the Flutter chat UI — do not emit
      // spoken/chat noteMessage bubbles for the success path.
      if (!noteLimitReached && autoSaveResult.limitReached) {
        noteLimitReached = true;
        noteMessage =
          'Free auto-save limit reached (10 notes). Upgrade for unlimited deck notes.';
      }

      let memoryUpdated = false;
      let memoryFacts = tutorMemory;
      if (result.memoryUpdate) {
        const memoryResult = await processMemoryUpdate(
          strapi,
          userId,
          result.memoryUpdate,
        );
        memoryUpdated = memoryResult.updated;
        memoryFacts = memoryResult.facts;
      }

      const speakingStats = openingSession
        ? null
        : await recordSpeakingTurnStats(strapi, userId, {
            userText: trimmedMessage,
            corrections: result.corrections,
          });

      // Session opening (first AI greeting) is free — count starts after the user engages.
      const usageAfter = openingSession
        ? usageBefore
        : await recordConversationTurn(strapi, userId);

      ctx.body = {
        ...result,
        memoryUpdate: undefined,
        trainingSession,
        usage: usageAfter,
        ...(memoryUpdated ? { memoryUpdated: true, memoryFacts } : {}),
        ...(trainingNotice ? { trainingNotice } : {}),
        ...(noteCreated ? { noteCreated } : {}),
        ...(autoSaveResult.saved?.length
          ? { autoSavedWords: autoSaveResult.saved }
          : {}),
        ...(noteLimitReached ? { noteLimitReached: true, noteMessage } : {}),
        ...(speakingStats ? { speakingStats } : {}),
      };
    } catch (error) {
      strapi.log.error("[ai.tutor]", error);
      return ctx.internalServerError("Tutor request failed");
    }
  },

  async evaluateSession(ctx) {
    const userId = await getAuthenticatedUserId(ctx, strapi);
    if (!userId) {
      return ctx.unauthorized("Authentication required");
    }

    const usageBefore = await ensureConversationAllowed(ctx, strapi, userId);
    if (!usageBefore) return;

    const { history, sessionContext } = ctx.request.body ?? {};
    const safeHistory = clampHistory(history);
    if (!Array.isArray(safeHistory) || safeHistory.length < 2) {
      return ctx.badRequest("history must contain at least 2 turns");
    }

    const sessionAccess = await assertSpeakingSessionAllowed(
      strapi,
      userId,
      sessionContext && typeof sessionContext === "object" ? sessionContext : null,
    );
    if (!sessionAccess.ok) {
      ctx.status = sessionAccess.status ?? 402;
      ctx.body = {
        error: {
          status: ctx.status,
          name: "PremiumRequired",
          message: sessionAccess.message,
        },
      };
      return;
    }

    try {
      const { userLevel } = await loadUserTutorContext(strapi, userId);
      const result = await evaluateSpeakingSession({
        history: safeHistory,
        sessionContext:
          sessionContext && typeof sessionContext === "object"
            ? sessionContext
            : { mode: "chat", title: "Free conversation" },
        userLevel,
      });
      ctx.body = {
        ...result,
        usage: await recordConversationTurn(strapi, userId),
      };
    } catch (error) {
      strapi.log.error("[ai.evaluateSession]", error);
      return ctx.internalServerError("Session evaluation failed");
    }
  },

  async translateMessage(ctx) {
    const userId = await getAuthenticatedUserId(ctx, strapi);
    if (!userId) {
      return ctx.unauthorized("Authentication required");
    }

    const usageBefore = await ensureConversationAllowed(ctx, strapi, userId);
    if (!usageBefore) return;

    const { text, targetLanguage } = ctx.request.body ?? {};
    const trimmed = String(text ?? '').trim();
    if (!trimmed) {
      return ctx.badRequest("text is required");
    }
    if (trimmed.length > 4000) {
      return ctx.badRequest("text is too long");
    }
    if (!targetLanguage || !String(targetLanguage).trim()) {
      return ctx.badRequest("targetLanguage is required");
    }

    try {
      const translation = await translateMessage({
        text: trimmed,
        targetLanguage: String(targetLanguage).trim(),
      });
      ctx.body = {
        translation,
        usage: await recordConversationTurn(strapi, userId),
      };
    } catch (error) {
      strapi.log.error("[ai.translateMessage]", error);
      return ctx.internalServerError("Translation request failed");
    }
  },

  async wordMeaning(ctx) {
    const userId = await getAuthenticatedUserId(ctx, strapi);
    if (!userId) {
      return ctx.unauthorized("Authentication required");
    }

    const usageBefore = await ensureConversationAllowed(ctx, strapi, userId);
    if (!usageBefore) return;

    const premium = await isPremiumUser(strapi, userId);
    if (!premium) {
      ctx.status = 402;
      ctx.body = {
        error: {
          status: 402,
          name: "PremiumRequired",
          message: "Generating a word meaning with AI is a premium feature.",
        },
      };
      return;
    }

    const { word, context } = ctx.request.body ?? {};
    if (!word || !String(word).trim()) {
      return ctx.badRequest("word is required");
    }

    try {
      const result = await generateWordMeaning({
        word: String(word).trim(),
        context: context ? String(context).trim() : undefined,
      });
      ctx.body = {
        ...result,
        usage: await recordConversationTurn(strapi, userId),
      };
    } catch (error) {
      strapi.log.error("[ai.wordMeaning]", error);
      return ctx.internalServerError("Could not generate word meaning");
    }
  },

  async tts(ctx) {
    const userId = await getAuthenticatedUserId(ctx, strapi);
    if (!userId) {
      return ctx.unauthorized("Authentication required");
    }

    const usageBefore = await ensureConversationAllowed(ctx, strapi, userId);
    if (!usageBefore) return;

    const { text } = ctx.request.body ?? {};
    const safeText = clampTtsText(text);
    if (!safeText) {
      return ctx.badRequest("text is required");
    }

    try {
      const { findUserById } = require("../../../utils/document-service");
      const user = await findUserById(strapi, userId, {
        fields: ["tutor_voice"],
      });
      const audioBuffer = await synthesizeSpeech(
        safeText,
        user?.tutor_voice
      );
      ctx.body = {
        audioBase64: audioBuffer.toString("base64"),
        contentType: "audio/mpeg",
        usage: await recordConversationTurn(strapi, userId),
      };
    } catch (error) {
      strapi.log.error("[ai.tts]", error);
      return ctx.internalServerError("TTS request failed");
    }
  },
}));
