'use strict';

const fs = require('fs');
const os = require('os');
const path = require('path');
const { importApkgFile } = require('./flashcard-apkg');

const ANKIWEB_BASE = 'https://ankiweb.net';

function parseDeckId(input) {
  const raw = String(input ?? '').trim();
  if (!raw) return null;
  if (/^\d+$/.test(raw)) return raw;
  const match = raw.match(/shared\/info\/(\d+)/i) ?? raw.match(/shared\/download\/(\d+)/i);
  return match?.[1] ?? null;
}

function parseDownloadUrl(input) {
  const raw = String(input ?? '').trim();
  if (!raw) return null;
  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    if (!raw.includes('ankiweb.net/shared/download/')) return null;
    return raw;
  }
  return null;
}

function buildDownloadUrl(deckId, tk) {
  const base = `${ANKIWEB_BASE}/shared/download/${deckId}`;
  return tk ? `${base}?tk=${encodeURIComponent(tk)}` : base;
}

async function fetchApkgBuffer(url, { cookie = '' } = {}) {
  const res = await fetch(url, {
    headers: {
      'User-Agent': 'EnglishApp/1.0 (AnkiWeb shared deck import)',
      Accept: 'application/octet-stream,*/*',
      ...(cookie ? { Cookie: cookie } : {}),
    },
    redirect: 'follow',
  });

  if (!res.ok) {
    throw new Error(`AnkiWeb download failed (${res.status}). Open the deck in a browser, copy the download link (with ?tk=…), and try again.`);
  }

  const contentType = res.headers.get('content-type') ?? '';
  const buf = Buffer.from(await res.arrayBuffer());
  if (buf.length < 4) {
    throw new Error('Downloaded file is empty');
  }
  if (contentType.includes('text/html') || buf[0] === 0x3c) {
    throw new Error('AnkiWeb returned HTML instead of an .apkg file. Paste the full download URL from your browser (includes ?tk= token).');
  }
  return buf;
}

async function loginAnkiWeb(username, password) {
  const body = new URLSearchParams({ username, password });
  const res = await fetch(`${ANKIWEB_BASE}/account/login`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'User-Agent': 'EnglishApp/1.0',
    },
    body: body.toString(),
    redirect: 'manual',
  });

  const setCookie = res.headers.getSetCookie?.() ?? [];
  const cookie = setCookie.map((c) => c.split(';')[0]).join('; ');
  if (!cookie && res.status !== 302 && res.status !== 303) {
    throw new Error('AnkiWeb login failed — check username and password');
  }
  return cookie;
}

async function downloadSharedDeckApkg({ deckId, tk, downloadUrl, cookie }) {
  const url = downloadUrl ?? buildDownloadUrl(deckId, tk);
  return fetchApkgBuffer(url, { cookie });
}

async function importSharedDeck(strapi, userId, options = {}) {
  const deckId = parseDeckId(options.deckId ?? options.url);
  const downloadUrl = parseDownloadUrl(options.downloadUrl ?? options.url);

  if (!deckId && !downloadUrl) {
    throw new Error('Provide a shared deck ID, info URL, or full download URL');
  }

  let cookie = options.sessionCookie ?? '';
  if (options.username && options.password) {
    cookie = await loginAnkiWeb(options.username, options.password);
  }

  const buffer = await downloadSharedDeckApkg({
    deckId,
    tk: options.tk,
    downloadUrl,
    cookie,
  });

  const tmpPath = path.join(os.tmpdir(), `ankiweb-${deckId ?? Date.now()}.apkg`);
  fs.writeFileSync(tmpPath, buffer);
  try {
    return await importApkgFile(strapi, userId, tmpPath, {
      createDecks: options.createDecks !== false,
      defaultDeckId: options.defaultDeckId ?? null,
      importScheduling: options.importScheduling === true,
    });
  } finally {
    try { fs.unlinkSync(tmpPath); } catch (_) { /* ignore */ }
  }
}

/**
 * AnkiWeb shared deck search has no official API (SPA-only since 2024+).
 * Return guidance + optional deck ID if query looks numeric.
 */
function searchSharedDecks(query) {
  const q = String(query ?? '').trim();
  const deckId = parseDeckId(q);
  return {
    query: q,
    apiAvailable: false,
    message:
      'AnkiWeb has no public search API. Browse shared decks at ankiweb.net/shared/decks/ in the app browser, then import by deck ID or paste the download link.',
    suggestedDeckId: deckId,
    browseUrl: q
      ? `${ANKIWEB_BASE}/shared/decks/?search=${encodeURIComponent(q)}&offset=0&order=mod`
      : `${ANKIWEB_BASE}/shared/decks/`,
  };
}

module.exports = {
  parseDeckId,
  parseDownloadUrl,
  buildDownloadUrl,
  loginAnkiWeb,
  downloadSharedDeckApkg,
  importSharedDeck,
  searchSharedDecks,
};
