'use strict';

// Tutor voice routing (ai-tutor.js): our own servers only. Kokoro for its 8
// languages, Piper for de/ru/ar/tr/vi, MeloTTS for Korean; Indonesian and
// Armenian are text only. No paid fallback: a missing or failing server means
// no audio (VoiceUnavailableError). SDK and cache stubbed.

const test = require('node:test');
const assert = require('node:assert/strict');
const path = require('path');

const calls = [];
const failing = new Set();
class FakeOpenAI {
  constructor(opts = {}) {
    this.audio = {
      speech: {
        create: async (req) => {
          const provider = /kokoro/.test(opts.baseURL) ? 'kokoro' : /piper/.test(opts.baseURL) ? 'piper' : /melo/.test(opts.baseURL) ? 'melotts' : 'openai';
          calls.push({ provider, baseURL: opts.baseURL, ...req });
          if (failing.has(provider)) throw Object.assign(new Error('down'), { status: 503 });
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

const {
  resolveTtsRoute,
  synthesizeSpeech,
  hasTutorVoice,
  KOKORO_LANGUAGES,
  PIPER_VOICES,
  MELOTTS_VOICES,
  VOICELESS_LANGUAGES,
} = require('../src/utils/ai-tutor');

const KEYS = ['KOKORO_BASE_URL', 'KOKORO_API_KEY', 'KOKORO_MODEL', 'PIPER_BASE_URL', 'PIPER_MODEL', 'PIPER_VOICES', 'MELOTTS_BASE_URL', 'MELOTTS_MODEL', 'OPENAI_API_KEY'];
const saved = Object.fromEntries(KEYS.map((k) => [k, process.env[k]]));
const allOn = {
  KOKORO_BASE_URL: 'http://kokoro:8880/v1',
  PIPER_BASE_URL: 'http://piper:8000/v1',
  MELOTTS_BASE_URL: 'http://melo:8888/v1',
};
test.beforeEach(() => {
  for (const k of KEYS) delete process.env[k];
  Object.assign(process.env, allOn, { OPENAI_API_KEY: 'o' });
  calls.length = 0;
  cache.clear();
  failing.clear();
});
test.after(() => {
  for (const [k, v] of Object.entries(saved)) (v === undefined ? delete process.env[k] : (process.env[k] = v));
});

const VOICED = ['en', 'es', 'fr', 'it', 'pt', 'ja', 'zh', 'hi', 'de', 'ru', 'ar', 'tr', 'vi', 'ko'];

test('every practice language has a voice server except Indonesian and Armenian', () => {
  assert.deepEqual(Object.keys(KOKORO_LANGUAGES).sort(), ['en', 'es', 'fr', 'hi', 'it', 'ja', 'pt', 'zh']);
  assert.deepEqual(Object.keys(PIPER_VOICES).sort(), ['ar', 'de', 'ru', 'tr', 'vi']);
  assert.deepEqual(Object.keys(MELOTTS_VOICES), ['ko']);
  assert.deepEqual([...VOICELESS_LANGUAGES].sort(), ['hy', 'id']);
  for (const lang of VOICED) assert.ok(hasTutorVoice(lang, allOn), lang);
  for (const lang of ['id', 'hy']) assert.equal(hasTutorVoice(lang, allOn), false, lang);
});

test('route: each language to its server, with the tutor\'s gender', () => {
  const r = (language, voicePreference) => resolveTtsRoute({ language, voicePreference, env: allOn });
  assert.deepEqual([r('en', 'nova').provider, r('en', 'nova').voice], ['kokoro', 'af_heart']);
  assert.equal(r('en', 'onyx').voice, 'am_michael');
  assert.deepEqual([r('de', 'onyx').provider, r('de', 'onyx').voice], ['piper', 'de_DE-thorsten-medium']);
  assert.equal(r('de', 'nova').voice, 'de_DE-kerstin-low');
  assert.equal(r('ru', 'nova').provider, 'piper');
  assert.deepEqual([r('ko', 'nova').provider, r('ko', 'nova').voice], ['melotts', 'KR']);
  assert.equal(r('id', 'nova'), null);
  assert.equal(r('hy', 'nova'), null);
});

test('route: never OpenAI; a server that isn\'t configured means no voice', () => {
  assert.equal(resolveTtsRoute({ language: 'en', env: {} }), null);
  assert.equal(resolveTtsRoute({ language: 'de', env: { KOKORO_BASE_URL: 'http://kokoro/v1' } }), null);
  assert.equal(resolveTtsRoute({ language: 'ko', env: { PIPER_BASE_URL: 'http://piper/v1' } }), null);
});

test('PIPER_VOICES overrides a language\'s voices', () => {
  const env = { ...allOn, PIPER_VOICES: '{"tr":{"f":"tr_TR-x","m":"tr_TR-y"}}' };
  assert.equal(resolveTtsRoute({ language: 'tr', voicePreference: 'nova', env }).voice, 'tr_TR-x');
  assert.equal(resolveTtsRoute({ language: 'de', voicePreference: 'onyx', env }).voice, 'de_DE-thorsten-medium');
});

test('English → Kokoro, German → Piper, Korean → MeloTTS, as mp3', async () => {
  assert.equal((await synthesizeSpeech('Hello', 'nova', 'en')).toString(), 'kokoro:af_heart');
  assert.equal((await synthesizeSpeech('Hallo', 'onyx', 'de')).toString(), 'piper:de_DE-thorsten-medium');
  assert.equal((await synthesizeSpeech('안녕', 'nova', 'ko')).toString(), 'melotts:KR');
  assert.deepEqual(calls.map((c) => c.provider), ['kokoro', 'piper', 'melotts']);
  assert.ok(calls.every((c) => c.response_format === 'mp3'));
});

test('Indonesian and Armenian: no voice, no request at all', async () => {
  for (const lang of ['id', 'hy']) {
    await assert.rejects(synthesizeSpeech('Halo', 'nova', lang), { code: 'VOICE_UNAVAILABLE' });
  }
  assert.equal(calls.length, 0);
});

test('a failing voice server gives text only, never OpenAI', async () => {
  failing.add('kokoro');
  await assert.rejects(synthesizeSpeech('Hello', 'nova', 'en'), { code: 'VOICE_UNAVAILABLE' });
  assert.deepEqual(calls.map((c) => c.provider), ['kokoro']);
});

test('cached audio is reused; each server caches separately', async () => {
  await synthesizeSpeech('Same text', 'nova', 'en');
  await synthesizeSpeech('Same text', 'nova', 'en');
  assert.equal(calls.length, 1);
  assert.ok(cache.has('kokoro:kokoro|af_heart|Same text'));
});
