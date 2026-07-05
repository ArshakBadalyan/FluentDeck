/**
 * Scheduled tasks for FluentDeck.
 *
 * Legacy MatheApp crons (parent digests, math goals, classroom reports) were
 * removed — those content types and tables are no longer part of this API.
 *
 * Set CRON_ENABLED=true in .env only after adding FluentDeck-specific jobs here.
 */
module.exports = {
  /** Safety net for missed renewal/cancellation webhooks — flips anything
   * past its currentPeriodEnd that's still marked active/grace_period/billing_retry. */
  expireStaleSubscriptions: {
    task: async ({ strapi }) => {
      const { expireStaleSubscriptions } = require("../src/utils/subscription-utils");
      try {
        const result = await expireStaleSubscriptions(strapi);
        if (result.expired > 0) {
          strapi.log.info(`[cron] Expired ${result.expired} stale subscription(s).`);
        }
      } catch (e) {
        strapi.log.error("[cron] expireStaleSubscriptions failed", e);
      }
    },
    options: {
      rule: "0 3 * * *", // daily at 03:00 server time
    },
  },

  /** Push a "time to practice" notification to users at their chosen local
   * time (dailyReminderEnabled/-Time on the profile), via OneSignal. Runs
   * every 5 minutes and de-dupes per user per local day. */
  sendDailyReminders: {
    task: async ({ strapi }) => {
      const { sendDailyReminders } = require("../src/utils/daily-reminder");
      try {
        const result = await sendDailyReminders(strapi);
        if (result.sent > 0) {
          strapi.log.info(`[cron] Sent ${result.sent} daily reminder(s).`);
        }
      } catch (e) {
        strapi.log.error("[cron] sendDailyReminders failed", e);
      }
    },
    options: {
      rule: "*/5 * * * *", // every 5 minutes
    },
  },
};
