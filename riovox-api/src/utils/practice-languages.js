'use strict';

const PRACTICE_LANGUAGES = {
  en: { label: 'English', whisper: 'en' },
  es: { label: 'Spanish', whisper: 'es' },
  fr: { label: 'French', whisper: 'fr' },
  de: { label: 'German', whisper: 'de' },
  it: { label: 'Italian', whisper: 'it' },
  pt: { label: 'Portuguese', whisper: 'pt' },
  zh: { label: 'Mandarin Chinese', whisper: 'zh' },
  ja: { label: 'Japanese', whisper: 'ja' },
  ru: { label: 'Russian', whisper: 'ru' },
  hi: { label: 'Hindi', whisper: 'hi' },
  // Added with the app's interface languages (docs/app-languages.md).
  tr: { label: 'Turkish', whisper: 'tr' },
  ko: { label: 'Korean', whisper: 'ko' },
  ar: { label: 'Arabic', whisper: 'ar' },
  vi: { label: 'Vietnamese', whisper: 'vi' },
  id: { label: 'Indonesian', whisper: 'id' },
  // Practice + tutor language only — not an app (interface) language yet.
  hy: { label: 'Armenian', whisper: 'hy' },
};

const PRACTICE_LANGUAGE_CODES = Object.keys(PRACTICE_LANGUAGES);

/** Languages the tutor can reply in: every practice language. */
const RESPONSE_LANGUAGE_CODES = PRACTICE_LANGUAGE_CODES;

/**
 * Tap-to-translate targets: 'none', every practice language, plus
 * translate-only languages (no speaking practice in them yet).
 */
const TRANSLATE_ONLY_CODES = ['uk'];
const TRANSLATION_LANGUAGE_CODES = ['none', ...PRACTICE_LANGUAGE_CODES, ...TRANSLATE_ONLY_CODES];

function normalizePracticeLanguage(code) {
  const key = String(code ?? 'en').trim().toLowerCase();
  return PRACTICE_LANGUAGE_CODES.includes(key) ? key : 'en';
}

function practiceLanguageLabel(code) {
  return PRACTICE_LANGUAGES[normalizePracticeLanguage(code)]?.label ?? 'English';
}

function whisperLanguageCode(code) {
  return PRACTICE_LANGUAGES[normalizePracticeLanguage(code)]?.whisper ?? 'en';
}

module.exports = {
  PRACTICE_LANGUAGES,
  PRACTICE_LANGUAGE_CODES,
  RESPONSE_LANGUAGE_CODES,
  TRANSLATION_LANGUAGE_CODES,
  normalizePracticeLanguage,
  practiceLanguageLabel,
  whisperLanguageCode,
};
