'use strict';

// Ad strategy by region (ad-regions.js) and the Groq → OpenAI speech-to-text
// switch in ai-tutor.js. The OpenAI SDK is stubbed — no network.

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');

// ── OpenAI SDK stub (records which provider was called) ──────────────────
const calls = [];
let groqFails = false;
class FakeOpenAI {
  constructor(opts) {
    this.opts = opts;
    this.audio = {
      transcriptions: {
        create: async (req) => {
          const provider = opts.baseURL ? 'groq' : 'openai';
          calls.push({ provider, model: req.model, language: req.language, format: req.response_format });
          if (provider === 'groq' && groqFails) {
            const err = new Error('rate limited');
            err.status = 429;
            throw err;
          }
          return { text: 'I went to the market yesterday', duration: 3.2, segments: [] };
        },
      },
    };
  }
}
const openaiPath = require.resolve('openai');
require.cache[openaiPath] = {
  id: openaiPath,
  filename: openaiPath,
  loaded: true,
  exports: Object.assign(FakeOpenAI, {
    // Close the stream right away (the real SDK reads it; nothing to read here).
    // Wait for it to close, so the temp file can be deleted safely.
    toFile: async (stream, name) => {
      await new Promise((resolve) => {
        stream.once('close', resolve);
        stream.destroy();
      });
      return { name };
    },
  }),
};

const { resolveSttConfig, transcribeAudio } = require('../src/utils/ai-tutor');
const {
  DEFAULT_HIGH_VALUE_COUNTRIES,
  isHighValueCountry,
  getAdConfig,
} = require('../src/utils/ad-regions');

const ENV_KEYS = [
  'GROQ_API_KEY', 'OPENAI_API_KEY', 'AI_STT_PROVIDER', 'AI_GROQ_WHISPER_MODEL',
  'AD_HIGH_VALUE_COUNTRIES', 'CONVERSATION_START_AD', 'CONVERSATION_START_AD_COOLDOWN_MINUTES',
  'REWARDED_MINUTES_ENABLED',
];
const saved = Object.fromEntries(ENV_KEYS.map((k) => [k, process.env[k]]));
test.beforeEach(() => {
  for (const k of ENV_KEYS) delete process.env[k];
  calls.length = 0;
  groqFails = false;
});
test.after(() => {
  for (const [k, v] of Object.entries(saved)) {
    if (v === undefined) delete process.env[k];
    else process.env[k] = v;
  }
});

// ── ads by region ─────────────────────────────────────────────────────────

test('Brazil, Turkey, India (and unknown) are low-value; US/EU are high-value', () => {
  for (const c of ['BR', 'TR', 'IN', 'AM', 'MX', 'VN', 'ID']) assert.equal(isHighValueCountry(c), false, c);
  for (const c of ['US', 'GB', 'DE', 'ES', 'JP']) assert.equal(isHighValueCountry(c), true, c);
  assert.equal(isHighValueCountry(''), false);
  assert.equal(isHighValueCountry(null), false);
  assert.equal(isHighValueCountry('us'), true);
});

test('defaults: start ad on (low-value only, 5 min cooldown), rewarded minutes off and high-value only', () => {
  const ads = getAdConfig();
  assert.deepEqual(ads.highValueCountries, DEFAULT_HIGH_VALUE_COUNTRIES);
  assert.deepEqual(ads.conversationStartAd, { enabled: true, lowValueOnly: true, cooldownMinutes: 5 });
  assert.deepEqual(ads.rewardedMinutes, { enabled: false, highValueOnly: true });
});

test('env controls the country list, the start ad and the cooldown', () => {
  process.env.AD_HIGH_VALUE_COUNTRIES = 'us, gb ,xx1, FR';
  process.env.CONVERSATION_START_AD = 'false';
  process.env.CONVERSATION_START_AD_COOLDOWN_MINUTES = '10';
  const ads = getAdConfig();
  assert.deepEqual(ads.highValueCountries, ['US', 'GB', 'FR']);
  assert.equal(ads.conversationStartAd.enabled, false);
  assert.equal(ads.conversationStartAd.cooldownMinutes, 10);
  assert.equal(isHighValueCountry('DE'), false);
});

test('the app receives the ad config inside app-feature-config', () => {
  const { DEFAULT_CONFIG } = require('../src/utils/app-feature-config');
  assert.ok(DEFAULT_CONFIG.ads.highValueCountries.includes('US'));
  assert.equal(DEFAULT_CONFIG.ads.rewardedMinutes.highValueOnly, true);
});

// ── speech-to-text provider ───────────────────────────────────────────────

test('Groq when GROQ_API_KEY is set; OpenAI otherwise or when forced', () => {
  assert.deepEqual(resolveSttConfig({ GROQ_API_KEY: 'g', OPENAI_API_KEY: 'o' }), {
    provider: 'groq',
    apiKey: 'g',
    baseURL: 'https://api.groq.com/openai/v1',
    model: 'whisper-large-v3-turbo',
  });
  assert.equal(resolveSttConfig({ OPENAI_API_KEY: 'o' }).provider, 'openai');
  assert.equal(resolveSttConfig({ GROQ_API_KEY: 'g', AI_STT_PROVIDER: 'openai' }).provider, 'openai');
  assert.equal(resolveSttConfig({ GROQ_API_KEY: 'g', AI_GROQ_WHISPER_MODEL: 'whisper-large-v3' }).model, 'whisper-large-v3');
});

function tempAudio() {
  const file = path.join(os.tmpdir(), `stt-test-${process.pid}-${Date.now()}.m4a`);
  fs.writeFileSync(file, 'fake audio');
  return file;
}

test('transcribeAudio uses Groq with verbose_json and the practice language', async () => {
  process.env.GROQ_API_KEY = 'g';
  process.env.OPENAI_API_KEY = 'o';
  const file = tempAudio();
  try {
    const result = await transcribeAudio(file, 'a.m4a', 'tr');
    assert.equal(result.text, 'I went to the market yesterday');
    assert.equal(result.durationSeconds, 4); // metering floor
    assert.deepEqual(calls, [{ provider: 'groq', model: 'whisper-large-v3-turbo', language: 'tr', format: 'verbose_json' }]);
  } finally {
    fs.unlinkSync(file);
  }
});

test('a Groq failure falls back to OpenAI whisper-1, so the turn still works', async () => {
  process.env.GROQ_API_KEY = 'g';
  process.env.OPENAI_API_KEY = 'o';
  groqFails = true;
  const file = tempAudio();
  try {
    const result = await transcribeAudio(file, 'a.m4a', 'en');
    assert.equal(result.text, 'I went to the market yesterday');
    assert.deepEqual(calls.map((c) => c.provider), ['groq', 'openai']);
    assert.equal(calls[1].model, 'whisper-1');
  } finally {
    fs.unlinkSync(file);
  }
});

test('without GROQ_API_KEY nothing changes: OpenAI whisper-1', async () => {
  process.env.OPENAI_API_KEY = 'o';
  const file = tempAudio();
  try {
    await transcribeAudio(file, 'a.m4a', 'en');
    assert.deepEqual(calls.map((c) => [c.provider, c.model]), [['openai', 'whisper-1']]);
  } finally {
    fs.unlinkSync(file);
  }
});
