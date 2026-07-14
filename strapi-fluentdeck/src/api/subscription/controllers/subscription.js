"use strict";

const { createCoreController } = require("@strapi/strapi").factories;
const {
  computeIsPremiumFromSubscription,
  getUserSubscription,
  upsertSubscription,
  verifyAppleReceipt,
  verifyGoogleSubscription,
  verifyAppleServerNotification,
  mapAppleStatus,
  updateSubscriptionByOriginalTransactionId,
  verifyGooglePubSubToken,
  decodeGooglePubSubMessage,
  updateSubscriptionByPurchaseToken,
} = require("../../../utils/subscription-utils");

async function getAuthenticatedUserId(ctx, strapi) {
  const token = await strapi.plugins["users-permissions"].services.jwt.getToken(ctx);
  return token?.id ?? null;
}

function formatSubscription(sub) {
  if (!sub) return null;
  return {
    platform: sub.platform,
    productId: sub.productId,
    status: sub.subscriptionStatus,
    currentPeriodEnd: sub.currentPeriodEnd,
    autoRenewing: sub.autoRenewing,
    dailyConversationTurns: sub.dailyConversationTurns ?? null,
  };
}

module.exports = createCoreController("api::subscription.subscription", ({ strapi }) => ({
  /** Public marketing plans (duration + fallback price) from env. */
  async plans(ctx) {
    const {
      getSubscriptionPlans,
      getSubscriptionPlansForDailyTurns,
      getDailyTurnsSliderConfig,
      clampDailyConversationTurns,
    } = require("../../../utils/subscription-plans");
    const slider = getDailyTurnsSliderConfig();
    const requested = ctx.query?.dailyTurns ?? ctx.query?.dailyConversationTurns;
    const dailyTurns = requested != null
      ? clampDailyConversationTurns(requested)
      : slider.default;
    ctx.body = {
      slider,
      dailyConversationTurns: dailyTurns,
      plans: getSubscriptionPlansForDailyTurns(dailyTurns),
      basePlans: getSubscriptionPlans(),
    };
  },

  async status(ctx) {
    const userId = await getAuthenticatedUserId(ctx, strapi);
    if (!userId) return ctx.unauthorized("Authentication required");

    const sub = await getUserSubscription(strapi, userId);
    ctx.body = {
      isPremium: computeIsPremiumFromSubscription(sub),
      subscription: formatSubscription(sub),
    };
  },

  async verifyApple(ctx) {
    const userId = await getAuthenticatedUserId(ctx, strapi);
    if (!userId) return ctx.unauthorized("Authentication required");

    const { receiptData, dailyConversationTurns } = ctx.request.body ?? {};
    if (!receiptData) return ctx.badRequest("receiptData is required");

    try {
      const { clampDailyConversationTurns } = require("../../../utils/subscription-plans");
      const verified = await verifyAppleReceipt({ receiptData });
      const sub = await upsertSubscription(strapi, userId, {
        platform: "ios",
        productId: verified.productId,
        originalTransactionId: verified.originalTransactionId,
        subscriptionStatus: "active",
        currentPeriodEnd: verified.currentPeriodEnd,
        autoRenewing: verified.autoRenewing,
        dailyConversationTurns: clampDailyConversationTurns(
          dailyConversationTurns,
        ),
        rawPayload: verified.rawPayload,
      });
      ctx.body = {
        ok: true,
        isPremium: computeIsPremiumFromSubscription(sub),
        subscription: formatSubscription(sub),
      };
    } catch (error) {
      strapi.log.error("[subscription.verifyApple]", error);
      return ctx.badRequest(error.message || "Could not verify Apple receipt");
    }
  },

  async verifyGoogle(ctx) {
    const userId = await getAuthenticatedUserId(ctx, strapi);
    if (!userId) return ctx.unauthorized("Authentication required");

    const { productId, purchaseToken, dailyConversationTurns } =
      ctx.request.body ?? {};
    if (!productId || !purchaseToken) {
      return ctx.badRequest("productId and purchaseToken are required");
    }

    try {
      const { clampDailyConversationTurns } = require("../../../utils/subscription-plans");
      const verified = await verifyGoogleSubscription({ productId, purchaseToken });
      const sub = await upsertSubscription(strapi, userId, {
        platform: "android",
        productId: verified.productId,
        purchaseToken: verified.purchaseToken,
        subscriptionStatus: verified.status,
        currentPeriodEnd: verified.currentPeriodEnd,
        autoRenewing: verified.autoRenewing,
        dailyConversationTurns: clampDailyConversationTurns(
          dailyConversationTurns,
        ),
        rawPayload: verified.rawPayload,
      });
      ctx.body = {
        ok: true,
        isPremium: computeIsPremiumFromSubscription(sub),
        subscription: formatSubscription(sub),
      };
    } catch (error) {
      strapi.log.error("[subscription.verifyGoogle]", error);
      return ctx.badRequest(error.message || "Could not verify Google Play purchase");
    }
  },

  /** Apple App Store Server Notifications V2 — keeps subscriptionStatus in sync with
   * real cancellations/renewals/refunds that happen outside the app (App Store Connect ->
   * your app -> App Information -> App Store Server Notifications -> Production/Sandbox URL). */
  async appleWebhook(ctx) {
    const { signedPayload } = ctx.request.body ?? {};
    if (!signedPayload) return ctx.badRequest("Missing signedPayload");

    let verified;
    try {
      verified = await verifyAppleServerNotification(signedPayload);
    } catch (error) {
      strapi.log.warn(`[subscription.appleWebhook] verification failed: ${error.message}`);
      return ctx.badRequest("Invalid notification");
    }

    const { notification, transaction, renewalInfo } = verified;
    const originalTransactionId = transaction?.originalTransactionId;

    if (!originalTransactionId) {
      strapi.log.info(
        `[subscription.appleWebhook] ${notification.notificationType} without transaction info — ignored`,
      );
      ctx.body = { ok: true };
      return;
    }

    const subscriptionStatus = mapAppleStatus({
      notificationType: notification.notificationType,
      transaction,
      renewalInfo,
    });

    const updated = await updateSubscriptionByOriginalTransactionId(strapi, originalTransactionId, {
      productId: transaction.productId,
      subscriptionStatus,
      currentPeriodEnd: new Date(transaction.expiresDate).toISOString(),
      autoRenewing: renewalInfo ? renewalInfo.autoRenewStatus === 1 : undefined,
      lastVerifiedAt: new Date().toISOString(),
      lastEventPayload: notification,
    });

    if (!updated) {
      strapi.log.info(
        `[subscription.appleWebhook] no local subscription for originalTransactionId ${originalTransactionId} (${notification.notificationType})`,
      );
    }

    ctx.body = { ok: true };
  },

  /** Google Play Real-Time Developer Notifications (Cloud Pub/Sub push). Configure a push
   * subscription in GCP pointing at /subscriptions/webhooks/google?token=GOOGLE_PUBSUB_WEBHOOK_TOKEN.
   * Re-verifies against the Android Publisher API rather than trusting the notification's own
   * fields, since the notification only tells us *that* something changed, not the new state. */
  async googleWebhook(ctx) {
    let tokenOk = false;
    try {
      tokenOk = verifyGooglePubSubToken(ctx);
    } catch (error) {
      strapi.log.error(`[subscription.googleWebhook] ${error.message}`);
      return ctx.internalServerError("Google webhook not configured");
    }
    if (!tokenOk) return ctx.unauthorized("Invalid token");

    let payload;
    try {
      payload = decodeGooglePubSubMessage(ctx);
    } catch (error) {
      return ctx.badRequest(error.message);
    }

    const notif = payload.subscriptionNotification;
    if (!notif) {
      ctx.body = { ok: true };
      return;
    }

    try {
      const verifiedSub = await verifyGoogleSubscription({
        productId: notif.subscriptionId,
        purchaseToken: notif.purchaseToken,
      });
      const updated = await updateSubscriptionByPurchaseToken(strapi, notif.purchaseToken, {
        productId: verifiedSub.productId,
        subscriptionStatus: verifiedSub.status,
        currentPeriodEnd: verifiedSub.currentPeriodEnd,
        autoRenewing: verifiedSub.autoRenewing,
        lastVerifiedAt: new Date().toISOString(),
        lastEventPayload: verifiedSub.rawPayload,
      });
      if (!updated) {
        strapi.log.info(
          `[subscription.googleWebhook] no local subscription for this purchaseToken (notificationType ${notif.notificationType})`,
        );
      }
    } catch (error) {
      strapi.log.error("[subscription.googleWebhook] re-verification failed", error);
    }

    ctx.body = { ok: true };
  },
}));
