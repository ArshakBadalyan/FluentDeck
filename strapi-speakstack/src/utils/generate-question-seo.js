"use strict";

const {
  getSolutionSeo,
  parseSolutionSeoResponse,
} = require("./open-ai");
const { sanitizeDbText } = require("./sanitize-db-text");

const QUESTION_PREFIX_REGEX = /^(@emoji@|@@@|@@|@pre@|@)/;

function cleanQuestionField(value) {
  return String(value || "").replace(QUESTION_PREFIX_REGEX, "").trim();
}

function questionNeedsSeo(question) {
  return !String(question?.seo_title || "").trim() ||
    !String(question?.seo_description || "").trim();
}

async function generateAndSaveQuestionSeo(strapi, question) {
  if (!question?.id || !question?.solution || !questionNeedsSeo(question)) {
    return { saved: false, reason: "not-needed" };
  }

  const categoryName = question?.category?.name || "";
  const cleanQuestion = cleanQuestionField(question.question);
  const cleanAnswer = cleanQuestionField(question.answer);
  const openAIResponse = await getSolutionSeo(
    cleanQuestion,
    cleanAnswer,
    categoryName,
    question.solution
  );
  const seo = parseSolutionSeoResponse(openAIResponse);
  if (!seo) {
    return { saved: false, reason: "generation-failed" };
  }

  const seoTitle = sanitizeDbText(seo.seo_title);
  const seoDescription = sanitizeDbText(seo.seo_description);
  if (!seoTitle || !seoDescription) {
    return { saved: false, reason: "empty-after-sanitize" };
  }

  try {
    await strapi.entityService.update("api::question.question", question.id, {
      data: {
        seo_title: seoTitle,
        seo_description: seoDescription,
      },
    });
  } catch (error) {
    return {
      saved: false,
      reason: "db-error",
      error: error?.message || String(error),
      questionId: question.id,
    };
  }

  return {
    saved: true,
    seo_title: seoTitle,
    seo_description: seoDescription,
  };
}

module.exports = {
  cleanQuestionField,
  questionNeedsSeo,
  generateAndSaveQuestionSeo,
};
