"use strict";

/**
 * Update-time identity history is applied in strapi-server.js
 * (`mergeUserIdentityHistoryIntoUpdateData`) for custom user.update routes
 * so it matches the real request body.
 *
 * This file only seeds the first snapshot for newly created users in afterCreate.
 * Each item: { email, username, changedAt }.
 */

function toNullableString(value) {
  if (value == null || value === "") {
    return null;
  }
  return String(value).trim();
}

module.exports = {
  async afterCreate(event) {
    const { result } = event;
    if (!result?.id) {
      return;
    }
    const firstEntry = {
      email: toNullableString(result.email),
      username: toNullableString(result.username),
      changedAt: new Date().toISOString(),
    };
    try {
      await strapi.entityService.update(
        "plugin::users-permissions.user",
        result.id,
        {
          data: { old_data: [firstEntry] },
        }
      );
    } catch (err) {
      strapi.log.error("user old_data afterCreate", err);
    }
  },
};
