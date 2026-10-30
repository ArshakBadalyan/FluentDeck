'use strict';

// Daily practice reminder cron (config/cron-tasks.js → sendDailyReminders):
// who gets a push, when, and that it's sent at most once per local day.
// OneSignal is stubbed via require.cache; users live in a tiny in-memory db.

const test = require('node:test');
const assert = require('node:assert/strict');
const path = require('path');

const pushes = [];
let pushFails = false;

const onesignal = require.resolve(path.join('../src/utils/onesignal'));
require.cache[onesignal] = {
  id: onesignal,
  filename: onesignal,
  loaded: true,
  exports: {
    sendPushToUser: async (userId, payload) => {
      if (pushFails) throw new Error('OneSignal down');
      pushes.push({ userId, ...payload });
    },
  },
};

const {
  sendDailyReminders,
  minutesSinceMidnight,
  localDateKey,
  parseHHmm,
} = require('../src/utils/daily-reminder');

function makeStrapi(users) {
  const rows = users.map((u, i) => ({
    id: i + 1,
    daily_reminder_enabled: true,
    push_subscribed: true,
    blocked: false,
    user_timezone: 'UTC',
    daily_reminder_time: '09:00',
    daily_reminder_last_sent_date: null,
    ...u,
  }));
  const matches = (row, where = {}) => Object.entries(where).every(([k, v]) => row[k] === v);
  return {
    rows,
    log: { error: () => {} },
    db: {
      query: () => ({
        findMany: async ({ where }) => rows.filter((r) => matches(r, where)),
        update: async ({ where, data }) => Object.assign(rows.find((r) => r.id === where.id), data),
      }),
    },
  };
}

test.beforeEach(() => {
  pushes.length = 0;
  pushFails = false;
});

// ── helpers ────────────────────────────────────────────────────────────

test('parseHHmm reads HH:MM and falls back to 09:00', () => {
  assert.equal(parseHHmm('07:30'), 450);
  assert.equal(parseHHmm('00:00'), 0);
  assert.equal(parseHHmm(null), 540);
  assert.equal(parseHHmm('xx'), 540);
});

test('local time and date follow the user time zone', () => {
  const now = new Date('2026-10-23T21:30:00Z');
  assert.equal(minutesSinceMidnight(now, 'UTC'), 21 * 60 + 30);
  assert.equal(minutesSinceMidnight(now, 'Asia/Yerevan'), 1 * 60 + 30); // UTC+4
  assert.equal(localDateKey(now, 'UTC'), '2026-10-23');
  assert.equal(localDateKey(now, 'Asia/Yerevan'), '2026-10-24');
});

// ── who gets a push and when ───────────────────────────────────────────

test('sends at the chosen time and records the local day', async () => {
  const strapi = makeStrapi([{ daily_reminder_time: '09:00' }]);
  const result = await sendDailyReminders(strapi, { now: new Date('2026-10-23T09:00:00Z') });

  assert.deepEqual(result, { checked: 1, sent: 1 });
  assert.equal(pushes[0].userId, 1);
  assert.equal(pushes[0].headings.en, 'Time to practice');
  assert.deepEqual(pushes[0].data, { type: 'daily_reminder' });
  assert.equal(strapi.rows[0].daily_reminder_last_sent_date, '2026-10-23');
});

test('within the 5-minute window it still sends; outside it does not', async () => {
  const at = (iso) => sendDailyReminders(makeStrapi([{ daily_reminder_time: '09:00' }]), { now: new Date(iso) });
  assert.equal((await at('2026-10-23T09:04:00Z')).sent, 1);
  assert.equal((await at('2026-10-23T09:05:00Z')).sent, 0);
  assert.equal((await at('2026-10-23T08:59:00Z')).sent, 0);
});

test('a reminder that is not on a 5-minute mark is caught by the next run', async () => {
  const strapi = makeStrapi([{ daily_reminder_time: '09:03' }]);
  const result = await sendDailyReminders(strapi, { now: new Date('2026-10-23T09:05:00Z') });
  assert.equal(result.sent, 1);
});

test('uses the user time zone, not server time', async () => {
  // 09:00 in Yerevan (UTC+4) is 05:00 UTC.
  const strapi = makeStrapi([{ user_timezone: 'Asia/Yerevan', daily_reminder_time: '09:00' }]);
  assert.equal((await sendDailyReminders(strapi, { now: new Date('2026-10-23T09:00:00Z') })).sent, 0);
  assert.equal((await sendDailyReminders(strapi, { now: new Date('2026-10-23T05:00:00Z') })).sent, 1);
});

test('no time zone → UTC; unknown time zone → skipped, not crashed', async () => {
  const strapi = makeStrapi([
    { user_timezone: null },
    { user_timezone: 'Not/AZone' },
  ]);
  const result = await sendDailyReminders(strapi, { now: new Date('2026-10-23T09:00:00Z') });
  assert.deepEqual(result, { checked: 2, sent: 1 });
  assert.equal(pushes[0].userId, 1);
});

test('only once per local day, even if the cron runs again in the window', async () => {
  const strapi = makeStrapi([{ daily_reminder_time: '09:00' }]);
  await sendDailyReminders(strapi, { now: new Date('2026-10-23T09:00:00Z') });
  await sendDailyReminders(strapi, { now: new Date('2026-10-23T09:03:00Z') });
  assert.equal(pushes.length, 1);
  // Next day it sends again.
  await sendDailyReminders(strapi, { now: new Date('2026-10-24T09:00:00Z') });
  assert.equal(pushes.length, 2);
});

test('reminders just before midnight are sent by the run after midnight', async () => {
  const strapi = makeStrapi([{ daily_reminder_time: '23:58' }]);
  const result = await sendDailyReminders(strapi, { now: new Date('2026-10-24T00:00:00Z') });
  assert.equal(result.sent, 1);
  // ...and it doesn't then fire twice around the next midnight.
  await sendDailyReminders(strapi, { now: new Date('2026-10-24T23:55:00Z') });
  assert.equal(pushes.length, 1);
  await sendDailyReminders(strapi, { now: new Date('2026-10-25T00:00:00Z') });
  assert.equal(pushes.length, 2);
});

test('skips users who turned reminders off, have no push, or are blocked', async () => {
  const strapi = makeStrapi([
    { daily_reminder_enabled: false },
    { push_subscribed: false },
    { blocked: true },
    { blocked: null }, // never set → not blocked
  ]);
  const result = await sendDailyReminders(strapi, { now: new Date('2026-10-23T09:00:00Z') });
  assert.equal(result.sent, 1);
  assert.equal(pushes[0].userId, 4);
});

test('a failed push is not recorded, so the next run retries', async () => {
  const strapi = makeStrapi([{ daily_reminder_time: '09:00' }]);
  pushFails = true;
  assert.equal((await sendDailyReminders(strapi, { now: new Date('2026-10-23T09:00:00Z') })).sent, 0);
  assert.equal(strapi.rows[0].daily_reminder_last_sent_date, null);
  pushFails = false;
  assert.equal((await sendDailyReminders(strapi, { now: new Date('2026-10-23T09:03:00Z') })).sent, 1);
});

// ── cron wiring ────────────────────────────────────────────────────────

test('cron task runs every 5 minutes, matching the send window', () => {
  const tasks = require('../config/cron-tasks');
  assert.equal(tasks.sendDailyReminders.options.rule, '*/5 * * * *');
});

test('cron is off unless CRON_ENABLED is set', () => {
  const config = require('../config/server');
  const env = (key, fallback) => process.env[key] ?? fallback;
  env.int = (key, fallback) => Number(process.env[key] ?? fallback);
  env.bool = (key, fallback) => (process.env[key] == null ? fallback : process.env[key] === 'true');
  env.array = () => [];

  const saved = process.env.CRON_ENABLED;
  delete process.env.CRON_ENABLED;
  assert.equal(config({ env }).cron.enabled, false);
  process.env.CRON_ENABLED = 'true';
  assert.equal(config({ env }).cron.enabled, true);
  if (saved == null) delete process.env.CRON_ENABLED;
  else process.env.CRON_ENABLED = saved;
});
