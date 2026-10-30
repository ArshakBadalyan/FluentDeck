"use strict";

/**
 * Removes outer LaTeX/MathJax inline math delimiters \( ... \) so stored fields
 * are raw TeX (the Flutter/f7 renderers already wrap for display).
 * Repeats while the whole string is wrapped (handles nested duplicate wrapping).
 *
 * @param {unknown} value
 * @returns {string}
 */
function stripMathInlineDelimiters(value) {
  if (value == null) {
    return "";
  }
  let s = String(value).trim();
  while (s.startsWith("\\(") && s.endsWith("\\)")) {
    s = s.slice(2, -2).trim();
  }
  return s;
}

/**
 * @param {unknown} arr
 * @returns {string[]}
 */
function stripMathInlineDelimitersList(arr) {
  if (!Array.isArray(arr)) {
    return [];
  }
  return arr.map((x) => stripMathInlineDelimiters(x));
}

module.exports = {
  stripMathInlineDelimiters,
  stripMathInlineDelimitersList,
};
