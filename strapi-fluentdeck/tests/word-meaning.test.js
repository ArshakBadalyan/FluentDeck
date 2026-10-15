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

test("parseWordMeaningResponse reads the translation line", () => {
  const result = parseWordMeaningResponse(
    "DEFINITION: 最近の出来事を尋ねる表現\nEXAMPLE: 最近の出来事について教えてください。\nTRANSLATION: Расскажите о последних событиях",
  );
  assert.equal(result.definition, "最近の出来事を尋ねる表現");
  assert.equal(result.example, "最近の出来事について教えてください。");
  assert.equal(result.translation, "Расскажите о последних событиях");
});

test("parseWordMeaningResponse leaves translation empty when absent", () => {
  const result = parseWordMeaningResponse("DEFINITION: To greet\nEXAMPLE: Hello there.");
  assert.equal(result.translation, "");
});

test("clampWords caps space-less scripts by characters", () => {
  const long = "あ".repeat(200);
  const clipped = clampWords(long, MAX_DEFINITION_WORDS);
  assert.ok(clipped.length <= 91);
  assert.match(clipped, /…$/);
});
