"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {
  parseWordMeaningResponse,
  clampWords,
  MAX_DEFINITION_WORDS,
} = require("../src/utils/word-meaning");

test("parseWordMeaningResponse extracts deck-style lines", () => {
  const result = parseWordMeaningResponse(
    "DEFINITION: To start a friendly conversation\nEXAMPLE: She told a joke to break the ice.",
  );
  assert.equal(result.definition, "To start a friendly conversation");
  assert.equal(result.example, "She told a joke to break the ice.");
});

test("clampWords limits long definitions", () => {
  const long =
    "one two three four five six seven eight nine ten eleven twelve thirteen fourteen";
  const clipped = clampWords(long, MAX_DEFINITION_WORDS);
  assert.equal(clipped.split(" ").length, MAX_DEFINITION_WORDS);
  assert.match(clipped, /\.$/);
});
