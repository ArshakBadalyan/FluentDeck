
/*
 *
 * ============================================================
 * WARNING: THIS FILE HAS BEEN COMMENTED OUT
 * ============================================================
 *
 * CONTEXT:
 *
 * The lifecycles.js file has been commented out to prevent unintended side effects when starting Strapi 5 for the first time after migrating to the document service.
 *
 * STRAPI 5 introduces a new document service that handles lifecycles differently compared to previous versions. Without migrating your lifecycles to document service middlewares, you may experience issues such as:
 *
 * - `unpublish` actions triggering `delete` lifecycles for every locale with a published entity, which differs from the expected behavior in v4.
 * - `discardDraft` actions triggering both `create` and `delete` lifecycles, leading to potential confusion.
 *
 * MIGRATION GUIDE:
 *
 * For a thorough guide on migrating your lifecycles to document service middlewares, please refer to the following link:
 * [Document Services Middlewares Migration Guide](https://docs.strapi.io/dev-docs/migration/v4-to-v5/breaking-changes/lifecycle-hooks-document-service)
 *
 * IMPORTANT:
 *
 * Simply uncommenting this file without following the migration guide may result in unexpected behavior and inconsistencies. Ensure that you have completed the migration process before re-enabling this file.
 *
 * ============================================================
 */

// "use strict";
// 
// /**
//  * Update-time identity history is applied in strapi-server.js
//  * (`mergeUserIdentityHistoryIntoUpdateData`) for custom user.update routes
//  * so it matches the real request body.
//  *
//  * This file only seeds the first snapshot for newly created users in afterCreate.
//  * Each item: { email, username, changedAt }.
//  */
// 
// function toNullableString(value) {
//   if (value == null || value === "") {
//     return null;
//   }
//   return String(value).trim();
// }
// 
// module.exports = {
//   async afterCreate(event) {
//     const { result } = event;
//     if (!result?.id) {
//       return;
//     }
//     const firstEntry = {
//       email: toNullableString(result.email),
//       username: toNullableString(result.username),
//       changedAt: new Date().toISOString(),
//     };
//     try {
//       await strapi.entityService.update(
//         "plugin::users-permissions.user",
//         result.id,
//         {
//           data: { old_data: [firstEntry] },
//         }
//       );
//     } catch (err) {
//       strapi.log.error("user old_data afterCreate", err);
//     }
//   },
// };
// 