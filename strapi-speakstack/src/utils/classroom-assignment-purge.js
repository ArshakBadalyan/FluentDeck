"use strict";

const ASSIGNMENT_UID = "api::assignment.assignment";
const CLASSROOM_UID = "api::classroom.classroom";
const ANSWER_UID = "api::user-answer.user-answer";
const {
  listMemberships,
  loadStudentActiveClassroomIds,
} = require("./classroom-membership");
const {
  normalizeTargets,
  questionIdsForTarget,
} = require("./assignment-progress");

async function collectQuestionIdsForClassroom(classroomId) {
  const assignments = await strapi.entityService.findMany(ASSIGNMENT_UID, {
    filters: { classroom: classroomId },
    fields: ["id", "targets"],
    limit: -1,
  });

  const questionIds = new Set();
  for (const assignment of assignments ?? []) {
    for (const target of normalizeTargets(assignment.targets)) {
      const qids = await questionIdsForTarget(target);
      for (const id of qids) questionIds.add(id);
    }
  }
  return questionIds;
}

async function collectStudentIdsForClassroom(classroomId) {
  const ids = new Set();
  const members = await listMemberships(classroomId);
  for (const m of members ?? []) {
    const uid = m.user?.id ?? m.user;
    if (uid) ids.add(Number(uid));
  }

  const classroom = await strapi.entityService.findOne(
    CLASSROOM_UID,
    classroomId,
    { populate: { students: { fields: ["id"] } } },
  );
  for (const s of classroom?.students ?? []) {
    const id = s?.id ?? s;
    if (id) ids.add(Number(id));
  }
  return ids;
}

async function questionIdsStillNeededByStudent(userId, candidateQuestionIds) {
  if (!candidateQuestionIds.size) return new Set();

  const activeClassroomIds = await loadStudentActiveClassroomIds(userId);
  if (!activeClassroomIds.length) return new Set();

  const stillNeeded = new Set();
  const activeAssignments = await strapi.entityService.findMany(ASSIGNMENT_UID, {
    filters: {
      classroom: { id: { $in: activeClassroomIds } },
      archived: false,
      published: true,
    },
    fields: ["targets"],
    limit: -1,
  });

  for (const assignment of activeAssignments ?? []) {
    for (const target of normalizeTargets(assignment.targets)) {
      const qids = await questionIdsForTarget(target);
      for (const qid of qids) {
        if (candidateQuestionIds.has(qid)) stillNeeded.add(qid);
      }
    }
  }
  return stillNeeded;
}

async function deleteTopicAnswersForUser(userId, questionIds) {
  if (!questionIds.length) return 0;

  const answers = await strapi.entityService.findMany(ANSWER_UID, {
    filters: {
      users_permissions_user: { id: userId },
      question: { id: { $in: questionIds } },
      answer_type: { $eq: "topic" },
    },
    fields: ["id"],
    limit: -1,
  });

  let deleted = 0;
  for (const row of answers ?? []) {
    await strapi.entityService.delete(ANSWER_UID, row.id);
    deleted += 1;
  }
  return deleted;
}

/**
 * Remove topic answers for assignment exercises in [classroomId].
 * Keeps answers when the same exercise is still assigned in another active class.
 */
async function purgeClassroomAssignmentProgress(classroomId) {
  const questionIds = await collectQuestionIdsForClassroom(classroomId);
  if (!questionIds.size) {
    return { students: 0, answersRemoved: 0 };
  }

  const studentIds = await collectStudentIdsForClassroom(classroomId);
  let answersRemoved = 0;

  for (const userId of studentIds) {
    const stillNeeded = await questionIdsStillNeededByStudent(
      userId,
      questionIds,
    );
    const toRemove = [...questionIds].filter((id) => !stillNeeded.has(id));
    answersRemoved += await deleteTopicAnswersForUser(userId, toRemove);
  }

  return { students: studentIds.size, answersRemoved };
}

async function collectQuestionIdsForAssignment(assignment) {
  const questionIds = new Set();
  for (const target of normalizeTargets(assignment?.targets)) {
    const qids = await questionIdsForTarget(target);
    for (const id of qids) questionIds.add(id);
  }
  return questionIds;
}

/**
 * Remove topic answers for exercises in a single assignment (e.g. when archived).
 * Keeps answers when the same exercise is still assigned elsewhere.
 */
async function purgeAssignmentProgress(assignmentId) {
  const assignment = await strapi.entityService.findOne(ASSIGNMENT_UID, assignmentId, {
    fields: ["id", "targets"],
    populate: { classroom: { fields: ["id"] } },
  });
  if (!assignment) return { students: 0, answersRemoved: 0 };

  const questionIds = await collectQuestionIdsForAssignment(assignment);
  if (!questionIds.size) return { students: 0, answersRemoved: 0 };

  const classroomId = assignment.classroom?.id ?? assignment.classroom;
  const studentIds = classroomId
    ? await collectStudentIdsForClassroom(classroomId)
    : [];

  let answersRemoved = 0;
  for (const userId of studentIds) {
    const stillNeeded = await questionIdsStillNeededByStudent(
      userId,
      questionIds,
    );
    const toRemove = [...questionIds].filter((id) => !stillNeeded.has(id));
    answersRemoved += await deleteTopicAnswersForUser(userId, toRemove);
  }

  return { students: studentIds.size, answersRemoved };
}

module.exports = {
  purgeClassroomAssignmentProgress,
  purgeAssignmentProgress,
  collectQuestionIdsForClassroom,
  collectQuestionIdsForAssignment,
  collectStudentIdsForClassroom,
};
