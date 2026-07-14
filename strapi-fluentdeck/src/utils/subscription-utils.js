"use strict";

const fs = require("fs");
const path = require("path");
const { JWT } = require("google-auth-library");
const {
  SignedDataVerifier,
  Environment: AppleEnvironment,
} = require("@apple/app-store-server-library");

const APPLE_VERIFY_RECEIPT_PRODUCTION = "https://buy.itunes.apple.com/verifyReceipt";
const APPLE_VERIFY_RECEIPT_SANDBOX = "https://sandbox.itunes.apple.com/verifyReceipt";
const APPLE_SANDBOX_STATUS = 21007;
const APPLE_ROOT_CA_PATH = path.join(__dirname, "certs", "AppleRootCA-G3.cer");

const SUBSCRIPTION_UID = "api::subscription.subscription";

/** Active/grace period + not yet expired = premium. Cancelled users keep access until period end. */
function computeIsPremiumFromSubscription(subscription) {
  if (!subscription) return false;
  const periodEnd = subscription.currentPeriodEnd
    ? new Date(subscription.currentPeriodEnd)
    : null;
  if (!periodEnd || periodEnd.getTime() <= Date.now()) return false;
  return ["active", "grace_period", "billing_retry", "cancelled"].includes(
    subscription.subscriptionStatus,
  );
}

async function getUserSubscription(strapi, userId) {
  return strapi.db.query(SUBSCRIPTION_UID).findOne({ where: { user: userId } });
}

/** Creates or updates the user's single subscription row (one row per user — latest state, not a full ledger). */
async function upsertSubscription(strapi, userId, data) {
  const existing = await getUserSubscription(strapi, userId);
  const payload = {
    user: userId,
    platform: data.platform,
    productId: data.productId,
    originalTransactionId: data.originalTransactionId ?? null,
    purchaseToken: data.purchaseToken ?? null,
    subscriptionStatus: data.subscriptionStatus,
    currentPeriodEnd: data.currentPeriodEnd,
    autoRenewing: data.autoRenewing ?? true,
    lastVerifiedAt: new Date().toISOString(),
    lastEventPayload: data.rawPayload ?? null,
  };
  if (data.dailyConversationTurns != null) {
    payload.dailyConversationTurns = data.dailyConversationTurns;
  }

  if (existing) {
    return strapi.db.query(SUBSCRIPTION_UID).update({
      where: { id: existing.id },
      data: payload,
    });
  }
  return strapi.db.query(SUBSCRIPTION_UID).create({ data: payload });
}

/**
 * Verifies an Apple App Store receipt via the (legacy but still supported)
 * verifyReceipt endpoint. Requires APPLE_SHARED_SECRET (App Store Connect ->
 * your app -> App Information -> App-Specific Shared Secret) and
 * APPLE_BUNDLE_ID (your app's bundle identifier) in env.
 *
 * Tries production first, retries against sandbox on Apple's documented
 * 21007 "this receipt is from the test environment" status.
 */
async function verifyAppleReceipt({ receiptData }) {
  const sharedSecret = process.env.APPLE_SHARED_SECRET;
  const bundleId = process.env.APPLE_BUNDLE_ID;
  if (!sharedSecret || !bundleId) {
    throw new Error(
      "Apple verification not configured: set APPLE_SHARED_SECRET and APPLE_BUNDLE_ID in .env",
    );
  }
  if (!receiptData) {
    throw new Error("receiptData is required");
  }

  const callVerify = async (url) => {
    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        "receipt-data": receiptData,
        password: sharedSecret,
        "exclude-old-transactions": true,
      }),
    });
    return res.json();
  };

  let result = await callVerify(APPLE_VERIFY_RECEIPT_PRODUCTION);
  if (result.status === APPLE_SANDBOX_STATUS) {
    result = await callVerify(APPLE_VERIFY_RECEIPT_SANDBOX);
  }

  if (result.status !== 0) {
    throw new Error(`Apple receipt verification failed (status ${result.status})`);
  }

  const latestReceiptInfo = Array.isArray(result.latest_receipt_info)
    ? result.latest_receipt_info
    : [];
  const latest = latestReceiptInfo
    .filter((entry) => entry.bundle_id === bundleId || !entry.bundle_id)
    .sort((a, b) => Number(b.expires_date_ms) - Number(a.expires_date_ms))[0];

  if (!latest) {
    throw new Error("No subscription transaction found in Apple receipt");
  }

  const pendingRenewal = Array.isArray(result.pending_renewal_info)
    ? result.pending_renewal_info.find(
        (entry) => entry.original_transaction_id === latest.original_transaction_id,
      )
    : null;

  return {
    productId: latest.product_id,
    originalTransactionId: latest.original_transaction_id,
    currentPeriodEnd: new Date(Number(latest.expires_date_ms)).toISOString(),
    autoRenewing: pendingRenewal ? pendingRenewal.auto_renew_status === "1" : true,
    rawPayload: result,
  };
}

let _googleJwtClient = null;
function getGoogleJwtClient() {
  if (_googleJwtClient) return _googleJwtClient;

  const rawCredentials = process.env.GOOGLE_SERVICE_ACCOUNT_JSON;
  if (!rawCredentials) {
    throw new Error(
      "Google verification not configured: set GOOGLE_SERVICE_ACCOUNT_JSON in .env " +
        "(paste the full service account JSON key as a single-line string)",
    );
  }

  const credentials = JSON.parse(rawCredentials);
  _googleJwtClient = new JWT({
    email: credentials.client_email,
    key: credentials.private_key,
    scopes: ["https://www.googleapis.com/auth/androidpublisher"],
  });
  return _googleJwtClient;
}

/**
 * Verifies a Google Play subscription purchase via the Android Publisher API.
 * Requires GOOGLE_SERVICE_ACCOUNT_JSON and GOOGLE_PLAY_PACKAGE_NAME in env,
 * and the service account must be granted access in Play Console -> API access.
 */
async function verifyGoogleSubscription({ productId, purchaseToken }) {
  const packageName = process.env.GOOGLE_PLAY_PACKAGE_NAME;
  if (!packageName) {
    throw new Error("Google verification not configured: set GOOGLE_PLAY_PACKAGE_NAME in .env");
  }
  if (!productId || !purchaseToken) {
    throw new Error("productId and purchaseToken are required");
  }

  const client = getGoogleJwtClient();
  const url =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/` +
    `${encodeURIComponent(packageName)}/purchases/subscriptions/` +
    `${encodeURIComponent(productId)}/tokens/${encodeURIComponent(purchaseToken)}`;

  const res = await client.request({ url });
  const data = res.data;

  // paymentState: 0 pending, 1 received, 2 free trial, 3 pending deferred upgrade/downgrade
  const status = data.cancelReason != null ? "cancelled" : "active";

  return {
    productId,
    purchaseToken,
    currentPeriodEnd: new Date(Number(data.expiryTimeMillis)).toISOString(),
    autoRenewing: data.autoRenewing === true,
    status,
    rawPayload: data,
  };
}

let _appleVerifier = null;

/** Lazily builds the App Store Server Notifications verifier (needs APPLE_BUNDLE_ID; APPLE_APP_APPLE_ID required in production). */
function getAppleVerifier() {
  if (_appleVerifier) return _appleVerifier;

  const bundleId = process.env.APPLE_BUNDLE_ID;
  if (!bundleId) {
    throw new Error(
      "Apple webhook verification not configured: set APPLE_BUNDLE_ID in .env",
    );
  }
  const environment =
    process.env.APPLE_ENVIRONMENT === "production"
      ? AppleEnvironment.PRODUCTION
      : AppleEnvironment.SANDBOX;
  const appAppleId = process.env.APPLE_APP_APPLE_ID
    ? Number(process.env.APPLE_APP_APPLE_ID)
    : undefined;
  const rootCert = fs.readFileSync(APPLE_ROOT_CA_PATH);

  _appleVerifier = new SignedDataVerifier([rootCert], true, environment, bundleId, appAppleId);
  return _appleVerifier;
}

/**
 * Verifies and decodes an App Store Server Notification V2 payload (the JWS
 * `signedPayload` Apple POSTs to our webhook). Throws if the signature/certificate
 * chain doesn't check out — never trust an unverified payload.
 */
async function verifyAppleServerNotification(signedPayload) {
  const verifier = getAppleVerifier();
  const notification = await verifier.verifyAndDecodeNotification(signedPayload);

  const signedTransactionInfo = notification.data?.signedTransactionInfo;
  const signedRenewalInfo = notification.data?.signedRenewalInfo;

  const transaction = signedTransactionInfo
    ? await verifier.verifyAndDecodeTransaction(signedTransactionInfo)
    : null;
  const renewalInfo = signedRenewalInfo
    ? await verifier.verifyAndDecodeRenewalInfo(signedRenewalInfo)
    : null;

  return { notification, transaction, renewalInfo };
}

/**
 * Derives our status enum from Apple's ground-truth transaction/renewal state
 * rather than trying to enumerate every one of Apple's ~20 notification types.
 */
function mapAppleStatus({ notificationType, transaction, renewalInfo }) {
  if (["REFUND", "REVOKE"].includes(notificationType)) return "cancelled";
  if (!transaction?.expiresDate) return "active";

  if (transaction.expiresDate <= Date.now()) return "expired";
  if (renewalInfo?.isInBillingRetryPeriod) return "billing_retry";
  if (notificationType === "DID_FAIL_TO_RENEW") return "grace_period";
  return "active";
}

async function updateSubscriptionByOriginalTransactionId(strapi, originalTransactionId, data) {
  const existing = await strapi.db.query(SUBSCRIPTION_UID).findOne({
    where: { originalTransactionId },
  });
  if (!existing) return null;
  return strapi.db.query(SUBSCRIPTION_UID).update({
    where: { id: existing.id },
    data,
  });
}

/** Verifies the shared token Google Pub/Sub push appends as `?token=` on the webhook URL. */
function verifyGooglePubSubToken(ctx) {
  const expected = process.env.GOOGLE_PUBSUB_WEBHOOK_TOKEN;
  if (!expected) {
    throw new Error(
      "Google webhook verification not configured: set GOOGLE_PUBSUB_WEBHOOK_TOKEN in .env",
    );
  }
  return ctx.query?.token === expected;
}

/** Decodes the base64 JSON body of a Google Play Real-Time Developer Notification Pub/Sub push. */
function decodeGooglePubSubMessage(ctx) {
  const dataB64 = ctx.request.body?.message?.data;
  if (!dataB64) {
    throw new Error("Missing Pub/Sub message data");
  }
  return JSON.parse(Buffer.from(dataB64, "base64").toString("utf8"));
}

async function updateSubscriptionByPurchaseToken(strapi, purchaseToken, data) {
  const existing = await strapi.db.query(SUBSCRIPTION_UID).findOne({
    where: { purchaseToken },
  });
  if (!existing) return null;
  return strapi.db.query(SUBSCRIPTION_UID).update({
    where: { id: existing.id },
    data,
  });
}

/** Cron-callable: flips anything past its period end that's still marked active/grace_period. */
async function expireStaleSubscriptions(strapi) {
  const now = new Date().toISOString();
  const stale = await strapi.db.query(SUBSCRIPTION_UID).findMany({
    where: {
      subscriptionStatus: { $in: ["active", "grace_period", "billing_retry"] },
      currentPeriodEnd: { $lt: now },
    },
  });

  for (const sub of stale) {
    await strapi.db.query(SUBSCRIPTION_UID).update({
      where: { id: sub.id },
      data: { subscriptionStatus: "expired" },
    });
  }

  return { expired: stale.length };
}

module.exports = {
  computeIsPremiumFromSubscription,
  getUserSubscription,
  upsertSubscription,
  verifyAppleReceipt,
  verifyGoogleSubscription,
  expireStaleSubscriptions,
  verifyAppleServerNotification,
  mapAppleStatus,
  updateSubscriptionByOriginalTransactionId,
  verifyGooglePubSubToken,
  decodeGooglePubSubMessage,
  updateSubscriptionByPurchaseToken,
};
