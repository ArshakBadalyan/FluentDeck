const cronTasks = require("./cron-tasks");

module.exports = ({ env }) => ({
  host: env("HOST", "0.0.0.0"),
  port: env.int("PORT", 1337),
  cron: {
    enabled: env.bool("CRON_ENABLED", false),
    tasks: cronTasks,
  },
  app: {
    keys: env.array("APP_KEYS"),
  },
  webhooks: {
    // Add this to not receive populated relations in webhooks
    populateRelations: false,
  },
});
