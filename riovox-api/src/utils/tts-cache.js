'use strict';

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const CACHE_DIR = path.join(process.cwd(), '.tmp', 'tts-cache');
const MAX_ENTRIES = 120;

function cacheKey(text, voice, model) {
  return crypto
    .createHash('sha256')
    .update(`${model}|${voice}|${text.trim()}`)
    .digest('hex');
}

function ensureCacheDir() {
  if (!fs.existsSync(CACHE_DIR)) {
    fs.mkdirSync(CACHE_DIR, { recursive: true });
  }
}

function cacheFilePath(key) {
  return path.join(CACHE_DIR, `${key}.mp3`);
}

function readCachedAudio(text, voice, model) {
  try {
    ensureCacheDir();
    const key = cacheKey(text, voice, model);
    const filePath = cacheFilePath(key);
    if (!fs.existsSync(filePath)) return null;
    fs.utimesSync(filePath, new Date(), new Date());
    return fs.readFileSync(filePath);
  } catch {
    return null;
  }
}

function writeCachedAudio(text, voice, model, buffer) {
  try {
    ensureCacheDir();
    const key = cacheKey(text, voice, model);
    fs.writeFileSync(cacheFilePath(key), buffer);
    pruneCacheIfNeeded();
  } catch {
    // ignore cache write failures
  }
}

function pruneCacheIfNeeded() {
  try {
    const files = fs
      .readdirSync(CACHE_DIR)
      .filter((name) => name.endsWith('.mp3'))
      .map((name) => {
        const filePath = path.join(CACHE_DIR, name);
        const stat = fs.statSync(filePath);
        return { filePath, mtime: stat.mtimeMs };
      })
      .sort((a, b) => b.mtime - a.mtime);

    for (const file of files.slice(MAX_ENTRIES)) {
      fs.unlinkSync(file.filePath);
    }
  } catch {
    // ignore prune failures
  }
}

module.exports = {
  readCachedAudio,
  writeCachedAudio,
};
