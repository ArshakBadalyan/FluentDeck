'use strict';

// The AI speaking language lists ("Your language", "Tutor response language",
// "Translation language") must agree between the server validation, the user
// schema enums and the Flutter app, and cover every app interface language.

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');

const {
  PRACTICE_LANGUAGE_CODES,
  RESPONSE_LANGUAGE_CODES,
  TRANSLATION_LANGUAGE_CODES,
  whisperLanguageCode,
  practiceLanguageLabel,
} = require('../src/utils/practice-languages');

const app = path.join(__dirname, '..', '..', 'fluentdeck-f', 'lib');
const prefsDart = fs.readFileSync(path.join(app, 'models', 'speaking_preferences.dart'), 'utf8');
const appLanguageDart = fs.readFileSync(path.join(app, 'config', 'app_language.dart'), 'utf8');
const schema = JSON.parse(
  fs.readFileSync(
    path.join(__dirname, '..', 'src', 'extensions', 'users-permissions', 'content-types', 'user', 'schema.json'),
    'utf8',
  ),
).attributes;

/** Keys of a `static const <name> = { 'xx': ... }` map in the Dart file. */
function dartMapKeys(name) {
  const start = prefsDart.indexOf(`static const ${name} = {`);
  assert.ok(start >= 0, `${name} not found`);
  const body = prefsDart.slice(start, prefsDart.indexOf('};', start));
  return [...body.matchAll(/'([a-z]{2,4})':/g)].map((m) => m[1]);
}

const sorted = (list) => [...list].sort();

test('server validation = user schema enums', () => {
  assert.deepEqual(sorted(schema.practice_language.enum), sorted(PRACTICE_LANGUAGE_CODES));
  assert.deepEqual(sorted(schema.response_language.enum), sorted(RESPONSE_LANGUAGE_CODES));
  assert.deepEqual(sorted(schema.translation_language.enum), sorted(TRANSLATION_LANGUAGE_CODES));
});

test('app pickers offer exactly what the server accepts', () => {
  assert.deepEqual(sorted(dartMapKeys('practiceLanguageOptions')), sorted(PRACTICE_LANGUAGE_CODES));
  assert.deepEqual(sorted(dartMapKeys('responseLanguageOptions')), sorted(RESPONSE_LANGUAGE_CODES));
  assert.deepEqual(sorted(dartMapKeys('translationLanguageOptions')), sorted(TRANSLATION_LANGUAGE_CODES));
});

test('every app interface language works for all three speaking settings', () => {
  const appLanguages = [...appLanguageDart.matchAll(/AppLanguageOption\('([a-z]{2})'/g)].map((m) => m[1]);
  assert.ok(appLanguages.length >= 11);
  for (const code of appLanguages) {
    assert.ok(PRACTICE_LANGUAGE_CODES.includes(code), `practice: ${code}`);
    assert.ok(RESPONSE_LANGUAGE_CODES.includes(code), `tutor response: ${code}`);
    assert.ok(TRANSLATION_LANGUAGE_CODES.includes(code), `translation: ${code}`);
  }
});

test('new practice languages have speech-to-text codes and tutor labels', () => {
  const tutor = fs.readFileSync(path.join(__dirname, '..', 'src', 'utils', 'ai-tutor.js'), 'utf8');
  for (const [code, label] of [
    ['tr', 'Turkish'],
    ['ko', 'Korean'],
    ['ar', 'Arabic'],
    ['vi', 'Vietnamese'],
    ['id', 'Indonesian'],
  ]) {
    assert.equal(whisperLanguageCode(code), code);
    assert.equal(practiceLanguageLabel(code), label);
    assert.match(tutor, new RegExp(`\\b${code}: "${label}"`), `ai-tutor label ${code}`);
  }
});

test('Armenian: practice + tutor + translation, but not an app language', () => {
  assert.ok(PRACTICE_LANGUAGE_CODES.includes('hy'));
  assert.ok(RESPONSE_LANGUAGE_CODES.includes('hy'));
  assert.ok(TRANSLATION_LANGUAGE_CODES.includes('hy'));
  assert.equal(whisperLanguageCode('hy'), 'hy');
  assert.equal(practiceLanguageLabel('hy'), 'Armenian');
  assert.doesNotMatch(appLanguageDart, /AppLanguageOption\('hy'/);
});

test('translation list: Off first, no duplicates, keeps Ukrainian', () => {
  assert.equal(TRANSLATION_LANGUAGE_CODES[0], 'none');
  assert.equal(new Set(TRANSLATION_LANGUAGE_CODES).size, TRANSLATION_LANGUAGE_CODES.length);
  assert.ok(TRANSLATION_LANGUAGE_CODES.includes('uk'));
  assert.ok(!PRACTICE_LANGUAGE_CODES.includes('uk'));
});
