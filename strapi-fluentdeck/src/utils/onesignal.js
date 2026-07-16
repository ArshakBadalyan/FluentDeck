const axios = require("axios");

/**
 * Send a template-based push notification to a user via OneSignal.
 */
async function sendTemplateNotification(
  externalUserId,
  templateId,
  customData = {}
) {
  const response = await axios.post(
    "https://api.onesignal.com/notifications",
    {
      app_id: process.env.ONESIGNAL_APP_ID,
      template_id: templateId,
      include_aliases: { external_id: [externalUserId.toString()] },
      target_channel: "push",
      custom_data: customData,
    },
    {
      headers: {
        Authorization: `Key ${process.env.ONESIGNAL_REST_API_KEY}`,
        "Content-Type": "application/json",
      },
    }
  );

  return response.data;
}

/**
 * Send a direct push (headings + contents) when no template is configured.
 */
async function sendPushToUser(externalUserId, { headings, contents, data } = {}) {
  const response = await axios.post(
    "https://api.onesignal.com/notifications",
    {
      app_id: process.env.ONESIGNAL_APP_ID,
      include_aliases: { external_id: [externalUserId.toString()] },
      target_channel: "push",
      headings,
      contents,
      data: data ?? {},
    },
    {
      headers: {
        Authorization: `Key ${process.env.ONESIGNAL_REST_API_KEY}`,
        "Content-Type": "application/json",
      },
    }
  );

  return response.data;
}

module.exports = { sendTemplateNotification, sendPushToUser };
