"use strict";

const { loadStudentActiveClassroomIds } = require("./classroom-membership");
const {
  normalizeTargets,
  questionIdsForTarget,
} = require("./assignment-progress");

const ASSIGNMENT_UID = "api::assignment.assignment";
const ANSWER_UID = "api::user-answer.user-answer";

async function assignmentQuestionIds(assignment) {
  const ids = new Set();
  for (const target of normalizeTargets(assignment.targets)) {
    const qids = await questionIdsForTarget(target);
    for (const id of qids) ids.add(id);
  }
  return ids;
}

async function validateAssignmentAnswerContext(userId, assignmentId, questionId) {
  const assignment = await strapi.entityService.findOne(
    ASSIGNMENT_UID,
    assignmentId,
    {
      fields: ["id", "archived", "published", "targets"],
      populate: { classroom: { fields: ["id"] } },
    },
  );

  if (!assignment || assignment.archived || assignment.published !== true) {
    return { ok: false, error: "Assignment not found" };
  }

  const classroomId = assignment.classroom?.id ?? assignment.classroom;
  const classroomIds = await loadStudentActiveClassroomIds(userId);
  if (!classroomIds.includes(Number(classroomId))) {
    return { ok: false, error: "Not your assignment" };
  }

  const allowed = await assignmentQuestionIds(assignment);
  if (!allowed.has(questionId)) {
    return { ok: false, error: "Question not in assignment" };
  }

  return { ok: true, assignment };
}

function normalizeAnswerPayload(body) {
  return {
    answer: body.answer ?? "",
    answer_1: body.answer_1 ?? "",
    answer_2: body.answer_2 ?? "",
    answer_3: body.answer_3 ?? "",
    answer_4: body.answer_4 ?? "",
    second_answer: body.second_answer ?? "",
    status: body.status,
    answer_type: "topic",
    category: body.category,
    question: body.question,
    users_permissions_user: body.users_permissions_user,
  };
}

async function upsertAssignmentTopicAnswer({
  userId,
  assignmentId,
  questionId,
  body,
  existingAnswer,
}) {
  const ctx = await validateAssignmentAnswerContext(
    userId,
    assignmentId,
    questionId,
  );
  if (!ctx.ok) return ctx;

  const payload = normalizeAnswerPayload(body);
  const now = new Date();

  await strapi.entityService.update(ANSWER_UID, existingAnswer.id, {
    data: payload,
  });

  const knex = strapi.db.connection;
  await knex("user_answers").where({ id: existingAnswer.id }).update({
    created_at: now,
    updated_at: now,
  });

  const entity = await strapi.entityService.findOne(
    ANSWER_UID,
    existingAnswer.id,
    { populate: ["question", "category", "users_permissions_user"] },
  );

  return {
    ok: true,
    entity,
    previousStatus: existingAnswer.status,
    newStatus: payload.status,
  };
}

module.exports = {
  validateAssignmentAnswerContext,
  upsertAssignmentTopicAnswer,
};
