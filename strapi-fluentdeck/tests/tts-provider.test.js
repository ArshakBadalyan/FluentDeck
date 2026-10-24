'use strict';

// Text-to-speech routing (ai-tutor.js): Kokoro for the languages it speaks,
// OpenAI tts-1 for the rest and whenever Kokoro fails. SDK and cache stubbed.

const test = require('node:test');
const assert = require('node:assert/strict');
const path = require('path');

const calls = [];
let kokoroFails = false;
class FakeOpenAI {
  constructor(opts = {}) {
    this.audio = {
      speech: {
        create: async (req) => {
          const provider = opts.baseURL ? 'kokoro' : 'openai';
          calls.push({ provider, baseURL: opts.baseURL, ...req });
          if (provider === 'kokoro' && kokoroFails) throw Object.assign(new Error('down'), { status: 503 });
          return { arrayBuffer: async () => Buffer.from(`${provider}:${req.voice}`) };
        },
      },
    };
  }
}
const openaiPath = require.resolve('openai');
require.cache[openaiPath] = {
  id: openaiPath, filename: openaiPath, loaded: true,
  exports: Object.assign(FakeOpenAI, { toFile: async () => ({}) }),
};
const cache = new Map();
const cachePath = require.resolve(path.join('..', 'src', 'utils', 'tts-cache'));
require.cache[cachePath] = {
  id: cachePath, filename: cachePath, loaded: true,
  exports: {
    readCachedAudio: (text, voice, model) => cache.get(`${model}|${voice}|${text}`) ?? null,
    writeCachedAudio: (text, voice, model, buf) => cache.set(`${model}|${voice}|${text}`, buf),
  },
};

const { resolveTtsRoute, synthesizeSpeech, KOKORO_LANGUAGES } = require('../src/utils/ai-tutor');

const KEYS = ['TTS_PROVIDER', 'KOKORO_BASE_URL', 'KOKORO_API_KEY', 'KOKORO_MODEL', 'OPENAI_API_KEY', 'AI_TTS_MODEL'];
const saved = Object.fromEntries(KEYS.map((k) => [k, process.env[k]]));
test.beforeEach(() => {
  for (const k of KEYS) delete process.env[k];
  process.env.OPENAI_API_KEY = 'o';
  calls.length = 0;
  cache.clear();
  kokoroFails = false;
});
test.after(() => {
  for (const [k, v] of Object.entries(saved)) (v === undefined ? delete process.env[k] : (process.env[k] = v));
});

const kokoroEnv = () => {
  process.env.TTS_PROVIDER = 'kokoro';
  process.env.KOKORO_BASE_URL = 'http://localhost:8880/v1';
};

test('Kokoro covers en, es, fr, it, pt, ja, zh, hi', () => {
  assert.deepEqual(Object.keys(KOKORO_LANGUAGES).sort(), ['en', 'es', 'fr', 'hi', 'it', 'ja', 'pt', 'zh']);
});

test('route: Kokoro language + matching gender; others stay on OpenAI', () => {
  const env = { TTS_PROVIDER: 'kokoro', KOKORO_BASE_URL: 'http://k/v1' };
  const r = (language, voicePreference) => resolveTtsRoute({ language, voicePreference, env });
  assert.deepEqual([r('en', 'nova').provider, r('en', 'nova').voice], ['kokoro', 'af_heart']);
  assert.equal(r('en', 'onyx').voice, 'am_michael');
  assert.equal(r('es', 'echo').voice, 'em_alex');
  assert.equal(r('ja', 'shimmer').voice, 'jf_alpha');
  assert.equal(r('en', 'unknown').voice, 'af_heart'); // default tutor voice is female (nova)
  for (const lang of ['ru', 'tr', 'ko', 'ar', 'vi', 'id', 'de', 'hy']) {
    assert.equal(r(lang, 'onyx').provider, 'openai', lang);
    assert.equal(r(lang, 'onyx').voice, 'onyx', lang);
  }
});

test('route: nothing configured → OpenAI tts-1 exactly as before', () => {
  const route = resolveTtsRoute({ language: 'en', voicePreference: 'nova', env: {} });
  assert.deepEqual(route, { provider: 'openai', model: 'tts-1', voice: 'nova' });
  assert.equal(
    resolveTtsRoute({ language: 'en', env: { TTS_PROVIDER: 'kokoro' } }).provider,
    'openai',
    'needs KOKORO_BASE_URL too',
  );
});

test('English goes to Kokoro as mp3', async () => {
  kokoroEnv();
  const audio = await synthesizeSpeech('Hello there', 'nova', 'en');
  assert.equal(audio.toString(), 'kokoro:af_heart');
  assert.equal(calls.length, 1);
  assert.equal(calls[0].baseURL, 'http://localhost:8880/v1');
  assert.equal(calls[0].model, 'kokoro');
  assert.equal(calls[0].response_format, 'mp3');
});

test('Russian goes to OpenAI even with Kokoro on', async () => {
  kokoroEnv();
  const audio = await synthesizeSpeech('Привет', 'onyx', 'ru');
  assert.equal(audio.toString(), 'openai:onyx');
  assert.equal(calls[0].model, 'tts-1');
});

test('a Kokoro failure falls back to OpenAI, so the tutor still speaks', async () => {
  kokoroEnv();
  kokoroFails = true;
  const audio = await synthesizeSpeech('Hello', 'nova', 'en');
  assert.equal(audio.toString(), 'openai:nova');
  assert.deepEqual(calls.map((c) => c.provider), ['kokoro', 'openai']);
});

test('cached audio is reused (no second request); providers cache separately', async () => {
  kokoroEnv();
  await synthesizeSpeech('Same text', 'nova', 'en');
  await synthesizeSpeech('Same text', 'nova', 'en');
  assert.equal(calls.length, 1);
  assert.ok(cache.has('kokoro:kokoro|af_heart|Same text'));

  delete process.env.TTS_PROVIDER;
  await synthesizeSpeech('Same text', 'nova', 'en');
  assert.equal(calls.length, 2); // OpenAI audio is a different cache entry
  assert.ok(cache.has('tts-1|nova|Same text')); // historical OpenAI key unchanged
});
