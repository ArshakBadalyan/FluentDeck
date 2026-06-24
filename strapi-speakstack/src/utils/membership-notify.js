"use strict";

const i18n = require("../i18n-helper");
const { sendPushToUser } = require("./onesignal");

const USER_UID = "plugin::users-permissions.user";
const NOTIFICATION_UID = "api::notification.notification";
const CLASSROOM_UID = "api::classroom.classroom";

async function loadUserPushTarget(userId) {
  const user = await strapi.entityService.findOne(USER_UID, userId, {
    fields: ["id", "push_subscribed"],
  });
  if (!user?.push_subscribed) return null;
  return user;
}

async function createInAppNotification(userId, { titleDe, titleEn, textDe, textEn, metadata }) {
  await strapi.entityService.create(NOTIFICATION_UID, {
    data: {
      title: titleDe,
      text: textDe,
      type: "class_membership",
      read: false,
      metadata: metadata ?? null,
      users_permissions_user: userId,
      publishedAt: new Date(),
    },
  });
}

async function pushToUser(userId, { titleDe, titleEn, textDe, textEn, data }) {
  if (!process.env.ONESIGNAL_APP_ID || !process.env.ONESIGNAL_REST_API_KEY) {
    return false;
  }
  const user = await loadUserPushTarget(userId);
  if (!user) return false;
  await sendPushToUser(user.id, {
    headings: { en: titleEn, de: titleDe },
    contents: { en: textEn, de: textDe },
    data: data ?? {},
  });
  return true;
}

async function notifyTeacherMembershipEvent(classroomId, studentUserId, event) {
  const classroom = await strapi.entityService.findOne(CLASSROOM_UID, classroomId, {
    fields: ["id", "name"],
    populate: { teacher: { fields: ["id"] } },
  });
  if (!classroom) return;

  const teacherId = classroom.teacher?.id ?? classroom.teacher;
  if (!teacherId) return;

  const student = await strapi.entityService.findOne(USER_UID, studentUserId, {
    fields: ["id", "username"],
  });
  const studentName = student?.username ?? "Student";
  const classroomName = classroom.name ?? "";

  const phraseKey = `notifications.class-membership.teacher-${event}`;
  const titleDe = i18n.__({ phrase: `${phraseKey}.title`, locale: "de" });
  const titleEn = i18n.__({ phrase: `${phraseKey}.title`, locale: "en" });
  const textDe = i18n.__(
    { phrase: `${phraseKey}.text`, locale: "de" },
    { student: studentName, classroom: classroomName },
  );
  const textEn = i18n.__(
    { phrase: `${phraseKey}.text`, locale: "en" },
    { student: studentName, classroom: classroomName },
  );

  const metadata = {
    event,
    classroom_id: classroomId,
    student_id: studentUserId,
    role: "teacher",
  };

  try {
    await createInAppNotification(teacherId, {
      titleDe,
      titleEn,
      textDe,
      textEn,
      metadata,
    });
    await pushToUser(teacherId, {
      titleDe,
      titleEn,
      textDe,
      textEn,
      data: { type: "class_membership", ...metadata },
    });
  } catch (err) {
    strapi.log.warn(`[membership-notify] teacher ${event}: ${err?.message}`);
  }
}

async function notifyStudentMembershipEvent(studentUserId, classroomId, event) {
  const classroom = await strapi.entityService.findOne(CLASSROOM_UID, classroomId, {
    fields: ["id", "name"],
  });
  const classroomName = classroom?.name ?? "";

  const phraseKey = `notifications.class-membership.student-${event}`;
  const titleDe = i18n.__({ phrase: `${phraseKey}.title`, locale: "de" });
  const titleEn = i18n.__({ phrase: `${phraseKey}.title`, locale: "en" });
  const textDe = i18n.__(
    { phrase: `${phraseKey}.text`, locale: "de" },
    { classroom: classroomName },
  );
  const textEn = i18n.__(
    { phrase: `${phraseKey}.text`, locale: "en" },
    { classroom: classroomName },
  );

  const metadata = {
    event,
    classroom_id: classroomId,
    role: "student",
  };

  try {
    await createInAppNotification(studentUserId, {
      titleDe,
      titleEn,
      textDe,
      textEn,
      metadata,
    });
    await pushToUser(studentUserId, {
      titleDe,
      titleEn,
      textDe,
      textEn,
      data: { type: "class_membership", ...metadata },
    });
  } catch (err) {
    strapi.log.warn(`[membership-notify] student ${event}: ${err?.message}`);
  }
}

module.exports = {
  notifyTeacherMembershipEvent,
  notifyStudentMembershipEvent,
};
