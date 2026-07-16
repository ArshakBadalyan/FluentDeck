"use strict";

module.exports = {
  routes: [
    {
      method: "GET",
      path: "/subscriptions/plans",
      handler: "subscription.plans",
      config: {
        auth: false,
      },
    },
    {
      method: "GET",
      path: "/subscriptions/status",
      handler: "subscription.status",
    },
    {
      method: "POST",
      path: "/subscriptions/verify-apple",
      handler: "subscription.verifyApple",
    },
    {
      method: "POST",
      path: "/subscriptions/verify-google",
      handler: "subscription.verifyGoogle",
    },
    {
      method: "POST",
      path: "/subscriptions/webhooks/apple",
      handler: "subscription.appleWebhook",
      config: {
        auth: false,
      },
    },
    {
      method: "POST",
      path: "/subscriptions/webhooks/google",
      handler: "subscription.googleWebhook",
      config: {
        auth: false,
      },
    },
  ],
};
