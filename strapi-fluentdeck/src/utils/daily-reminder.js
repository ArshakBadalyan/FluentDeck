const { sendPushToUser } = require("./onesignal");

/** Minutes since local midnight, for a given IANA timezone. */
function minutesSinceMidnight(date, timeZone) {
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone,
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
  }).formatToParts(date);
  const hour = Number(parts.find((p) => p.type === "hour").value);
  const minute = Number(parts.find((p) => p.type === "minute").value);
  return hour * 60 + minute;
}

/** Local calendar date (YYYY-MM-DD) for a given IANA timezone. */
function localDateKey(date, timeZone) {
  return new Intl.DateTimeFormat("en-CA", { timeZone }).format(date);
}

function parseHHmm(value) {
  const [h, m] = (value || "09:00").split(":").map((n) => Number(n));
  return (Number.isFinite(h) ? h : 9) * 60 + (Number.isFinite(m) ? m : 0);
}

/**
 * Finds users whose daily reminder time just came up (within the last
 * `windowMinutes`, matching the cron interval) in their own timezone, and
 * haven't already been sent one today, then pushes via OneSignal.
 */
async function sendDailyReminders(strapi, { now = new Date(), windowMinutes = 5 } = {}) {
  const users = await strapi.db.query("plugin::users-permissions.user").findMany({
    where: {
      daily_reminder_enabled: true,
      push_subscribed: true,
      blocked: false,
    },
    select: [
      "id",
      "user_timezone",
      "daily_reminder_time",
      "daily_reminder_last_sent_date",
    ],
  });

  let sent = 0;
  for (const user of users) {
    const timeZone = user.user_timezone || "UTC";
    let nowMinutes;
    let todayKey;
    try {
      nowMinutes = minutesSinceMidnight(now, timeZone);
      todayKey = localDateKey(now, timeZone);
    } catch (e) {
      continue;
    }

    if (user.daily_reminder_last_sent_date === todayKey) continue;

    const reminderMinutes = parseHHmm(user.daily_reminder_time);
    const dueSinceMidnight = nowMinutes - reminderMinutes;
    if (dueSinceMidnight < 0 || dueSinceMidnight >= windowMinutes) continue;

    try {
      await sendPushToUser(user.id, {
        headings: { en: "Time to practice" },
        contents: { en: "Your daily FluentDeck session is waiting." },
        data: { type: "daily_reminder" },
      });
      await strapi.db.query("plugin::users-permissions.user").update({
        where: { id: user.id },
        data: { daily_reminder_last_sent_date: todayKey },
      });
      sent += 1;
    } catch (e) {
      strapi.log.error(`[daily-reminder] Failed to notify user ${user.id}`, e);
    }
  }

  return { checked: users.length, sent };
}

module.exports = { sendDailyReminders, minutesSinceMidnight, localDateKey, parseHHmm };
