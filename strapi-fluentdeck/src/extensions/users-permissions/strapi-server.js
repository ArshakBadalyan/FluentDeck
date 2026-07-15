const _ = require("lodash");
const utils = require("@strapi/utils");
const {
  getAbsoluteAdminUrl,
  getAbsoluteServerUrl,
  contentTypes: { getNonWritableAttributes },
} = utils;
const { ApplicationError, ForbiddenError } = utils.errors;
const i18n = require("../../i18n-helper");

i18n.init();

const jwt = require("jsonwebtoken");

const sanitizeUser = async (user, ctx) => {
  const { auth } = ctx.state;
  const userSchema = strapi.getModel("plugin::users-permissions.user");
  return strapi.contentAPI.sanitize.output(user, userSchema, { auth });
};

// validation
const { yup, validateYupSchema } = require("@strapi/utils");
const {
  validateForgotPasswordBody,
} = require("../../../node_modules/@strapi/plugin-users-permissions/server/controllers/validation/auth");
const crypto = require("crypto");
const { getService } = require("../../../node_modules/@strapi/plugin-users-permissions/server/utils");
const { filterObjectByKeys } = require("../../utils/filter-object-by-keys");
const { isAdmin } = require("../../utils/is-admin");
const {
  mergeUserIdentityHistoryIntoUpdateData,
  appendPreAnonymizeDeletionToIncoming,
  isAnonymizeDeletePayload,
} = require("../../utils/user-identity-history");
const {
  findUserById,
  updateByNumericId,
  deleteByNumericId,
} = require("../../utils/document-service");
const plugins = require("../../../config/plugins");
const {
  verifyAppleIdentityToken,
  resolveAppleAudiences,
  findOrCreateAppleUser,
} = require("../../utils/apple-sign-in");
const {
  verifyGoogleIdToken,
  resolveGoogleAudiences,
  findOrCreateGoogleUser,
} = require("../../utils/google-sign-in");
const {
  getOrIncrementDailyCorrectCount,
} = require("../../utils/speaking-stats-utils");

const USER_RESPONSE_EXCLUDED_KEYS = [
  "confirmationToken",
  "password",
  "resetPasswordToken",
  "old_data",
];

function clampAutoStartRecordingDelay(raw) {
  const n = Number(raw);
  if (!Number.isFinite(n)) return 2;
  return Math.min(10, Math.max(0, Math.round(n)));
}

const registerBodySchema = yup.object().shape({
  username: yup.string().required(),
  password: yup.string().required(),
  email: yup.string().email().notRequired(),
});

const validateLocalRegisterBody = validateYupSchema(registerBodySchema);

module.exports = (plugin) => {
  const originalAuthFactory = plugin.controllers.auth;
  plugin.controllers.auth = (factoryArgs) => {
    const auth = originalAuthFactory(factoryArgs);
    return {
      ...auth,
      register: async (ctx) => {
    const pluginStore = await strapi.store({
      type: "plugin",
      name: "users-permissions",
    });
    const settings = await pluginStore.get({ key: "advanced" });

    if (!settings.allow_register) {
      throw new ApplicationError(i18n.__("errors.register-action-disabled"));
    }

    const { register } = strapi.config.get("plugin::users-permissions");
    const alwaysAllowedKeys = ["username", "password", "email"];
    const userModel = strapi.contentTypes["plugin::users-permissions.user"];
    const { attributes } = userModel;
    const nonWritable = getNonWritableAttributes(userModel);

    const allowedKeys = _.compact(
      _.concat(
        alwaysAllowedKeys,
        _.isArray(register?.allowedFields)
          ? register.allowedFields
          : Object.keys(attributes).filter(
              (key) =>
                !nonWritable.includes(key) &&
                !attributes[key].private &&
                ![
                  "confirmed",
                  "blocked",
                  "confirmationToken",
                  "resetPasswordToken",
                  "provider",
                  "id",
                  "role",
                  "createdAt",
                  "updatedAt",
                  "createdBy",
                  "updatedBy",
                  "publishedAt",
                  "strapi_reviewWorkflows_stage",
                ].includes(key)
            )
      )
    );

    const params = {
      ..._.pick(ctx.request.body, allowedKeys),
      provider: "local",
    };

    await validateLocalRegisterBody(params);

    const role = await strapi
      .query("plugin::users-permissions.role")
      .findOne({ where: { type: settings.default_role } });

    if (!role) {
      throw new ApplicationError(i18n.__("errors.find-default-role"));
    }

    const { email, username, provider } = params;
    const emailNorm = email ? email.toLowerCase() : null;

    // Email is optional; only enforce uniqueness when one was provided.
    if (emailNorm) {
      const emailWhere = settings.unique_email
        ? { email: emailNorm }
        : { email: emailNorm, provider };

      const emailTaken = await strapi
        .query("plugin::users-permissions.user")
        .count({ where: emailWhere });

      if (emailTaken > 0) {
        throw new ApplicationError(
          i18n.__("errors.register-email-or-nickname-taken")
        );
      }
    }

    const usernameTaken = await strapi
      .query("plugin::users-permissions.user")
      .count({
        where: {
          provider,
          username: { $eqi: username },
        },
      });

    if (usernameTaken > 0) {
      throw new ApplicationError(
        i18n.__("errors.register-email-or-nickname-taken")
      );
    }

    const registerPayload = _.pick(params, allowedKeys);

    const newUser = {
      ...registerPayload,
      role: role.id,
      ...(emailNorm ? { email: emailNorm } : {}),
      username,
      provider,
      confirmed: emailNorm ? !settings.email_confirmation : true,
    };

    const user = await getService("user").add(newUser);

    try {
      const { ensureUserDefaultDecks } = require("../../../utils/flashcard-auto-create");
      const { getOrCreateUserProgress } = require("../../../utils/user-progress-utils");
      await ensureUserDefaultDecks(strapi, user.id);
      await getOrCreateUserProgress(strapi, user.id);
    } catch (err) {
      strapi.log.error("[auth.register] default deck/progress seed failed", err);
    }

    const sanitizedUser = await sanitizeUser(user, ctx);

    if (settings.email_confirmation && emailNorm) {
      try {
        await getService("user").sendConfirmationEmail(sanitizedUser);
      } catch (err) {
        throw new ApplicationError(err.message);
      }
      return ctx.send({ user: sanitizedUser });
    }

    const token = getService("jwt").issue(_.pick(user, ["id"]));
    return ctx.send({
      jwt: token,
      user: sanitizedUser,
    });
      },
      forgotPassword: async (ctx) => {
    const { email } = await validateForgotPasswordBody(ctx.request.body);

    const pluginStore = await strapi.store({
      type: "plugin",
      name: "users-permissions",
    });

    const emailSettings = await pluginStore.get({ key: "email" });
    const advancedSettings = await pluginStore.get({ key: "advanced" });

    // Find the user by email.
    const user = await strapi
      .query("plugin::users-permissions.user")
      .findOne({ where: { email: email.toLowerCase() } });

    if (!user || user.blocked) {
      return ctx.send({ ok: true });
    }

    // Generate random token.
    const userInfo = await sanitizeUser(user, ctx);

    const resetPasswordToken = crypto.randomBytes(4).toString("hex");

    const resetPasswordSettings = _.get(
      emailSettings,
      "reset_password.options",
      {}
    );
    resetPasswordSettings.message = `
      <p>${i18n.__("forgot-password.we-heard")}</p>

      <p>${i18n.__("forgot-password.dont-worry")}</p>
      <br>
      <p><%= TOKEN %></p>
      <br>
      <p>${i18n.__("basic.thanks")}.</p>
    `;

    const emailBody = await getService("users-permissions").template(
      resetPasswordSettings.message,
      {
        URL: advancedSettings.email_reset_password,
        SERVER_URL: getAbsoluteServerUrl(strapi.config),
        ADMIN_URL: getAbsoluteAdminUrl(strapi.config),
        USER: userInfo,
        TOKEN: resetPasswordToken,
      }
    );

    const emailObject = await getService("users-permissions").template(
      resetPasswordSettings.object,
      {
        USER: userInfo,
      }
    );

    const emailToSend = {
      to: user.email,
      from: process.env.SMTP_USERNAME
        ? `"${i18n.__("daily-report.sender")}" <${process.env.SMTP_USERNAME}>`
        : plugins.email.config.settings.defaultFrom,
      replyTo: resetPasswordSettings.response_email,
      subject: emailObject,
      text: emailBody,
      html: emailBody,
    };

    // NOTE: Update the user before sending the email so an Admin can generate the link if the email fails
    await getService("user").edit(user.id, { resetPasswordToken });

    // Send user an email.
    await strapi.plugin("email").service("email").send(emailToSend);

    ctx.send({ ok: true });
      },
      appleMobile: async (ctx) => {
        const { identityToken, firstName, lastName, email } =
          ctx.request.body ?? {};

        if (!identityToken) {
          return ctx.badRequest("Missing identityToken");
        }

        const audiences = resolveAppleAudiences();
        if (audiences.length === 0) {
          throw new ApplicationError("Apple Sign In is not configured");
        }

        let tokenPayload;
        try {
          tokenPayload = await verifyAppleIdentityToken(
            identityToken,
            audiences,
          );
        } catch (err) {
          strapi.log.warn(`[appleMobile] token verification failed: ${err.message}`);
          throw new ApplicationError("Invalid Apple identity token");
        }

        const appleSub = tokenPayload?.sub;
        if (!appleSub) {
          throw new ApplicationError("Invalid Apple identity token");
        }

        const tokenEmail = normalizeAppleEmail(tokenPayload?.email);
        const bodyEmail = normalizeAppleEmail(email);
        const resolvedEmail = bodyEmail || tokenEmail;

        let result;
        try {
          result = await findOrCreateAppleUser({
            appleSub,
            email: resolvedEmail,
            firstName:
              typeof firstName === "string" ? firstName.trim() : undefined,
            lastName:
              typeof lastName === "string" ? lastName.trim() : undefined,
          });
        } catch (err) {
          throw new ApplicationError(err.message);
        }

        const { user, isNewUser } = result;

        if (user.blocked) {
          throw new ApplicationError(
            "Your account has been blocked by an administrator",
          );
        }

        const sanitizedUser = await sanitizeUser(user, ctx);
        const jwtToken = getService("jwt").issue({ id: user.id });

        return ctx.send({
          jwt: jwtToken,
          user: sanitizedUser,
          isNewUser,
        });
      },
      googleMobile: async (ctx) => {
        const { idToken, firstName, lastName, email } =
          ctx.request.body ?? {};

        if (!idToken) {
          return ctx.badRequest("Missing idToken");
        }

        const audiences = resolveGoogleAudiences();
        if (audiences.length === 0) {
          throw new ApplicationError("Google Sign In is not configured");
        }

        let tokenPayload;
        try {
          tokenPayload = await verifyGoogleIdToken(idToken, audiences);
        } catch (err) {
          strapi.log.warn(`[googleMobile] token verification failed: ${err.message}`);
          throw new ApplicationError("Invalid Google ID token");
        }

        const googleSub = tokenPayload?.sub;
        if (!googleSub) {
          throw new ApplicationError("Invalid Google ID token");
        }

        const tokenEmail = normalizeAppleEmail(tokenPayload?.email);
        const bodyEmail = normalizeAppleEmail(email);
        const resolvedEmail = bodyEmail || tokenEmail;

        let result;
        try {
          result = await findOrCreateGoogleUser({
            googleSub,
            email: resolvedEmail,
            firstName:
              typeof firstName === "string"
                ? firstName.trim()
                : tokenPayload?.given_name,
            lastName:
              typeof lastName === "string"
                ? lastName.trim()
                : tokenPayload?.family_name,
          });
        } catch (err) {
          throw new ApplicationError(err.message);
        }

        const { user, isNewUser } = result;

        if (user.blocked) {
          throw new ApplicationError(
            "Your account has been blocked by an administrator",
          );
        }

        const sanitizedUser = await sanitizeUser(user, ctx);
        const jwtToken = getService("jwt").issue({ id: user.id });

        return ctx.send({
          jwt: jwtToken,
          user: sanitizedUser,
          isNewUser,
        });
      },
    };
  };

  function normalizeAppleEmail(value) {
    return typeof value === "string" ? value.trim().toLowerCase() : null;
  }

  const issue = (payload, jwtOptions = {}) => {
    _.defaults(jwtOptions, strapi.config.get("plugin::users-permissions.jwt"));
    return jwt.sign(
      _.clone(payload.toJSON ? payload.toJSON() : payload),
      strapi.config.get("plugin::users-permissions.jwtSecret"),
      jwtOptions
    );
  };

  const originalUser = plugin.controllers.user;
  plugin.controllers.user = () => {
    const originalFindOne = originalUser.findOne;

    return {
      ...originalUser,
      findOne: async (ctx) => {
        await originalFindOne(ctx);
        const auth = ctx.state.user;
        if (
          ctx.body &&
          auth &&
          String(auth.id) === String(ctx.params.id)
        ) {
          const row = await strapi.db.connection
            .select("password")
            .from("up_users")
            .where("id", auth.id)
            .first();
          ctx.body.needs_logout_credentials = !(row && row.password);
        }
      },
      update: async (ctx) => {
    const data = ctx.request.body;
    const authToken = await strapi.plugins["users-permissions"].services.jwt.getToken(ctx);

    const requesterIsAdmin = await isAdmin(ctx);

    if (!requesterIsAdmin && String(authToken?.id) !== String(ctx.params.id)) {
      throw new ForbiddenError("You can only update your own account.");
    }

    if (!requesterIsAdmin) {
      delete data.is_admin;
      delete data.account_type;
      delete data.teacher_approved;
      delete data.is_institution_admin;
      delete data.special;
    }

    if (data.english_level != null) {
      if (!ENGLISH_LEVELS.includes(data.english_level)) {
        return ctx.badRequest("Invalid english_level");
      }
      if (!requesterIsAdmin && PREMIUM_ENGLISH_LEVELS.includes(data.english_level)) {
        const { isPremiumUser } = require("../../utils/app-feature-config");
        const premium = await isPremiumUser(strapi, ctx.params.id);
        if (!premium) {
          return ctx.forbidden(
            "B2 and above are only available on Premium. Upgrade to unlock advanced levels."
          );
        }
      }
    }

    const newPassword = data.password;

    if (data.username) {
      const existing = await strapi
        .query("plugin::users-permissions.user")
        .findOne({
          where: {
            username: { $eqi: data.username },
            id: { $ne: ctx.params.id },
          },
        });

      if (existing) {
        throw new ApplicationError(i18n.__("errors.nickname-already-taken"));
      }
    }

    const resultData = {
      ...data,
      ...(newPassword && { password: newPassword }),
    };

    const existingForHistory = await findUserById(strapi, ctx.params.id, {
      fields: ["email", "username", "old_data"]
    });
    if (existingForHistory) {
      appendPreAnonymizeDeletionToIncoming(
        existingForHistory,
        resultData
      );
      if (!isAnonymizeDeletePayload(resultData)) {
        mergeUserIdentityHistoryIntoUpdateData(
          existingForHistory,
          resultData
        );
      }
    }

    const userRawEntity = await updateByNumericId(
      strapi,
      "plugin::users-permissions.user",
      ctx.params.id,
      resultData
    );

    return filterObjectByKeys(USER_RESPONSE_EXCLUDED_KEYS, userRawEntity);
      },
      getSpeakingPreferences: async (ctx) => {
    const { id: userId } = await strapi.plugins[
      "users-permissions"
    ].services.jwt.getToken(ctx);
    const user = await findUserById(strapi, userId, {
      fields: [
        "practice_language",
        "auto_save_corrections",
        "response_language",
        "translation_language",
        "show_translations",
        "auto_play_voice",
        "auto_conversation",
        "sound",
        "type_messages_enabled",
        "auto_start_recording",
        "auto_start_recording_delay_seconds",
        "daily_reminder_enabled",
        "daily_reminder_time",
        "correct_sentence_goal",
        "english_level",
        "tutor_voice",
      ],
    });
    const correctSentencesToday = await getOrIncrementDailyCorrectCount(
      strapi,
      userId,
      false,
    );
    ctx.send({
      practice_language: user?.practice_language ?? "en",
      auto_save_corrections: user?.auto_save_corrections !== false,
      response_language: user?.response_language ?? "en",
      translation_language: user?.translation_language ?? "none",
      show_translations: user?.show_translations === true,
      auto_play_voice: user?.auto_play_voice !== false,
      auto_conversation: user?.auto_conversation === true,
      sound_on: user?.sound !== false,
      type_messages_enabled: user?.type_messages_enabled === true,
      auto_start_recording: user?.auto_start_recording === true,
      auto_start_recording_delay_seconds: clampAutoStartRecordingDelay(
        user?.auto_start_recording_delay_seconds
      ),
      daily_reminder_enabled: user?.daily_reminder_enabled === true,
      daily_reminder_time: user?.daily_reminder_time ?? "09:00",
      correct_sentence_goal: user?.correct_sentence_goal ?? 10,
      correct_sentences_today: correctSentencesToday,
      english_level: user?.english_level ?? null,
      tutor_voice: user?.tutor_voice ?? "nova",
    });
      },
      updateSpeakingPreferences: async (ctx) => {
    const { id: userId } = await strapi.plugins[
      "users-permissions"
    ].services.jwt.getToken(ctx);
    const body = ctx.request.body ?? {};

    const data = {};
    if (body.practice_language != null) {
      if (!PRACTICE_LANGUAGE_CODES.includes(body.practice_language)) {
        return ctx.badRequest("Invalid practice_language");
      }
      data.practice_language = body.practice_language;
    }
    if (body.auto_save_corrections != null) {
      data.auto_save_corrections = body.auto_save_corrections === true;
    }
    if (body.response_language != null) {
      if (!SPEAKING_RESPONSE_LANGS.includes(body.response_language)) {
        return ctx.badRequest("Invalid response_language");
      }
      data.response_language = body.response_language;
    }
    if (body.translation_language != null) {
      if (!SPEAKING_TRANSLATION_LANGS.includes(body.translation_language)) {
        return ctx.badRequest("Invalid translation_language");
      }
      data.translation_language = body.translation_language;
    }
    if (body.show_translations != null) {
      data.show_translations = body.show_translations === true;
    }
    if (body.auto_play_voice != null) {
      data.auto_play_voice = body.auto_play_voice === true;
    }
    if (body.auto_conversation != null) {
      data.auto_conversation = body.auto_conversation === true;
    }
    if (body.sound_on != null) {
      data.sound = body.sound_on === true;
    }
    if (body.type_messages_enabled != null) {
      data.type_messages_enabled = body.type_messages_enabled === true;
    }
    if (body.auto_start_recording != null) {
      data.auto_start_recording = body.auto_start_recording === true;
    }
    if (body.auto_start_recording_delay_seconds != null) {
      const delay = Number(body.auto_start_recording_delay_seconds);
      if (!Number.isFinite(delay) || delay < 0 || delay > 10) {
        return ctx.badRequest(
          "auto_start_recording_delay_seconds must be between 0 and 10"
        );
      }
      data.auto_start_recording_delay_seconds = Math.round(delay);
    }
    if (body.daily_reminder_enabled != null) {
      data.daily_reminder_enabled = body.daily_reminder_enabled === true;
    }
    if (body.daily_reminder_time != null) {
      const time = String(body.daily_reminder_time).trim();
      if (!/^\d{2}:\d{2}$/.test(time)) {
        return ctx.badRequest("daily_reminder_time must be HH:MM");
      }
      data.daily_reminder_time = time;
    }
    if (body.correct_sentence_goal != null) {
      const goal = Number(body.correct_sentence_goal);
      if (!Number.isFinite(goal) || goal < 1 || goal > 100) {
        return ctx.badRequest("correct_sentence_goal must be between 1 and 100");
      }
      data.correct_sentence_goal = Math.round(goal);
    }
    if (body.english_level != null) {
      if (!ENGLISH_LEVELS.includes(body.english_level)) {
        return ctx.badRequest("Invalid english_level");
      }
      if (PREMIUM_ENGLISH_LEVELS.includes(body.english_level)) {
        const { isPremiumUser } = require("../../utils/app-feature-config");
        const premium = await isPremiumUser(strapi, userId);
        if (!premium) {
          return ctx.forbidden(
            "B2 and above are only available on Premium. Upgrade to unlock advanced levels."
          );
        }
      }
      data.english_level = body.english_level;
    }
    if (body.tutor_voice != null) {
      if (!TUTOR_VOICES.includes(body.tutor_voice)) {
        return ctx.badRequest("Invalid tutor_voice");
      }
      if (!FREE_TUTOR_VOICES.includes(body.tutor_voice)) {
        const { isPremiumUser } = require("../../utils/app-feature-config");
        const premium = await isPremiumUser(strapi, userId);
        if (!premium) {
          return ctx.forbidden(
            "This voice is only available on Premium. Upgrade to unlock more tutor voices."
          );
        }
      }
      data.tutor_voice = body.tutor_voice;
    }

    if (Object.keys(data).length === 0) {
      return ctx.badRequest("No speaking preference fields provided");
    }

    try {
      const updated = await updateByNumericId(
        strapi,
        "plugin::users-permissions.user",
        userId,
        data
      );

      try {
        const {
          recordLanguageSelection,
          updateTutorLevelForLanguage,
        } = require("../../utils/language-level-analytics");
        const lang = updated.practice_language ?? "en";
        const tutorLevel = updated.english_level ?? "A1";
        if (body.practice_language != null) {
          await recordLanguageSelection(strapi, userId, lang, tutorLevel);
        } else if (body.english_level != null) {
          await updateTutorLevelForLanguage(strapi, userId, lang, tutorLevel);
        }
      } catch (analyticsErr) {
        strapi.log.warn(
          "[updateSpeakingPreferences] language analytics failed",
          analyticsErr,
        );
      }

      ctx.send({
        practice_language: updated.practice_language ?? "en",
        auto_save_corrections: updated.auto_save_corrections !== false,
        response_language: updated.response_language,
        translation_language: updated.translation_language,
        show_translations: updated.show_translations,
        auto_play_voice: updated.auto_play_voice,
        auto_conversation: updated.auto_conversation,
        sound_on: updated.sound !== false,
        type_messages_enabled: updated.type_messages_enabled === true,
        auto_start_recording: updated.auto_start_recording === true,
        auto_start_recording_delay_seconds: clampAutoStartRecordingDelay(
          updated.auto_start_recording_delay_seconds
        ),
        daily_reminder_enabled: updated.daily_reminder_enabled === true,
        daily_reminder_time: updated.daily_reminder_time ?? "09:00",
        correct_sentence_goal: updated.correct_sentence_goal ?? 10,
        english_level: updated.english_level ?? null,
      });
    } catch (err) {
      throw err;
    }
      },
      deleteNicknamedUser: async (ctx) => {
        return deleteByNumericId(
          strapi,
          "plugin::users-permissions.user",
          ctx.params.id
        );
      },
    };
  };

  const SPEAKING_RESPONSE_LANGS = ["en", "es", "fr", "de", "it", "hi", "pt", "zh", "ja", "ru"];
  const SPEAKING_TRANSLATION_LANGS = ["none", "en", "es", "fr", "de", "it", "hi", "pt", "zh", "ja", "ru", "ar", "hy", "ko", "tr", "uk"];
  const PRACTICE_LANGUAGE_CODES = ["en", "es", "fr", "de", "it", "pt", "zh", "ja", "ru", "hi"];
  const TUTOR_VOICES = ["alloy", "echo", "fable", "onyx", "nova", "shimmer"];
  const FREE_TUTOR_VOICES = ["nova", "onyx"];
  const ENGLISH_LEVELS = ["A1", "A2", "B1", "B2", "C1", "C2"];
  const PREMIUM_ENGLISH_LEVELS = ["B2", "C1", "C2"];

  plugin.routes["content-api"].routes.push(
    {
      method: "POST",
      path: "/auth/apple/mobile",
      handler: "auth.appleMobile",
      config: {
        prefix: "",
        auth: false,
      },
    },
    {
      method: "POST",
      path: "/auth/google/mobile",
      handler: "auth.googleMobile",
      config: {
        prefix: "",
        auth: false,
      },
    },
    {
      method: "DELETE",
      path: "/users/:id/delete-nicknamed-user",
      handler: "user.deleteNicknamedUser",
      config: {
        prefix: "",
      },
    },
    {
      method: "GET",
      path: "/users/me/speaking-preferences",
      handler: "user.getSpeakingPreferences",
      config: {
        prefix: "",
      },
    },
    {
      method: "PUT",
      path: "/users/me/speaking-preferences",
      handler: "user.updateSpeakingPreferences",
      config: {
        prefix: "",
      },
    }
  );

  return plugin;
};
