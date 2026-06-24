"use strict";

const i18n = require("../i18n-helper");
const {
  sendTemplateNotification,
  sendPushToUser,
} = require("./onesignal");
const { loadActiveStudentIds } = require("./assignment-progress");

const USER_UID = "plugin::users-permissions.user";
const NOTIFICATION_UID = "api::notification.notification";

function stripRichText(html) {
  if (typeof html !== "string") return "";
  return html.replace(/<[^>]+>/g, " ").replace(/\s+/g, " ").trim();
}

async function notifyStudentsNewAssignment(classroomId, assignment, classroomName) {
  if (!process.env.ONESIGNAL_APP_ID || !process.env.ONESIGNAL_REST_API_KEY) {
    strapi.log.warn(
      "[assignment-notify] OneSignal not configured; skipping push.",
    );
    return { sent: 0, skipped: true };
  }

  const studentIds = await loadActiveStudentIds(classroomId);
  if (!studentIds.length) {
    return { sent: 0, skipped: false };
  }

  const users = await strapi.entityService.findMany(USER_UID, {
    filters: {
      id: { $in: studentIds },
      push_subscribed: true,
    },
    fields: ["id"],
    limit: studentIds.length,
  });

  if (!users?.length) {
    return { sent: 0, skipped: false };
  }

  const templateId = process.env.ONESIGNAL_NEW_ASSIGNMENT_TEMPLATE_ID;
  const titleDe = i18n.__({ phrase: "notifications.new-assignment.title", locale: "de" });
  const titleEn = i18n.__({ phrase: "notifications.new-assignment.title", locale: "en" });
  const textDe = i18n.__(
    { phrase: "notifications.new-assignment.text", locale: "de" },
    { title: assignment.title, classroom: classroomName ?? "" },
  );
  const textEn = i18n.__(
    { phrase: "notifications.new-assignment.text", locale: "en" },
    { title: assignment.title, classroom: classroomName ?? "" },
  );

  let sent = 0;
  for (const user of users) {
    try {
      if (templateId) {
        await sendTemplateNotification(user.id, templateId, {
          assignment_title: assignment.title,
          classroom_name: classroomName ?? "",
          assignment_id: assignment.id,
        });
      } else {
        await sendPushToUser(user.id, {
          headings: { en: titleEn, de: titleDe },
          contents: { en: textEn, de: textDe },
          data: {
            type: "new_assignment",
            assignmentId: assignment.id,
            classroomId,
          },
        });
      }

      await strapi.entityService.create(NOTIFICATION_UID, {
        data: {
          title: titleDe,
          text: textDe,
          type: "assignment",
          read: false,
          metadata: {
            assignment_id: assignment.id,
            classroom_id: classroomId,
          },
          users_permissions_user: user.id,
          publishedAt: new Date(),
        },
      });
      sent += 1;
    } catch (err) {
      strapi.log.warn(
        `[assignment-notify] push failed for user ${user.id}: ${err?.message}`,
      );
    }
  }

  strapi.log.info(
    `[assignment-notify] classroom ${classroomId} assignment ${assignment.id}: sent=${sent}/${users.length}`,
  );
  return { sent, skipped: false };
}

async function notifyTeacherSolutionBeforeAnswer({
  teacherId,
  student,
  assignment,
  classroom,
  question,
}) {
  if (!teacherId) return;

  const studentName = student?.username ?? "Student";
  const assignmentTitle = assignment?.title ?? "Assignment";
  const classroomName = classroom?.name ?? "";
  const exerciseLabel = stripRichText(question?.question);
  const shortLabel =
    exerciseLabel.length > 80
      ? `${exerciseLabel.slice(0, 77)}...`
      : exerciseLabel || `Exercise #${question?.id ?? ""}`;

  const titleDe = i18n.__({
    phrase: "notifications.assignment-solution-before-answer.title",
    locale: "de",
  });
  const titleEn = i18n.__({
    phrase: "notifications.assignment-solution-before-answer.title",
    locale: "en",
  });
  const textDe = i18n.__(
    { phrase: "notifications.assignment-solution-before-answer.text", locale: "de" },
    {
      student: studentName,
      assignment: assignmentTitle,
      exercise: shortLabel,
      classroom: classroomName,
    },
  );
  const textEn = i18n.__(
    { phrase: "notifications.assignment-solution-before-answer.text", locale: "en" },
    {
      student: studentName,
      assignment: assignmentTitle,
      exercise: shortLabel,
      classroom: classroomName,
    },
  );

  const metadata = {
    event: "solution_before_answer",
    assignment_id: assignment.id,
    question_id: question?.id ?? null,
    student_id: student?.id ?? null,
    classroom_id: classroom?.id ?? classroom ?? null,
    role: "teacher",
  };

  try {
    await strapi.entityService.create(NOTIFICATION_UID, {
      data: {
        title: titleDe,
        text: textDe,
        type: "assignment",
        read: false,
        metadata,
        users_permissions_user: teacherId,
        publishedAt: new Date(),
      },
    });

    if (process.env.ONESIGNAL_APP_ID && process.env.ONESIGNAL_REST_API_KEY) {
      const user = await strapi.entityService.findOne(USER_UID, teacherId, {
        fields: ["id", "push_subscribed"],
      });
      if (user?.push_subscribed) {
        await sendPushToUser(teacherId, {
          headings: { en: titleEn, de: titleDe },
          contents: { en: textEn, de: textDe },
          data: {
            type: "assignment_solution_before_answer",
            ...metadata,
          },
        });
      }
    }
  } catch (err) {
    strapi.log.warn(
      `[assignment-notify] solution before answer: ${err?.message}`,
    );
  }
}

module.exports = {
  notifyStudentsNewAssignment,
  notifyTeacherSolutionBeforeAnswer,
  stripRichText,
};
