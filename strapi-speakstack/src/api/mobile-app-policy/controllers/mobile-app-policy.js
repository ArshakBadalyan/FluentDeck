"use strict";

const { createCoreController } = require("@strapi/strapi").factories;

module.exports = createCoreController(
  "api::mobile-app-policy.mobile-app-policy",
  ({ strapi }) => ({
    /**
     * Public JSON for Flutter native clients. Auth disabled in route config.
     * Build numbers align with Flutter `pubspec.yaml` +N suffix (Android versionCode / iOS CFBundleVersion).
     */
    async publicPolicy(ctx) {
      const rows = await strapi.db
        .query("api::mobile-app-policy.mobile-app-policy")
        .findMany({
          where: { publishedAt: { $notNull: true } },
          limit: 1,
        });
      const entry = rows[0];

      const empty = {
        forceMinimumAndroidBuild: 0,
        forceMinimumIosBuild: 0,
        softSuggestBelowAndroidBuild: 0,
        softSuggestBelowIosBuild: 0,
        softCampaignId: "",
        softMessage: "",
        androidStoreUrl: "",
        iosStoreUrl: "",
      };

      if (!entry) {
        ctx.body = empty;
        return;
      }

      // db.query() rows use schema attribute names (camelCase); do not rely on SQL column snake_case keys.
      const pickInt = (snakeKey, camelKey) => {
        const raw = entry[snakeKey] ?? entry[camelKey];
        if (raw === null || raw === undefined || raw === "") return 0;
        const n = typeof raw === "number" ? raw : parseInt(String(raw), 10);
        return Number.isFinite(n) ? n : 0;
      };
      const pickStr = (snakeKey, camelKey) => {
        const raw = entry[snakeKey] ?? entry[camelKey];
        if (raw === null || raw === undefined) return "";
        return String(raw);
      };

      ctx.body = {
        forceMinimumAndroidBuild: pickInt(
          "force_minimum_android_build",
          "forceMinimumAndroidBuild"
        ),
        forceMinimumIosBuild: pickInt(
          "force_minimum_ios_build",
          "forceMinimumIosBuild"
        ),
        softSuggestBelowAndroidBuild: pickInt(
          "soft_suggest_below_android_build",
          "softSuggestBelowAndroidBuild"
        ),
        softSuggestBelowIosBuild: pickInt(
          "soft_suggest_below_ios_build",
          "softSuggestBelowIosBuild"
        ),
        softCampaignId: pickStr("soft_campaign_id", "softCampaignId"),
        softMessage: pickStr("soft_message", "softMessage"),
        androidStoreUrl: pickStr("android_store_url", "androidStoreUrl"),
        iosStoreUrl: pickStr("ios_store_url", "iosStoreUrl"),
      };
    },
  })
);
