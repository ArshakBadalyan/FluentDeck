'use strict';

// scripts/translate-app-locales.js: the pure helpers (no OpenAI calls) and
// that its language list matches the app's AppLanguage.options.

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const {
  LANGUAGES,
  flatten,
  unflattenLike,
  keepsPlaceholders,
  keysToTranslate,
  matchesScript,
  chunk,
  parseArgs,
  systemPrompt,
} = require('../scripts/translate-app-locales');

const source = {
  buttons: { save: 'Save', cancel: 'Cancel' },
  steps: ['First', 'Then {n} more'],
  greeting: 'Hi {name}, {count} cards due',
};

test('flatten / unflattenLike round-trip keeps shape and key order', () => {
  const flat = flatten(source);
  assert.deepEqual(Object.keys(flat), [
    'buttons.save',
    'buttons.cancel',
    'steps.0',
    'steps.1',
    'greeting',
  ]);
  assert.deepEqual(unflattenLike(source, flat), source);
});

test('unflattenLike leaves out keys that were not translated', () => {
  const partial = { 'buttons.save': 'Guardar', 'steps.0': 'Primero' };
  // A half-translated list is left out entirely (the app uses English's).
  assert.deepEqual(unflattenLike(source, partial), {
    buttons: { save: 'Guardar' },
  });
});

test('keepsPlaceholders rejects lost, renamed or extra placeholders and empties', () => {
  assert.equal(keepsPlaceholders('Hi {name}, {count} due', '{count} pendientes, hola {name}'), true);
  assert.equal(keepsPlaceholders('Hi {name}', 'Hola'), false);
  assert.equal(keepsPlaceholders('Hi {name}', 'Hola {nombre}'), false);
  assert.equal(keepsPlaceholders('Hi', 'Hola {name}'), false);
  assert.equal(keepsPlaceholders('Hi', '  '), false);
  assert.equal(keepsPlaceholders('Hi', undefined), false);
});

test('only missing keys are sent, unless --all', () => {
  const src = flatten(source);
  const target = { 'buttons.save': 'Guardar' };
  assert.deepEqual(keysToTranslate(src, target), [
    'buttons.cancel',
    'steps.0',
    'steps.1',
    'greeting',
  ]);
  assert.equal(keysToTranslate(src, target, { all: true }).length, 5);
});

test('matchesScript: right letters, no stray Chinese, short codes pass', () => {
  assert.equal(matchesScript('hy', 'Save', 'Պահպանել'), true);
  assert.equal(matchesScript('hy', 'Save', 'Save'), false); // left in English
  assert.equal(matchesScript('ru', 'Save', 'Сохранить'), true);
  assert.equal(matchesScript('ar', 'Save', 'حفظ'), true);
  assert.equal(matchesScript('es', 'Save', 'Guardar'), true);
  assert.equal(matchesScript('es', 'Save', 'Guardar 保存'), false); // Qwen slip
  assert.equal(matchesScript('ja', 'Save', '保存'), true);
  assert.equal(matchesScript('ko', 'Save', '저장'), true);
  assert.equal(matchesScript('hy', 'A1', 'A1'), true); // no words to translate
  assert.equal(matchesScript('hy', '{count}', '{count}'), true);
});

test('--local defaults to Ollama + qwen2.5:14b with small batches', () => {
  const local = parseArgs(['--local']);
  assert.equal(local.baseUrl, 'http://localhost:11434/v1');
  assert.equal(local.model, 'qwen2.5:14b');
  assert.equal(local.batch, 20);
  const cloud = parseArgs([]);
  assert.equal(cloud.baseUrl, null);
  assert.equal(cloud.model, 'gpt-4.1');
  assert.equal(cloud.batch, 120);
  assert.equal(parseArgs(['--local', '--batch=10', '--limit=5']).batch, 10);
});

test('chunk splits into batches', () => {
  assert.deepEqual(chunk([1, 2, 3, 4, 5], 2), [[1, 2], [3, 4], [5]]);
});

test('parseArgs reads flags and rejects unknown languages', () => {
  const args = parseArgs(['--dry-run', '--langs=es,ar', '--model=gpt-4.1-mini']);
  assert.equal(args.dryRun, true);
  assert.deepEqual(args.langs, ['es', 'ar']);
  assert.equal(args.model, 'gpt-4.1-mini');
  assert.throws(() => parseArgs(['--langs=xx']), /Unknown language/);
  // Armenian is planned for later, not translated yet.
  assert.throws(() => parseArgs(['--langs=hy']), /Unknown language/);
});

test('prompt protects placeholders and brand names', () => {
  const prompt = systemPrompt('ar');
  assert.match(prompt, /Arabic/);
  assert.match(prompt, /\{placeholder\}/);
  assert.match(prompt, /Riovox/);
});

test('script languages = app languages (AppLanguage.options minus English)', () => {
  const dart = fs.readFileSync(
    path.join(__dirname, '..', '..', 'fluentdeck-f', 'lib', 'config', 'app_language.dart'),
    'utf8',
  );
  const appCodes = [...dart.matchAll(/AppLanguageOption\('([a-z]{2})'/g)].map((m) => m[1]);
  assert.deepEqual(
    appCodes.filter((c) => c !== 'en').sort(),
    Object.keys(LANGUAGES).sort(),
  );
});

test('--dry-run works without an API key and calls nothing', () => {
  const out = execFileSync(process.execPath, ['scripts/translate-app-locales.js', '--dry-run'], {
    cwd: path.join(__dirname, '..'),
    env: { ...process.env, OPENAI_API_KEY: '' },
    encoding: 'utf8',
  });
  assert.match(out, /es \(Spanish\): \d+ to translate/);
  assert.match(out, /ar \(Arabic\): \d+ to translate/);
  assert.doesNotMatch(out, /Armenian/);
});
