const _ = require("lodash");
const utils = require("@strapi/utils");
const {
  getAbsoluteAdminUrl,
  getAbsoluteServerUrl,
  sanitize,
  contentTypes: { getNonWritableAttributes },
} = utils;
const { ApplicationError } = utils.errors;
const i18n = require("../../i18n-helper");

i18n.init();

const jwt = require("jsonwebtoken");
const moment = require("moment-timezone");
const constants = require("../../constants");

const sanitizeUser = (user, ctx) => {
  const { auth } = ctx.state;
  const userSchema = strapi.getModel("plugin::users-permissions.user");
  return sanitize.contentAPI.output(user, userSchema, { auth });
};

// validation
const { yup, validateYupSchema } = require("@strapi/utils");
const {
  validateForgotPasswordBody,
} = require("../../../node_modules/@strapi/plugin-users-permissions/server/controllers/validation/auth");
const crypto = require("crypto");
const { getService } = require("../../../node_modules/@strapi/plugin-users-permissions/server/utils");
const {
  dateDiff,
  getTodayAndTomorrow,
  getServerDateFromUserDate,
} = require("../../utils/dates");
const { getUser } = require("../../utils/get_user");
const { filterObjectByKeys } = require("../../utils/filter-object-by-keys");
const { isAdmin } = require("../../utils/is-admin");
const {
  filterLeaderboardUsers,
  isLeaderboardEligibleUser,
} = require("../../utils/leaderboard-eligibility");
const {
  normalizeAccountType,
  ACCOUNT_TYPES,
} = require("../../utils/account-type");
const {
  resolveInstitutionForSchoolEmail,
  registrationRequiresSchoolEmail,
  assertSchoolEmailFormat,
} = require("../../utils/school-email");
const {
  institutionInviteMatches,
  currentCalendarYear,
} = require("../../utils/teacher-approval");
const {
  mergeUserIdentityHistoryIntoUpdateData,
  appendPreAnonymizeDeletionToIncoming,
  isAnonymizeDeletePayload,
} = require("../../utils/user-identity-history");
const plugins = require("../../../config/plugins");

const USER_RESPONSE_EXCLUDED_KEYS = [
  "confirmationToken",
  "password",
  "resetPasswordToken",
  "old_data",
];

const utcYmd = (d = new Date()) => d.toISOString().slice(0, 10);

const parseYmdParam = (s) => {
  if (!s || typeof s !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(s.trim())) {
    return null;
  }
  const trimmed = s.trim();
  const t = new Date(`${trimmed}T00:00:00.000Z`);
  return Number.isNaN(t.getTime()) ? null : trimmed;
};

const addUtcDaysYmd = (ymd, deltaDays) => {
  const t = new Date(`${ymd}T00:00:00.000Z`);
  t.setUTCDate(t.getUTCDate() + deltaDays);
  return utcYmd(t);
};

const ymdlte = (a, b) => a.localeCompare(b) <= 0;

const rowDayToYmd = (day) => {
  if (!day) return null;
  if (day instanceof Date && !Number.isNaN(day.getTime())) return utcYmd(day);
  const s = String(day);
  const m = s.match(/^(\d{4}-\d{2}-\d{2})/);
  if (m) return m[1];
  const d = new Date(s);
  return Number.isNaN(d.getTime()) ? null : utcYmd(d);
};

function dayRangeInclusive(startYmd, endYmd) {
  const out = [];
  let cur = startYmd;
  while (ymdlte(cur, endYmd)) {
    out.push(cur);
    cur = addUtcDaysYmd(cur, 1);
  }
  return out;
}

/** Inclusive ISO dates stepping by calendar days in [tz]. */
function dayRangeInclusiveTz(startYmd, endYmd, tz) {
  const out = [];
  let cur = startYmd;
  while (ymdlte(cur, endYmd)) {
    out.push(cur);
    cur = moment.tz(cur, "YYYY-MM-DD", tz).add(1, "days").format("YYYY-MM-DD");
  }
  return out;
}

function weekRangeInclusiveTz(startYmd, endYmd, tz) {
  const out = [];
  const first = moment.tz(startYmd, "YYYY-MM-DD", tz).startOf("isoWeek");
  const lastWeekStart = moment
    .tz(endYmd, "YYYY-MM-DD", tz)
    .startOf("isoWeek");
  let cur = first.clone();
  while (!cur.isAfter(lastWeekStart)) {
    out.push(cur.format("YYYY-MM-DD"));
    cur.add(1, "week");
  }
  return out;
}

function monthRangeInclusiveTz(startYmd, endYmd, tz) {
  const out = [];
  let cur = moment.tz(startYmd, "YYYY-MM-DD", tz).startOf("month");
  const last = moment.tz(endYmd, "YYYY-MM-DD", tz).startOf("month");
  while (!cur.isAfter(last)) {
    out.push(cur.format("YYYY-MM-DD"));
    cur.add(1, "month");
  }
  return out;
}

function bucketKeysForGranularity(startYmd, endYmd, tz, granularity) {
  if (granularity === "week") {
    return weekRangeInclusiveTz(startYmd, endYmd, tz);
  }
  if (granularity === "month") {
    return monthRangeInclusiveTz(startYmd, endYmd, tz);
  }
  return dayRangeInclusiveTz(startYmd, endYmd, tz);
}

const buildFilledSeriesTz = (startYmd, endYmd, countsByDay, tz, granularity) =>
  bucketKeysForGranularity(startYmd, endYmd, tz, granularity).map((date) => ({
    date,
    count: countsByDay[date] ?? 0,
  }));

/**
 * Validates IANA before interpolating SQL; falls back safely.
 */
const sanitizeReportingTimezone = (raw, fb) => {
  const fallback =
    fb && typeof fb === "string" && fb.trim().length && moment.tz.zone(fb.trim())
      ? fb.trim()
      : constants.DEFAULT_TIMEZONE &&
          moment.tz.zone(constants.DEFAULT_TIMEZONE)
        ? constants.DEFAULT_TIMEZONE
        : "UTC";
  if (
    typeof raw !== "string" ||
    raw.trim().length < 3 ||
    !moment.tz.zone(raw.trim())
  ) {
    return fallback;
  }
  return raw.trim();
};

// Local register schema: username + password required, email optional.
// Replaces Strapi's default validator, which marks email required.
const registerBodySchema = yup.object().shape({
  username: yup.string().required(),
  password: yup.string().required(),
  email: yup.string().email().notRequired(),
  account_type: yup
    .string()
    .oneOf([ACCOUNT_TYPES.STUDENT, ACCOUNT_TYPES.TEACHER])
    .notRequired(),
  institution: yup.number().integer().positive().notRequired(),
  teacher_invite_code: yup.string().notRequired(),
});

const validateLocalRegisterBody = validateYupSchema(registerBodySchema);

/** Strapi Postgres may store the learner on `user_answers` or only in the `_links` table. */
const UA_USER_FK_UNSET = {};

/** @type {string | boolean | Record<string, never>} — string = column; false = no column; sentinel = not loaded */
let cachedUserAnswerParticipantCol = UA_USER_FK_UNSET;

const resolveUserAnswerUserFkColumn = async (knex) => {
  if (cachedUserAnswerParticipantCol !== UA_USER_FK_UNSET) {
    return cachedUserAnswerParticipantCol === false
      ? null
      : /** @type {string} */ (cachedUserAnswerParticipantCol);
  }
  try {
    const { rows } = await knex.raw(
      `SELECT column_name
       FROM information_schema.columns
       WHERE table_schema IN ('public', current_schema())
         AND table_name = 'user_answers'
         AND (
           column_name = 'users_permissions_user_id'
           OR column_name ILIKE '%permissions%users%'
           OR column_name ILIKE 'users_permissions%'
         );`
    );
    const cols = rows.map((r) => r.column_name).filter(Boolean);
    const preferred = cols.includes("users_permissions_user_id")
      ? "users_permissions_user_id"
      : cols.find((c) => /^[a-z0-9_]+$/i.test(c)) ?? null;
    if (preferred) {
      cachedUserAnswerParticipantCol = preferred;
      return preferred;
    }
    cachedUserAnswerParticipantCol = false;
    return null;
  } catch (_) {
    cachedUserAnswerParticipantCol = false;
    return null;
  }
};

/**
 * Links learner via `_links` (always when Strapi persists relations) or optional FK on `ua`.
 * INNER JOIN COALESCE(...) dropped answers when links were absent; EXISTS keeps all linked rows.
 * [statusSql] is literal (callers-only), e.g. `ua.status = 'correct'`.
 */
const userAnswerBucketExpr = (granularity) =>
  granularity === "week"
    ? `date_trunc('week', timezone(?::text, ua.created_at))::date`
    : granularity === "month"
      ? `date_trunc('month', timezone(?::text, ua.created_at))::date`
      : `(timezone(?::text, ua.created_at))::date`;

const userCreatedBucketExpr = (granularity) =>
  granularity === "week"
    ? `date_trunc('week', timezone(?::text, up_users.created_at))::date`
    : granularity === "month"
      ? `date_trunc('month', timezone(?::text, up_users.created_at))::date`
      : `(timezone(?::text, up_users.created_at))::date`;

const userAnswerBucketsByGranularity = async (
  knex,
  reportTz,
  startYmd,
  endYmd,
  fkParticipant,
  statusSql,
  granularity,
) => {
  const fkOr =
    fkParticipant && /^[a-z0-9_]+$/i.test(fkParticipant)
      ? `OR EXISTS (
          SELECT 1 FROM up_users u
          WHERE u.id = ua.${fkParticipant} AND (u.is_admin IS NOT TRUE)
        )`
      : "";
  return knex.raw(
    `SELECT ${userAnswerBucketExpr(granularity)} AS day,
            COUNT(DISTINCT ua.id)::int AS cnt
     FROM user_answers AS ua
     WHERE (${statusSql})
       AND (timezone(?::text, ua.created_at))::date BETWEEN ?::date AND ?::date
       AND (
         EXISTS (
           SELECT 1
           FROM user_answers_users_permissions_user_links AS lnk
           INNER JOIN up_users AS u ON u.id = lnk.user_id
           WHERE lnk.user_answer_id = ua.id
             AND (u.is_admin IS NOT TRUE)
         )
         ${fkOr}
       )
     GROUP BY 1
     ORDER BY 1`,
    [reportTz, reportTz, startYmd, endYmd],
  );
};

module.exports = (plugin) => {
  const userFindOneDefault = plugin.controllers.user.findOne;
  if (typeof userFindOneDefault === "function") {
    plugin.controllers.user.findOne = async (ctx) => {
      await userFindOneDefault(ctx);
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
    };
  }

  // JWT issuer
  const issue = (payload, jwtOptions = {}) => {
    _.defaults(jwtOptions, strapi.config.get("plugin.users-permissions.jwt"));
    return jwt.sign(
      _.clone(payload.toJSON ? payload.toJSON() : payload),
      strapi.config.get("plugin.users-permissions.jwtSecret"),
      jwtOptions
    );
  };

  plugin.controllers.user.getUserDailyStatistics = async (ctx) => {
    const { id: userId } = await strapi.plugins[
      "users-permissions"
    ].services.jwt.getToken(ctx);
    const user = await strapi.entityService.findOne(
      "plugin::users-permissions.user",
      userId
    );

    const timezone = user.user_timezone || constants.DEFAULT_TIMEZONE;
    const { today, tomorrow } = getTodayAndTomorrow(timezone);
    let { rows } = await strapi.db.connection.raw(
      `SELECT status, COUNT(status) FROM user_answers
        INNER JOIN user_answers_users_permissions_user_links
        ON user_answers.id = user_answers_users_permissions_user_links.user_answer_id
        WHERE user_id = ${user.id}
        AND user_answers.created_at >= '${getServerDateFromUserDate(
          today,
          timezone
        )}'
        AND user_answers.created_at < '${getServerDateFromUserDate(
          tomorrow,
          timezone
        )}'
        GROUP BY status;`
    );

    return rows;
  };

  // getting points controller
  plugin.controllers.user.getPoints = async (ctx) => {
    const { filters, sort } = ctx.request.query;

    const leaderboardExclusion = {
      account_type: { $ne: ACCOUNT_TYPES.TEACHER },
      is_admin: { $ne: true },
    };

    const scopedFilters =
      filters && filters.hasOwnProperty("institution")
        ? {
            $and: [
              leaderboardExclusion,
              {
                institution: {
                  place_id: {
                    $eq: filters.institution,
                  },
                },
                ...(filters.hasOwnProperty("course") && {
                  course: {
                    $eq: filters.course,
                  },
                }),
              },
            ],
          }
        : filters
          ? { $and: [leaderboardExclusion, filters] }
          : leaderboardExclusion;

    return await strapi.entityService.findMany(
      "plugin::users-permissions.user",
      {
        filters: scopedFilters,
        sort,
      }
    );
  };

  // getting of user rankings
  plugin.controllers.user.getUserRankings = async (ctx) => {
    const userId = (
      await strapi.plugins["users-permissions"].services.jwt.getToken(ctx)
    ).id;
    const user = await strapi.entityService.findOne(
      "plugin::users-permissions.user",
      userId,
      {
        populate: { institution: true },
      }
    );

    const users = filterLeaderboardUsers(
      await strapi.entityService.findMany(
        "plugin::users-permissions.user",
        {
          populate: { institution: true },
          sort: { points: "desc" },
        }
      )
    );
    const countryUsers = user.country
      ? users.filter((u) => u.country === user.country)
      : [];
    const cityUsers = user.city
      ? users.filter((u) => u.city === user.city)
      : [];
    const institutionUsers = user.institution
      ? users.filter((u) => u.institution?.id === user.institution.id)
      : [];
    const courseUsers =
      user.institution && user.course
        ? users.filter(
            (u) =>
              u.institution?.id === user.institution.id &&
              u.course === user.course
          )
        : [];
    const eligible = isLeaderboardEligibleUser(user);
    const placeIn = (list) =>
      eligible ? list.findIndex((u) => u.id === userId) + 1 || null : null;

    return {
      rankings: {
        world: {
          my_place: placeIn(users),
          users_amount: users.length,
        },
        country: {
          my_place: placeIn(countryUsers),
          users_amount: countryUsers.length,
        },
        city: {
          my_place: placeIn(cityUsers),
          users_amount: cityUsers.length,
        },
        institution: {
          my_place: placeIn(institutionUsers),
          users_amount: institutionUsers.length,
        },
        course: {
          my_place: placeIn(courseUsers),
          users_amount: courseUsers.length,
        },
      },
    };
  };

  plugin.controllers.user.getMyAnswersStats = async (ctx) => {
    const userId = (
      await strapi.plugins["users-permissions"].services.jwt.getToken(ctx)
    ).id;

    const topicQuestionsCount = (
      await strapi.entityService.findMany("api::question.question")
    ).length;
    const lastAnswer = (
      await strapi.entityService.findMany("api::user-answer.user-answer", {
        populate: {
          users_permissions_user: {
            fields: ["id"],
          },
        },
        filters: {
          users_permissions_user: {
            id: {
              $eq: userId,
            },
          },
        },
        sort: { id: "desc" },
      })
    )[0];
    const allAnswersCount = (
      await strapi.entityService.findMany("api::user-answer.user-answer", {
        populate: {
          users_permissions_user: {
            fields: ["id"],
          },
        },
        filters: {
          users_permissions_user: {
            id: {
              $eq: userId,
            },
          },
        },
      })
    ).length;
    const answeredTopicQuestionsCount = (
      await strapi.entityService.findMany("api::question.question", {
        populate: {
          user_answers: {
            fields: ["id", "status", "answer", "answer_type"],
            populate: {
              users_permissions_user: {
                fields: ["id"],
              },
            },
            filters: {
              $and: [
                {
                  users_permissions_user: {
                    id: userId,
                  },
                },
                {
                  answer_type: {
                    $eq: "topic",
                  },
                },
                {
                  status: {
                    $ne: "skipped",
                  },
                },
              ],
            },
          },
        },
        filters: {
          user_answers: {
            $and: [
              {
                users_permissions_user: {
                  id: {
                    $eq: userId,
                  },
                },
              },
              {
                answer_type: {
                  $eq: "topic",
                },
              },
              {
                status: {
                  $ne: "skipped",
                },
              },
            ],
          },
        },
      })
    ).length;

    const getAnswersByStatus = async (status) => {
      const answers = await strapi.entityService.findMany(
        "api::user-answer.user-answer",
        {
          populate: {
            users_permissions_user: {
              fields: ["id"],
            },
          },
          filters: {
            users_permissions_user: {
              id: {
                $eq: userId,
              },
            },
            status: {
              $eq: status,
            },
          },
        }
      );

      return answers.length;
    };

    const correctAnswersCount = await getAnswersByStatus("correct");
    const wrongAnswersCount = await getAnswersByStatus("wrong");
    const skippedAnswersCount = await getAnswersByStatus("skipped");

    const topicQuestionsLeftCount =
      topicQuestionsCount - answeredTopicQuestionsCount;
    const answersPercent = Math.round(
      (Number(answeredTopicQuestionsCount) / Number(topicQuestionsCount)) * 100
    );
    const correctAnswersPercent = Math.round(
      (Number(correctAnswersCount) / Number(allAnswersCount)) * 100
    );
    const wrongAnswersPercent = Math.round(
      (Number(wrongAnswersCount) / Number(allAnswersCount)) * 100
    );
    const skippedAnswersPercent =
      100 - correctAnswersPercent - wrongAnswersPercent;

    return {
      questions_count: topicQuestionsCount,
      questions_left_count: topicQuestionsLeftCount,
      answers_count: answeredTopicQuestionsCount,
      answers_percent: answersPercent,
      correct_answers: {
        count: correctAnswersCount,
        percent: correctAnswersPercent,
      },
      wrong_answers: {
        count: wrongAnswersCount,
        percent: wrongAnswersPercent,
      },
      skipped_answers: {
        count: skippedAnswersCount,
        percent: skippedAnswersPercent,
      },
      last_update: lastAnswer?.createdAt ? dateDiff(new Date(lastAnswer?.createdAt), new Date()) : null,
    };
  };

  // getting of user's stats
  plugin.controllers.user.getUserStats = async (ctx) => {
    const userId = +ctx.params.id;
    const user = await strapi.entityService.findOne(
      "plugin::users-permissions.user",
      userId,
      {
        populate: { institution: true, user_answers: true },
      }
    );

    // how much time user uses the application
    const currentDate = new Date();
    const registerDate = new Date(user.createdAt);
    const time = (currentDate.getTime() - registerDate.getTime()) / 1000;
    const years = Math.abs(Math.round(time / (60 * 60 * 24) / 365.25));
    const months = Math.abs(Math.round(time / (60 * 60 * 24 * 7 * 4)));
    const days = Math.abs(Math.round(time / (3600 * 24)));

    // rank in world, country, city, institution, course
    const users = filterLeaderboardUsers(
      await strapi.entityService.findMany(
        "plugin::users-permissions.user",
        {
          populate: { institution: true },
          sort: { points: "desc" },
        }
      )
    );
    const countryUsers = user.country
      ? users.filter((u) => u.country === user.country)
      : [];
    const cityUsers = user.city
      ? users.filter((u) => u.city === user.city)
      : [];
    const institutionUsers = user.institution
      ? users.filter((u) => u.institution?.id === user.institution.id)
      : [];
    const courseUsers =
      user.institution && user.course
        ? users.filter(
            (u) =>
              u.institution?.id === user.institution.id &&
              u.course === user.course
          )
        : [];
    const eligible = isLeaderboardEligibleUser(user);
    const placeIn = (list) =>
      eligible ? list.findIndex((u) => u.id === userId) + 1 || null : null;

    // answers percentage
    const answersCount = user.user_answers.length;
    const correctAnswers = user.user_answers.filter(
      (a) => a.status === "correct"
    ).length;
    const wrongAnswers = user.user_answers.filter(
      (a) => a.status === "wrong"
    ).length;
    const skippedAnswers = user.user_answers.filter(
      (a) => a.status === "skipped"
    ).length;

    return {
      howMuchTime: {
        years,
        months,
        days,
      },
      points: user.points,
      rankings: {
        world: placeIn(users),
        country: placeIn(countryUsers),
        city: placeIn(cityUsers),
        institution: placeIn(institutionUsers),
        course: placeIn(courseUsers),
      },
      answers: {
        count: answersCount,
        correct: correctAnswers,
        wrong: wrongAnswers,
        skipped: skippedAnswers,
      },
    };
  };

  // getting of user's status
  plugin.controllers.user.getUserStatus = async (ctx) => {
    const userId = (
      await strapi.plugins["users-permissions"].services.jwt.getToken(ctx)
    ).id;

    const user = await getUser(userId);
    const currentDate = new Date();
    const registerDate = new Date(user.createdAt);

    // get last category
    const lastCategory = await strapi
      .controller("api::category.category")
      .getLastCategory(ctx);

    // get past categories data
    const pastCategories = await strapi
      .controller("api::category.category")
      .getPastCategories(ctx);
    const categories = await strapi.entityService.findMany(
      "api::category.category"
    );
    const dailyStatics = await strapi.plugins[
      "users-permissions"
    ].controllers.user.getUserDailyStatistics(ctx);

    return {
      last_quiz: lastCategory,
      time_in_app: dateDiff(registerDate, currentDate),
      last_update: user.user_answers[0]?.createdAt ? dateDiff(new Date(user.user_answers[0]?.createdAt), currentDate) : null,
      points: user.points,
      past_categories_count: pastCategories.length,
      categories_count: categories.length,
      daily_statics: dailyStatics,
      past_categories_percent: Math.round(
        (pastCategories.length / categories.length) * 100
      ),
    };
  };

  /** Global activity stats by reporting timezone; excludes `is_admin` learners only in aggregates. */
  plugin.controllers.user.getAppActivityStats = async (ctx) => {
    if (!(await isAdmin(ctx))) {
      return ctx.badRequest(
        null,
        "You are not allowed to access this route",
      );
    }

    const parseGranularity = (s) => {
      const v = (s && String(s).toLowerCase().trim()) || "day";
      if (v === "week" || v === "weekly") return "week";
      if (v === "month" || v === "monthly") return "month";
      return "day";
    };

    const granularity = parseGranularity(ctx.query.granularity);

    const presetRaw =
      ctx.query.preset != null
        ? String(ctx.query.preset).toLowerCase().trim()
        : "";
    const preset =
      presetRaw === "current_month" ||
      presetRaw === "last_month" ||
      presetRaw === "last_30_days"
        ? presetRaw
        : "";

    const adminId = ctx.state.user?.id;
    const adminRow =
      adminId != null
        ? await strapi.entityService.findOne(
            "plugin::users-permissions.user",
            adminId,
            { fields: ["user_timezone"] },
          )
        : null;
    const reportTz = sanitizeReportingTimezone(
      undefined,
      adminRow?.user_timezone ?? null,
    );

    let endYmd;
    let startYmd;
    const nowTz = moment.tz(reportTz);

    if (preset === "current_month") {
      startYmd = nowTz.clone().startOf("month").format("YYYY-MM-DD");
      endYmd = nowTz.format("YYYY-MM-DD");
    } else if (preset === "last_month") {
      const last = nowTz.clone().subtract(1, "month");
      startYmd = last.clone().startOf("month").format("YYYY-MM-DD");
      endYmd = last.clone().endOf("month").format("YYYY-MM-DD");
    } else if (preset === "last_30_days") {
      endYmd = nowTz.format("YYYY-MM-DD");
      startYmd = nowTz.clone().subtract(29, "days").format("YYYY-MM-DD");
    } else {
      endYmd =
        parseYmdParam(ctx.query.end) ?? nowTz.format("YYYY-MM-DD");
      startYmd =
        parseYmdParam(ctx.query.start) ??
        moment.tz(endYmd, "YYYY-MM-DD", reportTz)
          .subtract(29, "days")
          .format("YYYY-MM-DD");
    }

    if (startYmd > endYmd) {
      const swap = startYmd;
      startYmd = endYmd;
      endYmd = swap;
    }

    const spanDays =
      Math.round(
        (new Date(`${endYmd}T00:00:00.000Z`).getTime() -
          new Date(`${startYmd}T00:00:00.000Z`).getTime()) /
          86400000,
      ) + 1;
    const maxSpanDays =
      granularity === "day" ? 366 : granularity === "week" ? 730 : 1095;
    if (spanDays > maxSpanDays) {
      startYmd = moment
        .tz(endYmd, "YYYY-MM-DD", reportTz)
        .subtract(maxSpanDays - 1, "days")
        .format("YYYY-MM-DD");
    }

    const spanDaysFinal =
      Math.round(
        (new Date(`${endYmd}T00:00:00.000Z`).getTime() -
          new Date(`${startYmd}T00:00:00.000Z`).getTime()) /
          86400000,
      ) + 1;

    const knex = strapi.db.connection;

    const regRes = await knex.raw(
      `SELECT ${userCreatedBucketExpr(granularity)} AS day,
              COUNT(*)::int AS cnt
       FROM up_users
       WHERE (up_users.is_admin IS NOT TRUE)
         AND (timezone(?::text, up_users.created_at))::date BETWEEN ?::date AND ?::date
       GROUP BY 1
       ORDER BY 1`,
      [reportTz, reportTz, startYmd, endYmd],
    );

    const fkParticipant = await resolveUserAnswerUserFkColumn(knex);
    const solvedRes = await userAnswerBucketsByGranularity(
      knex,
      reportTz,
      startYmd,
      endYmd,
      fkParticipant,
      "ua.status = 'correct'",
      granularity,
    );
    const answeredRes = await userAnswerBucketsByGranularity(
      knex,
      reportTz,
      startYmd,
      endYmd,
      fkParticipant,
      "ua.status IN ('correct', 'wrong')",
      granularity,
    );

    const regRows = regRes.rows ?? regRes;
    const solvedRows = solvedRes.rows ?? solvedRes;
    const answeredRows = answeredRes.rows ?? answeredRes;

    const regCounts = {};
    for (const row of regRows) {
      const ymd = rowDayToYmd(row.day);
      if (ymd) regCounts[ymd] = Number(row.cnt) || 0;
    }
    const solvedCounts = {};
    for (const row of solvedRows) {
      const ymd = rowDayToYmd(row.day);
      if (ymd) solvedCounts[ymd] = Number(row.cnt) || 0;
    }
    const answeredCounts = {};
    for (const row of answeredRows) {
      const ymd = rowDayToYmd(row.day);
      if (ymd) answeredCounts[ymd] = Number(row.cnt) || 0;
    }

    const bucketCount = bucketKeysForGranularity(
      startYmd,
      endYmd,
      reportTz,
      granularity,
    ).length;

    return {
      timezone: reportTz,
      granularity,
      preset: preset || null,
      window_days: spanDaysFinal,
      bucket_count: bucketCount,
      start: startYmd,
      end: endYmd,
      daily_registrations: buildFilledSeriesTz(
        startYmd,
        endYmd,
        regCounts,
        reportTz,
        granularity,
      ),
      daily_solved_correct: buildFilledSeriesTz(
        startYmd,
        endYmd,
        solvedCounts,
        reportTz,
        granularity,
      ),
      daily_exercises_answered: buildFilledSeriesTz(
        startYmd,
        endYmd,
        answeredCounts,
        reportTz,
        granularity,
      ),
    };
  };

  // Strapi's default register treats email and username as one identifier pool
  // (email may conflict with another user's username). We only compare email↔email
  // and username↔username so a nickname may equal someone else's email string.
  plugin.controllers.auth.register = async (ctx) => {
    const pluginStore = await strapi.store({
      type: "plugin",
      name: "users-permissions",
    });
    const settings = await pluginStore.get({ key: "advanced" });

    if (!settings.allow_register) {
      throw new ApplicationError(i18n.__("errors.register-action-disabled"));
    }

    const { register } = strapi.config.get("plugin.users-permissions");
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
      teacher_invite_code: ctx.request.body?.teacher_invite_code,
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

    const accountType =
      normalizeAccountType(params.account_type) || ACCOUNT_TYPES.STUDENT;

    if (registrationRequiresSchoolEmail(params) && !emailNorm) {
      throw new ApplicationError(i18n.__("errors.school-email-required"));
    }

    let institutionIdFromEmail = null;
    if (emailNorm && registrationRequiresSchoolEmail(params)) {
      try {
        assertSchoolEmailFormat(emailNorm);
      } catch (e) {
        throw new ApplicationError(
          i18n.__(e.code || "errors.school-email-invalid")
        );
      }

      const resolved = await resolveInstitutionForSchoolEmail(
        strapi,
        emailNorm,
        params.institution
      );
      if (resolved.errorKey) {
        throw new ApplicationError(i18n.__(resolved.errorKey));
      }
      institutionIdFromEmail = resolved.institutionId;

      if (accountType === ACCOUNT_TYPES.TEACHER) {
        const inviteCode = params.teacher_invite_code;
        if (!inviteCode || typeof inviteCode !== "string" || !inviteCode.trim()) {
          throw new ApplicationError(
            i18n.__("errors.teacher-invite-required")
          );
        }
        const institution = await strapi.entityService.findOne(
          "api::institution.institution",
          institutionIdFromEmail,
          {
            fields: [
              "id",
              "teacher_invite_code",
              "teacher_invite_code_year",
            ],
          }
        );
        if (!institutionInviteMatches(institution, inviteCode)) {
          throw new ApplicationError(
            i18n.__("errors.teacher-invite-invalid", {
              year: currentCalendarYear(),
            })
          );
        }
      }
    }

    let assignedRole = role;
    if (accountType === ACCOUNT_TYPES.TEACHER) {
      const teacherRole = await strapi
        .query("plugin::users-permissions.role")
        .findOne({ where: { type: "teacher" } });
      if (!teacherRole) {
        throw new ApplicationError(i18n.__("errors.find-teacher-role"));
      }
      assignedRole = teacherRole;
    }

    const registerPayload = _.omit(params, [
      "institution",
      "teacher_invite_code",
    ]);

    const newUser = {
      ...registerPayload,
      account_type: accountType,
      teacher_approved: false,
      role: assignedRole.id,
      ...(emailNorm ? { email: emailNorm } : {}),
      ...(institutionIdFromEmail
        ? { institution: institutionIdFromEmail }
        : {}),
      username,
      // Without an email there's nothing to confirm — skip confirmation flow.
      confirmed: emailNorm ? !settings.email_confirmation : true,
    };

    const user = await getService("user").add(newUser);
    const sanitizedUser = await sanitizeUser(user, ctx);

    if (settings.email_confirmation && emailNorm) {
      try {
        await getService("user").sendConfirmationEmail(sanitizedUser);
      } catch (err) {
        throw new ApplicationError(err.message);
      }
      return ctx.send({ user: sanitizedUser });
    }

    const jwt = getService("jwt").issue(_.pick(user, ["id"]));
    return ctx.send({
      jwt,
      user: sanitizedUser,
    });
  };

  // register by nickname only
  plugin.controllers.auth.registerNicknamedUser = async (ctx) => {
    const pluginStore = await strapi.store({
      type: "plugin",
      name: "users-permissions",
    });

    const settings = await pluginStore.get({
      key: "advanced",
    });

    if (!settings.allow_register) {
      throw new ApplicationError(i18n.__("errors.register-action-disabled"));
    }

    const params = {
      ..._.omit(ctx.request.body, [
        "confirmed",
        "confirmationToken",
        "resetPasswordToken",
      ]),
      provider: "local",
      confirmed: true,
    };

    if (!params.username) {
      throw new ApplicationError(i18n.__("errors.nickname-required"));
    }

    const role = await strapi
      .query("plugin::users-permissions.role")
      .findOne({ where: { type: settings.default_role } });

    if (!role) {
      throw new ApplicationError(i18n.__("errors.find-default-role"));
    }

    const user = await strapi.query("plugin::users-permissions.user").findOne({
      where: {
        username: {
          $eqi: params.username,
        },
      },
    });

    if (user) {
      throw new ApplicationError(i18n.__("errors.nickname-already-taken"));
    }

    params.role = role.id;

    try {
      const user = await strapi
        .query("plugin::users-permissions.user")
        .create({ data: params });

      const sanitizedUser = await sanitizeUser(user, ctx);
      const jwt = issue(_.pick(user, ["id"]));

      return ctx.send({
        jwt,
        user: sanitizedUser,
      });
    } catch (error) {
      if (error.code === "23505" || error.message?.includes("unique")) {
        throw new ApplicationError(i18n.__("errors.nickname-already-taken"));
      }
      throw new ApplicationError(error.message);
    }
  };

  plugin.controllers.auth.forgotPassword = async (ctx) => {
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
  };

  // extending of user's update() method - adding of saving course/class
  plugin.controllers.user.update = async (ctx) => {
    const data = ctx.request.body;
    await strapi.plugins["users-permissions"].services.jwt.getToken(ctx);

    const requesterIsAdmin = await isAdmin(ctx);

    if (!requesterIsAdmin) {
      // Prevent privilege escalation attempts.
      delete data.is_admin;
      delete data.account_type;
      delete data.teacher_approved;
      delete data.is_institution_admin;
    }

    const newPassword = data.password;
    let institutionId = null;
    let courseName = data.course?.replaceAll(" ", "").toLowerCase();

    // adding of relation to the Institution model
    if (data.institution?.name && data.institution?.place_id) {
      const institutions = await strapi.entityService.findMany(
        "api::institution.institution"
      );
      const institutionItem = institutions.find(
        (item) => item.place_id === data.institution.place_id
      );

      if (!institutionItem) {
        const entry = await strapi.entityService.create(
          "api::institution.institution",
          {
            data: {
              name: data.institution.name,
              place_id: data.institution.place_id,
            },
          }
        );

        institutionId = entry.id;
      } else {
        institutionId = institutionItem.id;
      }
    }

    // adding of course to institution
    if (courseName) {
      if (!data.institution?.name || !data.institution?.place_id) {
        throw new ApplicationError(i18n.__("errors.fill-institution"));
      }

      const institutionEntry = await strapi.entityService.findOne(
        "api::institution.institution",
        institutionId
      );

      if (
        !institutionEntry.courses ||
        !institutionEntry.courses.includes(courseName)
      ) {
        await strapi.entityService.update(
          "api::institution.institution",
          institutionId,
          {
            data: {
              courses: institutionEntry.courses
                ? [...institutionEntry.courses, courseName]
                : [courseName],
            },
          }
        );
      }
    }

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
      ...(institutionId && { institution: institutionId }),
      ...(courseName && { course: courseName }),
    };

    const existingForHistory = await strapi.entityService.findOne(
      "plugin::users-permissions.user",
      ctx.params.id,
      { fields: ["email", "username", "old_data"] }
    );
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

    const userRawEntity = await strapi.entityService.update(
      "plugin::users-permissions.user",
      ctx.params.id,
      {
        data: resultData,
        populate: ["institution"],
      }
    );

    return filterObjectByKeys(USER_RESPONSE_EXCLUDED_KEYS, userRawEntity);
  };

  const SPEAKING_RESPONSE_LANGS = ["en", "es", "fr", "de", "it", "hi", "pt", "zh", "ja", "ru"];
  const SPEAKING_TRANSLATION_LANGS = ["none", "en", "es", "fr", "de", "it", "hi", "pt", "zh", "ja", "ru"];
  const PRACTICE_LANGUAGE_CODES = ["en", "es", "fr", "de", "it", "pt", "zh", "ja", "ru", "hi"];

  plugin.controllers.user.getSpeakingPreferences = async (ctx) => {
    const { id: userId } = await strapi.plugins[
      "users-permissions"
    ].services.jwt.getToken(ctx);
    const user = await strapi.entityService.findOne(
      "plugin::users-permissions.user",
      userId,
      {
        fields: [
          "practice_language",
          "confirm_transcript",
          "auto_save_corrections",
          "response_language",
          "translation_language",
          "show_translations",
          "auto_play_voice",
          "auto_conversation",
          "sound",
          "type_messages_enabled",
          "auto_start_recording",
          "daily_reminder_enabled",
          "daily_reminder_time",
          "correct_sentence_goal",
          "english_level",
        ],
      }
    );
    ctx.send({
      practice_language: user?.practice_language ?? "en",
      confirm_transcript: user?.confirm_transcript !== false,
      auto_save_corrections: user?.auto_save_corrections !== false,
      response_language: user?.response_language ?? "en",
      translation_language: user?.translation_language ?? "none",
      show_translations: user?.show_translations === true,
      auto_play_voice: user?.auto_play_voice !== false,
      auto_conversation: user?.auto_conversation === true,
      sound_on: user?.sound !== false,
      type_messages_enabled: user?.type_messages_enabled === true,
      auto_start_recording: user?.auto_start_recording === true,
      daily_reminder_enabled: user?.daily_reminder_enabled === true,
      daily_reminder_time: user?.daily_reminder_time ?? "09:00",
      correct_sentence_goal: user?.correct_sentence_goal ?? 10,
      english_level: user?.english_level ?? null,
    });
  };

  plugin.controllers.user.updateSpeakingPreferences = async (ctx) => {
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
    if (body.confirm_transcript != null) {
      data.confirm_transcript = body.confirm_transcript === true;
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
      const levels = ["A1", "A2", "B1", "B2", "C1", "C2"];
      if (!levels.includes(body.english_level)) {
        return ctx.badRequest("Invalid english_level");
      }
      data.english_level = body.english_level;
    }

    if (Object.keys(data).length === 0) {
      return ctx.badRequest("No speaking preference fields provided");
    }

    try {
      const updated = await strapi.entityService.update(
        "plugin::users-permissions.user",
        userId,
        { data }
      );
      ctx.send({
        practice_language: updated.practice_language ?? "en",
        confirm_transcript: updated.confirm_transcript !== false,
        auto_save_corrections: updated.auto_save_corrections !== false,
        response_language: updated.response_language,
        translation_language: updated.translation_language,
        show_translations: updated.show_translations,
        auto_play_voice: updated.auto_play_voice,
        auto_conversation: updated.auto_conversation,
        sound_on: updated.sound !== false,
        type_messages_enabled: updated.type_messages_enabled === true,
        auto_start_recording: updated.auto_start_recording === true,
        daily_reminder_enabled: updated.daily_reminder_enabled === true,
        daily_reminder_time: updated.daily_reminder_time ?? "09:00",
        correct_sentence_goal: updated.correct_sentence_goal ?? 10,
        english_level: updated.english_level ?? null,
      });
    } catch (err) {
      throw err;
    }
  };

  plugin.controllers.user.deleteNicknamedUser = async (ctx) => {
    return await strapi.entityService.delete(
      "plugin::users-permissions.user",
      ctx.params.id
    );
  };

  plugin.routes["content-api"].routes.push(
    {
      method: "GET",
      path: "/get-points",
      handler: "user.getPoints",
      config: {
        prefix: "",
      },
    },
    {
      method: "GET",
      path: "/get-stats/:id",
      handler: "user.getUserStats",
      config: {
        prefix: "",
      },
    },
    {
      method: "GET",
      path: "/get-rankings",
      handler: "user.getUserRankings",
      config: {
        prefix: "",
      },
    },
    {
      method: "GET",
      path: "/get-answers-stats",
      handler: "user.getMyAnswersStats",
      config: {
        prefix: "",
      },
    },
    {
      method: "GET",
      path: "/get-user-status",
      handler: "user.getUserStatus",
      config: {
        prefix: "",
      },
    },
    {
      method: "GET",
      path: "/admin/app-activity-stats",
      handler: "user.getAppActivityStats",
      config: {
        prefix: "",
      },
    },
    {
      method: "POST",
      path: "/auth/local/register-nicknamed-user",
      handler: "auth.registerNicknamedUser",
      config: {
        prefix: "",
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
