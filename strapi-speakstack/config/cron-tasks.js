const moment = require("moment");
const utils = require("@strapi/utils");
const { getUserDate } = require("../src/utils/dates");
const { ApplicationError } = utils.errors;
const i18n = require("../src/i18n-helper");
const constants = require("../src/constants");
const plugins = require("../config/plugins");
const {
  sendTemplateNotification,
} = require("../src/utils/onesignal");
const { isStaleEverydayGoalPassed } = require("../src/utils/everyday-goal-passed");

i18n.init();

module.exports = {
  /**
   * Send reports to parents' emails.
   * Every day at 11am (Europe/Berlin timezone).
   */
  sendReportsToEmails: {
    task: async ({ strapi }) => {
      strapi.log.info("[cron] sendReportsToEmails start");
      const emails = await strapi.entityService.findMany(
        "api::parents-email.parents-email",
        {
          populate: {
            users_permissions_users: {
              populate: {
                institution: {
                  fields: ["id", "name"],
                },
              },
            },
          },
        }
      );

      return await Promise.all(
        emails.map(async (email) => {
          const digestUnsubscribeBaseUrl = String(
            process.env.PARENT_DAILY_REPORT_UNSUBSCRIBE_URL ||
              "https://schulmatheapp.de/unsubscribe.php"
          ).replace(/\/$/, "");

          const usersReports = (
            await Promise.all(
              email.users_permissions_users.map(async (user) => {
                const userName =
                  user.name && user.surname
                    ? `${user.name} ${user.surname}`
                    : user.username;

                const appendUnsubscribePrefix = (fragment) => {
                  const parentEmail = String(email.email || "").trim();
                  const params = new URLSearchParams({
                    name: userName,
                    "subscription-email": parentEmail,
                  });
                  const href = `${digestUnsubscribeBaseUrl}?${params.toString()}`;
                  const linkText = i18n.__("daily-report.unsubscribe-user");
                  return `<p style="margin:0 0 12px 0;"><a href="${href}" style="color:#0969da;text-decoration:underline;font-size:14px;">${linkText}</a></p>${fragment}`;
                };

                const timezone =
                  user.user_timezone || constants.DEFAULT_TIMEZONE;
                const yesterday = moment()
                  .tz(timezone)
                  .add(-1, "days")
                  .set({ hour: 0, minute: 0, second: 0, millisecond: 0 })
                  .format("YYYY-MM-DD HH:mm:ss.SSSSSS");
                const today = moment()
                  .tz(timezone)
                  .set({ hour: 0, minute: 0, second: 0, millisecond: 0 })
                  .format("YYYY-MM-DD HH:mm:ss.SSSSSS");

                const { rows: topicAnswersRows } =
                  await strapi.db.connection.raw(
                    `SELECT status, COUNT(status) FROM user_answers
                      INNER JOIN user_answers_users_permissions_user_links
                      ON user_answers.id = user_answers_users_permissions_user_links.user_answer_id
                      WHERE user_id = ${user.id}
                      AND user_answers.answer_type = 'topic'
                      AND user_answers.created_at >= TIMESTAMP  '${yesterday}' AT TIME ZONE  '${timezone}'
                      AND user_answers.created_at < TIMESTAMP  '${today}' AT TIME ZONE  '${timezone}'
                      GROUP BY status;
                    `
                  );

                const { rows: practiceRows } = await strapi.db.connection.raw(
                  `SELECT result, COUNT(result) FROM practice_results
                      INNER JOIN practice_results_users_permissions_user_links
                      ON practice_results.id = practice_results_users_permissions_user_links.practice_result_id
                      WHERE user_id = ${user.id}
                      AND practice_results.created_at >= TIMESTAMP  '${yesterday}' AT TIME ZONE  '${timezone}'
                      AND practice_results.created_at < TIMESTAMP  '${today}' AT TIME ZONE  '${timezone}'
                      GROUP BY result`
                );

                const users = await strapi.entityService.findMany(
                  "plugin::users-permissions.user",
                  {
                    fields: ["id", "points", "country", "city", "course"],
                    populate: { institution: true },
                    sort: { points: "desc" },
                  }
                );
                const countryUsers = user.country
                  ? users.filter((u) => u.country === user.country)
                  : [];
                const cityUsers = user.city
                  ? users.filter((u) => u.city === user.city)
                  : [];
                const institutionUsers = user.institution
                  ? users.filter(
                      (u) => u.institution?.id === user.institution.id
                    )
                  : [];
                const courseUsers =
                  user.institution && user.course
                    ? users.filter(
                        (u) =>
                          u.institution?.id === user.institution.id &&
                          u.course === user.course
                      )
                    : [];

                const rankings = {
                  world: users.findIndex((u) => u.id === user.id) + 1,
                  country:
                    countryUsers.findIndex((u) => u.id === user.id) + 1 || null,
                  city:
                    cityUsers.findIndex((u) => u.id === user.id) + 1 || null,
                  institution:
                    institutionUsers.findIndex((u) => u.id === user.id) + 1 ||
                    null,
                  course:
                    courseUsers.findIndex((u) => u.id === user.id) + 1 || null,
                };

                let rankReport;

                if (rankings.course) {
                  rankReport = `${i18n.__("daily-report.has-points", {
                    username: userName,
                    points: user.points,
                  })} ${i18n.__("daily-report.world-rank", {
                    rankWorld: rankings.world,
                  })}, ${i18n.__("daily-report.rank-in", {
                    level: user.country,
                    rank: rankings.country,
                  })}, ${i18n.__("daily-report.rank-in", {
                    level: user.city,
                    rank: rankings.city,
                  })}, ${i18n.__("daily-report.rank-in", {
                    level: user.institution.name,
                    rank: rankings.institution,
                  })} ${i18n.__("daily-report.class-rank", {
                    class: user.course,
                    username: userName,
                    rankClass: rankings.course,
                  })}`;
                } else if (rankings.institution) {
                  rankReport = `${i18n.__("daily-report.has-points", {
                    username: userName,
                    points: user.points,
                  })} ${i18n.__("daily-report.world-rank", {
                    rankWorld: rankings.world,
                  })}, ${i18n.__("daily-report.rank-in", {
                    level: user.country,
                    rank: rankings.country,
                  })}, ${i18n.__("daily-report.rank-in", {
                    level: user.city,
                    rank: rankings.city,
                  })}, ${i18n.__("daily-report.rank-in", {
                    level: user.institution.name,
                    rank: rankings.institution,
                  })}.`;
                } else if (rankings.city) {
                  rankReport = `${i18n.__("daily-report.has-points", {
                    username: userName,
                    points: user.points,
                  })} ${i18n.__("daily-report.world-rank", {
                    rankWorld: rankings.world,
                  })}, ${i18n.__("daily-report.rank-in", {
                    level: user.country,
                    rank: rankings.country,
                  })}, ${i18n.__("daily-report.rank-in", {
                    level: user.city,
                    rank: rankings.city,
                  })}.`;
                } else if (rankings.country) {
                  rankReport = `${i18n.__("daily-report.has-points", {
                    username: userName,
                    points: user.points,
                  })} ${i18n.__("daily-report.world-rank", {
                    rankWorld: rankings.world,
                  })}, ${i18n.__("daily-report.rank-in", {
                    level: user.country,
                    rank: rankings.country,
                  })}.`;
                } else {
                  rankReport = `${i18n.__("daily-report.has-points", {
                    username: userName,
                    points: user.points,
                  })} ${i18n.__("daily-report.world-rank", {
                    rankWorld: rankings.world,
                  })}.`;
                }

                if (!topicAnswersRows.length && !practiceRows.length) {
                  return appendUnsubscribePrefix(
                    `${i18n.__("daily-report.has-no-activity", {
                      username: userName,
                    })}<br>${rankReport}`
                  );
                }

                const answeredQuestionsCount = topicAnswersRows
                  .filter((row) => row.status !== "skipped")
                  .reduce((acc, row) => acc + parseInt(row.count), 0);
                const correctAnswersCount =
                  topicAnswersRows.find((row) => row.status === "correct")
                    ?.count || 0;
                const wrongAnswersCount =
                  topicAnswersRows.find((row) => row.status === "wrong")
                    ?.count || 0;
                const skippedAnswersCount =
                  topicAnswersRows.find((row) => row.status === "skipped")
                    ?.count || 0;

                const playedPractices = practiceRows.reduce(
                  (acc, row) => acc + parseInt(row.count),
                  0
                );
                const wonPracticesCount =
                  practiceRows.find((row) => row.result === "win")?.count || 0;
                const lostPracticesCount =
                  practiceRows.find((row) => row.result === "lose")?.count || 0;
                const drawPracticesCount =
                  practiceRows.find((row) => row.result === "draw")?.count || 0;

                const answeredQuestionsReport = `${i18n.__(
                  "daily-report.has-answered-questions",
                  {
                    username: userName,
                    questions: answeredQuestionsCount,
                  }
                )}. ${i18n.__("daily-report.answered-questions-details", {
                  correctQuestions: correctAnswersCount,
                  wrongQuestions: wrongAnswersCount,
                  skippedQuestions: skippedAnswersCount,
                })}.
                  `;

                const playedPracticesPhrase = topicAnswersRows.length
                  ? "daily-report.has-played-practices"
                  : "daily-report.has-played-practices-first";
                const playedPracticesReport = `
                    ${i18n.__(playedPracticesPhrase, {
                      username: userName,
                      practices: playedPractices,
                    })}. ${i18n.__("daily-report.played-practices-details", {
                  wonPractices: wonPracticesCount,
                  lostPractices: lostPracticesCount,
                  drawPractices: drawPracticesCount,
                })}.
                  `;

                if (topicAnswersRows.length && !practiceRows.length) {
                  return appendUnsubscribePrefix(
                    `${answeredQuestionsReport}<br>${rankReport}`
                  );
                }

                if (!topicAnswersRows.length && practiceRows.length) {
                  return appendUnsubscribePrefix(
                    `${playedPracticesReport}<br>${rankReport}`
                  );
                }

                return appendUnsubscribePrefix(
                  `${answeredQuestionsReport}.<br>${playedPracticesReport}<br>${rankReport}`
                );
              })
            )
          ).join("<br><br>");

          const reportDate = moment()
            .tz("Europe/Berlin")
            .add(-1, "days")
            .set({ hour: 0, minute: 0, second: 0, millisecond: 0 })
            .format("DD.MM.YYYY");

          const reportMessage = `
            <p>${i18n.__("daily-report.title")}</p>
            <p>${i18n.__("daily-report.subtitle", { date: reportDate })}</p>
            <br>
            ${usersReports}
            <br>
            <br>
            <p>${i18n.__("daily-report.thanks")}</p>
            <br>
            <p>${i18n.__("daily-report.br")}</p>
            <p>${i18n.__("daily-report.sender")}</p>
            <div style="margin-bottom: 16px">
              <img width="101" height="87" src="https://schulmatheapp.de/images/logo/matheapp.gif" alt="Mathe App Logo">
            </div>
            <div style="margin-bottom: 16px">
              <a href="schulmatheapp.de">MatheApp</a>
            </div>
            <div style="margin-bottom: 16px">
                <a href="mailto:leonie@schulmatheapp.de">leonie@schulmatheapp.de</a>
            </div>
            <div style="margin-bottom: 16px;">
              <a href="https://apps.apple.com/de/app/matheappde/id6447060725">
                <img width="180" height="60" src="https://schulmatheapp.de/images/remote/app-store.png" alt="Download in App Store">
              </a>
            </div>
            <div style="margin-bottom: 16px;">
              <a href="https://play.google.com/store/apps/details?id=io.framework7.matheapp">
                <img width="180" height="54" src="https://schulmatheapp.de/images/remote/play-market.png" alt="Download in Google Play">
              </a>
            </div>
            <div style="margin-bottom: 32px">
                <a href="https://schulmatheapp.de/#contact-us" style="text-decoration: none;color: inherit;">${i18n.__("daily-report.subscribe-unsubscribe")}</a>
            </div>
          `;

          const emailToSend = {
            to: email.email,
            from: process.env.SMTP_USERNAME
              ? `"${i18n.__("daily-report.sender")}" <${process.env.SMTP_USERNAME}>`
              : plugins.email.config.settings.defaultFrom,
            subject: i18n.__("daily-report.daily-report"),
            text: reportMessage,
            html: reportMessage,
          };

          await strapi.plugin("email").service("email").send(emailToSend);

          return { ok: true };
        })
      );
      strapi.log.info(
        `[cron] sendReportsToEmails done (recipients=${emails.length})`
      );
    },
    options: {
      rule: "0 10 * * *",
      tz: "Europe/Berlin",
    },
  },
  /**
   * Send reminder notifications to users who have not finished their everyday goal.
   * Runs every hour; sends up to 3 reminders per day at 13:00, 17:00 and 20:00
   * in each user's local timezone.
   */
  notifyAboutUnfinishedGoal: {
    task: async ({ strapi }) => {
      try {
      const REMINDER_HOURS = [13, 17, 20];
      strapi.log.info("[cron] notifyAboutUnfinishedGoal tick");

      // Clear everyday_goal_passed when it refers to a previous calendar day in the
      // user's timezone (e.g. Flutter clients that never reset it). Otherwise they
      // stay excluded from reminders and from goal-completion logic.
      const usersWithGoalPassedSet = await strapi.entityService.findMany(
        "plugin::users-permissions.user",
        {
          fields: ["id", "user_timezone", "everyday_goal_passed"],
          filters: {
            everyday_goal: { $notNull: true },
            everyday_goal_passed: { $notNull: true },
          },
        }
      );

      const stalePassedUserIds = usersWithGoalPassedSet
        .filter((u) => isStaleEverydayGoalPassed(u))
        .map((u) => u.id);

      if (stalePassedUserIds.length) {
        await Promise.all(
          stalePassedUserIds.map((id) =>
            strapi.entityService.update(
              "plugin::users-permissions.user",
              id,
              { data: { everyday_goal_passed: null } }
            )
          )
        );
        strapi.log.info(
          `[cron] notifyAboutUnfinishedGoal: cleared stale everyday_goal_passed for ${stalePassedUserIds.length} user(s)`
        );
      }

      const usersWithUnfinishedGoal = await strapi.entityService.findMany(
        "plugin::users-permissions.user",
        {
          populate: {
            institution: true,
            notifications: {
              filters: {
                type: {
                  $eq: "unfinished_goal",
                },
              },
            },
          },
          filters: {
            special: {
              $eq: false,
            },
            push_subscribed: {
              $eq: true,
            },
            everyday_goal: {
              $notNull: true,
            },
            everyday_goal_passed: {
              $null: true,
            },
          },
        }
      );

      const eligibleUsers = usersWithUnfinishedGoal.filter((u) => {
        const timezone = u.user_timezone || constants.DEFAULT_TIMEZONE;
        const userCurrentDate = getUserDate(timezone);

        const todayNotificationCount = u.notifications.filter((n) => {
          const notificationDate = new Intl.DateTimeFormat("sv-SE", {
            dateStyle: "short",
            timeZone: timezone,
          }).format(new Date(n.createdAt));
          return userCurrentDate === notificationDate;
        }).length;

        const userHour = parseInt(
          new Intl.DateTimeFormat("en-US", {
            hour: "numeric",
            hour12: false,
            timeZone: timezone,
          }).format(new Date()),
          10
        );

        const passedSlots = REMINDER_HOURS.filter((h) => userHour >= h).length;

        return todayNotificationCount < passedSlots;
      });

      strapi.log.info(
        `[cron] notifyAboutUnfinishedGoal: candidates=${usersWithUnfinishedGoal.length} eligible=${eligibleUsers.length}`
      );

      if (!eligibleUsers.length) return;

      await Promise.all(
        eligibleUsers.map((u) => {
          const notificationTitle = i18n.__(
            "notifications.not-reached-everyday-goal.title"
          );
          const notificationText = i18n.__(
            "notifications.not-reached-everyday-goal.text"
          );

          return sendTemplateNotification(
            u.id,
            process.env.ONESIGNAL_UNFINISHED_GOAL_TEMPLATE_ID
          )
            .then(async () => {
              return strapi.entityService.create(
                "api::notification.notification",
                {
                  data: {
                    title: notificationTitle,
                    text: notificationText,
                    users_permissions_user: u.id,
                    read: false,
                    type: "unfinished_goal",
                    createdAt: new Date(),
                    publishedAt: new Date(),
                  },
                  populate: {
                    users_permissions_user: true,
                  },
                }
              );
            })
            .catch(function (error) {
              strapi.log.error(
                `OneSignal unfinished goal notification failed for user ${u.id}:`,
                error
              );
            });
        })
      );
      strapi.log.info(
        `[cron] notifyAboutUnfinishedGoal: finished (${eligibleUsers.length} user(s))`
      );
      } catch (err) {
        strapi.log.error("[cron] notifyAboutUnfinishedGoal failed:", err);
      }
    },
    options: {
      rule: "0 * * * *",
    },
  },

  /**
   * Weekly class summary email to teachers (Monday 08:00 Europe/Berlin).
   * Only classrooms with weekly_report_enabled = true.
   */
  sendWeeklyClassReports: {
    task: async ({ strapi }) => {
      strapi.log.info("[cron] sendWeeklyClassReports start");
      try {
        const { sendClassReportEmail } = require("../src/utils/class-report");
        const classrooms = await strapi.entityService.findMany(
          "api::classroom.classroom",
          {
            filters: { archived: false, weekly_report_enabled: true },
            fields: ["id", "name"],
            limit: -1,
          }
        );

        let sent = 0;
        for (const classroom of classrooms ?? []) {
          try {
            const result = await sendClassReportEmail(classroom.id);
            if (result.ok) sent += 1;
          } catch (err) {
            strapi.log.warn(
              `[cron] weekly class report failed for classroom ${classroom.id}: ${err?.message}`
            );
          }
        }
        strapi.log.info(
          `[cron] sendWeeklyClassReports finished (${sent}/${(classrooms ?? []).length})`
        );
      } catch (err) {
        strapi.log.error("[cron] sendWeeklyClassReports failed:", err);
      }
    },
    options: {
      rule: "0 8 * * 1",
      tz: "Europe/Berlin",
    },
  },
};
