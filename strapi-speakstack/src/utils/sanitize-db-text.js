"use strict";

/**
 * Strip characters PostgreSQL UTF-8 text columns reject (e.g. NUL 0x00).
 */
function sanitizeDbText(text) {
  if (text == null) {
    return "";
  }

  const withoutNulls = String(text).replace(/\0/g, "");
  const withoutControls = withoutNulls.replace(
    /[\x01-\x08\x0B\x0C\x0E-\x1F\x7F]/g,
    ""
  );

  return Buffer.from(withoutControls, "utf8")
    .toString("utf8")
    .replace(/\uFFFD/g, "")
    .trim();
}

module.exports = {
  sanitizeDbText,
};
