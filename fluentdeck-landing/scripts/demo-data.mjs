// Seeds a realistic demo learner on a LOCAL FluentDeck API, for capturing
// landing-page screenshots / GIFs from the real app (see README "Real app
// captures"). Never point this at production.
//
//   API_URL=http://localhost:1338/api node scripts/demo-data.mjs
//
// Credentials are generated once and kept in assets-src/.demo-account.json
// (git-ignored), so re-runs sign in instead of registering again.
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const API = (process.env.API_URL || 'http://localhost:1338/api').replace(/\/+$/, '');
const ACCOUNT_FILE = path.join(root, 'assets-src', '.demo-account.json');

if (!/localhost|127\.0\.0\.1/.test(API)) {
  console.error(`Refusing to seed a non-local API: ${API}`);
  process.exit(1);
}

// Ana, a B1 learner from Spain preparing for job interviews in English.
const PERSONA = { username: 'ana.martin', email: 'ana.martin@fluentdeck.test' };

const DECK = {
  name: 'Job interview English',
  description: 'Phrases for answering interview questions with confidence.',
};

const CARDS = [
  ['Tell me about yourself.', 'Give a 60-second answer: your current role, one key strength, and why you want this job.'],
  ["I'm responsible for …", "Describe your duties: “I'm responsible for onboarding new clients.”"],
  ['to meet a deadline', "To finish work on time: “We met every deadline during the launch.”"],
  ['to get along with', "To have a good relationship: “I get along well with my team.”"],
  ['What is your greatest strength?', "Pick one strength and prove it: “I'm a quick learner — I learned SQL in two months.”"],
  ['a notice period', 'The time you must work after resigning: “My notice period is one month.”'],
  ['salary expectations', "What you hope to earn: “I'm looking for something in the range of …”"],
  ['to be in charge of', "To lead or manage: “I was in charge of a team of four.”"],
  ['I look forward to hearing from you.', 'A polite way to end an email after an interview.'],
  ['It went well.', "Past tense of “go”: “The interview went well.” (not “it go well”)"],
  ['a weakness', "Be honest and show progress: “I used to avoid public speaking, so I joined a speaking club.”"],
  ['Why do you want to work here?', 'Connect the company to your goals: mention its product, values, or growth.'],
];

async function call(method, route, body, token) {
  const res = await fetch(`${API}${route}`, {
    method,
    headers: {
      'content-type': 'application/json',
      ...(token ? { authorization: `Bearer ${token}` } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let data;
  try { data = text ? JSON.parse(text) : {}; } catch { data = { raw: text }; }
  if (!res.ok) {
    const msg = data?.error?.message || res.statusText;
    throw Object.assign(new Error(`${method} ${route} → ${res.status} ${msg}`), { status: res.status, data });
  }
  return data;
}

function loadAccount() {
  if (fs.existsSync(ACCOUNT_FILE)) return JSON.parse(fs.readFileSync(ACCOUNT_FILE, 'utf8'));
  const account = { ...PERSONA, password: crypto.randomBytes(15).toString('base64url'), seeded: false };
  fs.writeFileSync(ACCOUNT_FILE, JSON.stringify(account, null, 2) + '\n', { mode: 0o600 });
  return account;
}

async function signIn(account) {
  try {
    const r = await call('POST', '/auth/local/register', {
      username: account.username,
      email: account.email,
      password: account.password,
    });
    console.log('Registered demo learner', account.username);
    return r.jwt;
  } catch (err) {
    if (err.status !== 400) throw err; // already exists → sign in
    const r = await call('POST', '/auth/local', { identifier: account.email, password: account.password });
    console.log('Signed in as', account.username);
    return r.jwt;
  }
}

const account = loadAccount();
const jwt = await signIn(account);

await call('PUT', '/users/me/speaking-preferences', {
  practice_language: 'en',
  english_level: 'B1',
  type_messages_enabled: true,
  auto_save_corrections: true,
  correct_sentence_goal: 10,
  tutor_voice: 'nova',
  auto_play_voice: false, // captures don't need audio; saves TTS cost
}, jwt);

if (account.seeded) {
  console.log('Decks already seeded — nothing else to do.');
  process.exit(0);
}

const decks = await call('GET', '/flashcards/decks', null, jwt);
const list = Array.isArray(decks) ? decks : decks.data ?? decks.decks ?? [];
let deck = list.find((d) => d.name === DECK.name);
if (!deck) {
  const created = await call('POST', '/flashcards/decks', DECK, jwt);
  deck = created.data ?? created.deck ?? created;
  console.log('Created deck', DECK.name);
}

const cardIds = [];
for (const [front, back] of CARDS) {
  const r = await call('POST', '/flashcards/notes', {
    deckId: deck.id,
    noteType: 'basic',
    fields: { Front: front, Back: back },
    tags: ['job-interview'],
    languageCode: 'en',
  }, jwt);
  const cards = r.cards ?? r.data?.cards ?? [];
  for (const c of cards) if (c?.id) cardIds.push(c.id);
}
console.log(`Added ${CARDS.length} notes (${cardIds.length} cards)`);

// Study a few, like a real first session: mostly Good, one Again.
const ratings = ['good', 'good', 'easy', 'again', 'good', 'hard'];
let reviewed = 0;
for (const [i, rating] of ratings.entries()) {
  const id = cardIds[i];
  if (!id) break;
  try {
    await call('POST', '/flashcards/review/answer', { flashcardId: id, rating, durationMs: 4000 + i * 900 }, jwt);
    reviewed++;
  } catch (err) {
    console.warn('review skipped:', err.message);
  }
}
console.log(`Reviewed ${reviewed} cards`);

account.seeded = true;
fs.writeFileSync(ACCOUNT_FILE, JSON.stringify(account, null, 2) + '\n', { mode: 0o600 });
console.log('Done. Demo account details: assets-src/.demo-account.json');
