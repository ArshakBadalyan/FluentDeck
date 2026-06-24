"use strict";

const { isAdmin } = require("./is-admin");
const { getCategoryLesson, extractBodyHtml } = require("./open-ai");

/// Prevents concurrent generations for the same category (duplicate cost
/// and last-write-wins races when an admin clicks the button twice).
const inFlightCategoryIds = new Set();

/// Safety net: even if the model ignores the instruction and emits an <img>
/// tag, remove it so we never store hallucinated / external URLs in `lesson`.
function stripExternalImages(html) {
  if (typeof html !== "string") return "";
  return html
    .replace(/<img\b[^>]*>/gi, "")
    .replace(/<\/img\s*>/gi, "");
}

/**
 * From `category_class.name` (e.g. "11.-12."). Picks the first 1–2 digit
 * number and forms "N class" for the model. If no digit, returns the
 * trimmed name as-is.
 */
function schoolClassForPrompt(className) {
  if (typeof className !== "string" || !className.trim()) return "";
  const m = className.match(/(\d{1,2})/);
  if (m) return `${m[1]} class`;
  return className.trim();
}

function richTextToPromptString(value) {
  if (value == null) {
    return "";
  }
  if (typeof value === "string") {
    return value;
  }
  try {
    return JSON.stringify(value);
  } catch {
    return "";
  }
}

/**
 * Admin-only: builds category `lesson` from OpenAI using selected question ids.
 * Lives in a util so it can be mounted on the **question** custom router (Strapi 4
 * does not accept this POST on the category router — 405).
 */
async function generateCategoryLesson(strapi, ctx) {
  if (!(await isAdmin(ctx))) {
    return ctx.badRequest(null, "You are not allowed to access this route");
  }
  const data = ctx.request.body?.data;
  const categoryID = Number(data?.categoryID);
  const questionIds = data?.questionIds;
  if (data?.categoryID == null || data?.categoryID === "" || Number.isNaN(categoryID)) {
    return ctx.badRequest("categoryID is required");
  }
  if (!Array.isArray(questionIds) || questionIds.length === 0) {
    return ctx.badRequest("questionIds must be a non-empty array");
  }
  const maxExamples = 40;
  const ids = [...new Set(questionIds.map((id) => Number(id)).filter((n) => !Number.isNaN(n)))].slice(
    0,
    maxExamples
  );
  if (ids.length === 0) {
    return ctx.badRequest("No valid question ids");
  }

  if (inFlightCategoryIds.has(categoryID)) {
    return ctx.tooManyRequests
      ? ctx.tooManyRequests("Lesson generation already running for this category")
      : ctx.badRequest("Lesson generation already running for this category");
  }
  inFlightCategoryIds.add(categoryID);

  try {
    const category = await strapi.entityService.findOne("api::category.category", categoryID, {
      fields: ["id", "name"],
      populate: { category_class: { fields: ["id", "name"] } },
    });
    if (!category) {
      return ctx.badRequest("Category not found");
    }
    const rawClassName =
      typeof category.category_class?.name === "string"
        ? category.category_class.name
        : "";
    const schoolClassLabel = schoolClassForPrompt(rawClassName);

    const questions = await strapi.entityService.findMany("api::question.question", {
      filters: {
        id: { $in: ids },
        category: { id: { $eq: categoryID } },
      },
      fields: ["id", "question", "answer", "second_answer", "wrong_answers"],
    });
    if (questions.length === 0) {
      return ctx.badRequest("No matching questions for this category");
    }

    const regex = /^(@emoji@|@@@|@@|@)/;
    const lines = [];
    let i = 1;
    for (const q of questions) {
      const rawQ = richTextToPromptString(q.question);
      const rawA = typeof q.answer === "string" ? q.answer : "";
      const cleanQuestion = rawQ.replace(regex, "");
      const cleanAnswer = rawA.replace(regex, "");
      lines.push(`Beispiel ${i}`);
      lines.push(`Aufgabe: ${cleanQuestion}`);
      lines.push(`Richtige Antwort: ${cleanAnswer}`);
      if (Array.isArray(q.wrong_answers) && q.wrong_answers.length) {
        lines.push(`Falsche Antworten (zur Einordnung): ${JSON.stringify(q.wrong_answers)}`);
      }
      if (q.second_answer) {
        lines.push(`Zweite Antwort / Rechenweg: ${q.second_answer}`);
      }
      lines.push("");
      i += 1;
    }
    const exercisesText = lines.join("\n");

    const openAIResponse = await getCategoryLesson(
      category.name,
      String(categoryID),
      exercisesText,
      schoolClassLabel
    );
    if (openAIResponse?.error || !openAIResponse?.choices?.[0]?.message?.content) {
      strapi.log.error(
        `generateCategoryLesson: OpenAI returned no content for category ${categoryID}: ${
          openAIResponse?.error?.message || "empty response"
        }`
      );
      return { success: false, lesson: false };
    }
    const initialText = openAIResponse.choices[0].message.content;
    const lessonHtml = stripExternalImages(extractBodyHtml(initialText));
    if (!lessonHtml) {
      strapi.log.error(
        `generateCategoryLesson: empty lesson HTML after extraction for category ${categoryID}`
      );
      return { success: false, lesson: false };
    }

    await strapi.entityService.update("api::category.category", categoryID, {
      data: {
        lesson: lessonHtml,
        lesson_checked: false,
      },
    });

    return { success: true, lesson: true };
  } finally {
    inFlightCategoryIds.delete(categoryID);
  }
}

module.exports = { generateCategoryLesson };
