"use strict";

function hasRichTextContent(value) {
  if (value == null) {
    return false;
  }
  if (typeof value === "string") {
    return value.trim().length > 0;
  }
  if (Array.isArray(value)) {
    return value.length > 0;
  }
  if (typeof value === "object") {
    return Object.keys(value).length > 0;
  }
  return false;
}

/**
 * Removes large `lesson` / `solution` blobs from API-shaped objects and adds
 * `hasLesson` / `hasSolution` booleans. Recurses into nested objects and arrays
 * (e.g. Strapi `attributes`, relation `data` wrappers).
 *
 * Does not run on wpSync / wpSyncFinal payloads (those are stripped separately by not calling this).
 */
function stripHeavyFieldsDeep(value) {
  if (value == null) {
    return value;
  }
  if (Array.isArray(value)) {
    return value.map((item) => stripHeavyFieldsDeep(item));
  }
  if (typeof value !== "object") {
    return value;
  }

  let next = { ...value };

  if ("lesson" in next) {
    const hasLesson = hasRichTextContent(next.lesson);
    const { lesson, ...rest } = next;
    next = { ...rest, hasLesson };
  }

  if (
    "solution" in next &&
    ("wrong_answers" in next || next.answer !== undefined)
  ) {
    const hasSolution = hasRichTextContent(next.solution);
    const { solution, ...rest } = next;
    next = { ...rest, hasSolution };
  }

  for (const key of Object.keys(next)) {
    const child = next[key];
    if (child != null && typeof child === "object") {
      next[key] = stripHeavyFieldsDeep(child);
    }
  }
  return next;
}

module.exports = { stripHeavyFieldsDeep, hasRichTextContent };
