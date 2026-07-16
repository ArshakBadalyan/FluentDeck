"use strict";

/**
 * Appends to user.old_data when email and/or username change.
 * See lifecycles.js afterCreate for the initial snapshot; this handles updates
 * on the custom users-permissions routes where DB beforeUpdate is unreliable
 * (entity service passes transformed data to lifecycles).
 */

function toNullableString(value) {
  if (value == null || value === "") {
    return null;
  }
  return String(value).trim();
}

function normEmail(value) {
  if (value == null || value === "") {
    return null;
  }
  return String(value).trim().toLowerCase();
}

function normUsername(value) {
  if (value == null || value === "") {
    return null;
  }
  return String(value).trim().toLowerCase();
}

function emailsDiffer(a, b) {
  return normEmail(a) !== normEmail(b);
}

function usernamesDiffer(a, b) {
  return normUsername(a) !== normUsername(b);
}

function normalizeHistory(raw) {
  if (raw == null) {
    return [];
  }
  if (Array.isArray(raw)) {
    return raw.filter((e) => e && typeof e === "object");
  }
  return [];
}

/**
 * Mutates [incoming] (data passed to entityService.update) to set `old_data`
 * when `email` and/or `username` keys are present and values actually changed
 * compared to [existing] from the DB.
 *
 * @param {object} existing - { email, username, old_data } from the DB
 * @param {object} incoming - update payload (will be mutated)
 */
function mergeUserIdentityHistoryIntoUpdateData(existing, incoming) {
  if (!existing || !incoming || typeof incoming !== "object") {
    return;
  }

  const hasEmail = Object.prototype.hasOwnProperty.call(incoming, "email");
  const hasUsername = Object.prototype.hasOwnProperty.call(
    incoming,
    "username"
  );
  if (!hasEmail && !hasUsername) {
    return;
  }

  const emailChanged = hasEmail && emailsDiffer(incoming.email, existing.email);
  const usernameChanged =
    hasUsername && usernamesDiffer(incoming.username, existing.username);
  if (!emailChanged && !usernameChanged) {
    return;
  }

  const newEmail = hasEmail ? incoming.email : existing.email;
  const newUsername = hasUsername ? incoming.username : existing.username;

  const prev = normalizeHistory(existing.old_data);
  const nextEntry = {
    email: toNullableString(newEmail),
    username: toNullableString(newUsername),
    changedAt: new Date().toISOString(),
  };

  incoming.old_data = [...prev, nextEntry];
}

/**
 * Detects the Flutter/ f7 "soft delete" anonymize payload
 * (Del{timestamp} / Del{timestamp}@schulmatheapp.de).
 */
function isAnonymizeDeletePayload(incoming) {
  if (!incoming || typeof incoming !== "object") {
    return false;
  }
  const u = incoming.username;
  const e = incoming.email;
  if (typeof u !== "string" || typeof e !== "string") {
    return false;
  }
  if (!/^Del\d+$/i.test(u.trim())) {
    return false;
  }
  if (!/^Del\d+@schulmatheapp\.de$/i.test(e.trim())) {
    return false;
  }
  return true;
}

/**
 * Appends a snapshot of the *current* (pre-anonymize) email/username before
 * the row is replaced with Del* placeholders.
 */
function appendPreAnonymizeDeletionToIncoming(existing, incoming) {
  if (!existing || !incoming || typeof incoming !== "object") {
    return;
  }
  if (!isAnonymizeDeletePayload(incoming)) {
    return;
  }
  const prev = normalizeHistory(existing.old_data);
  const nextEntry = {
    email: toNullableString(existing.email),
    username: toNullableString(existing.username),
    changedAt: new Date().toISOString(),
    action: "account_deletion",
  };
  incoming.old_data = [...prev, nextEntry];
}

module.exports = {
  mergeUserIdentityHistoryIntoUpdateData,
  isAnonymizeDeletePayload,
  appendPreAnonymizeDeletionToIncoming,
};
