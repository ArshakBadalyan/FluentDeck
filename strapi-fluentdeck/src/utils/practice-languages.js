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
};

const PRACTICE_LANGUAGE_CODES = Object.keys(PRACTICE_LANGUAGES);

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
  normalizePracticeLanguage,
  practiceLanguageLabel,
  whisperLanguageCode,
};
