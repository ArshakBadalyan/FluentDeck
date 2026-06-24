"use strict";

const {
  normalizeTargets,
  questionIdsForTarget,
  buildAssignmentAnswerFilters,
} = require("./assignment-progress");
const { notifyTeacherSolutionBeforeAnswer } = require("./assignment-notify");

const TABLE = "assignment_solution_peeks";
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

async function studentHasAnswerSinceAssignment(userId, questionId, assignment) {
  const answered = await strapi.entityService.findMany(ANSWER_UID, {
    fields: ["id"],
    filters: buildAssignmentAnswerFilters(userId, [questionId], assignment, {
      excludeSkipped: true,
    }),
    limit: 1,
  });
  return (answered ?? []).length > 0;
}

async function recordSolutionPeekBeforeAnswer(assignment, userId, questionId) {
  const allowed = await assignmentQuestionIds(assignment);
  if (!allowed.has(questionId)) {
    return { ok: false, error: "Question not in assignment" };
  }

  if (await studentHasAnswerSinceAssignment(userId, questionId, assignment)) {
    return { ok: false, error: "Already answered" };
  }

  const knex = strapi.db.connection;
  const hasTable = await knex.schema.hasTable(TABLE);
  if (!hasTable) {
    return { ok: false, error: "Peek storage unavailable" };
  }

  const existing = await knex(TABLE)
    .where({
      assignment_id: assignment.id,
      question_id: questionId,
      user_id: userId,
    })
    .first();

  if (existing) {
    return { ok: true, created: false };
  }

  await knex(TABLE).insert({
    assignment_id: assignment.id,
    question_id: questionId,
    user_id: userId,
    created_at: new Date(),
  });

  return { ok: true, created: true };
}

async function reportSolutionPeekBeforeAnswer(assignmentId, userId, questionId) {
  const assignment = await strapi.entityService.findOne(
    ASSIGNMENT_UID,
    assignmentId,
    {
      populate: {
        classroom: {
          fields: ["id", "name", "archived"],
          populate: { teacher: { fields: ["id"] } },
        },
      },
    },
  );

  if (!assignment || assignment.archived || assignment.published !== true) {
    return { ok: false, error: "Assignment not found" };
  }

  const classroom = assignment.classroom;
  if (!classroom || classroom.archived === true) {
    return { ok: false, error: "Assignment not found" };
  }

  const result = await recordSolutionPeekBeforeAnswer(
    assignment,
    userId,
    questionId,
  );
  if (!result.ok) return result;

  if (result.created) {
    const student = await strapi.entityService.findOne(
      "plugin::users-permissions.user",
      userId,
      { fields: ["id", "username"] },
    );
    const question = await strapi.entityService.findOne(
      "api::question.question",
      questionId,
      { fields: ["id", "question"] },
    );

    await notifyTeacherSolutionBeforeAnswer({
      teacherId: classroom.teacher?.id ?? classroom.teacher,
      student,
      assignment,
      classroom,
      question,
    });
  }

  return { ok: true, created: result.created };
}

async function loadPeekCountsByAssignment(userId, assignmentIds) {
  const ids = [...new Set(assignmentIds.map((id) => Number(id)).filter((id) => id > 0))];
  const counts = Object.fromEntries(ids.map((id) => [id, 0]));
  if (!ids.length) return counts;

  const knex = strapi.db.connection;
  const hasTable = await knex.schema.hasTable(TABLE);
  if (!hasTable) return counts;

  const rows = await knex(TABLE)
    .where({ user_id: userId })
    .whereIn("assignment_id", ids)
    .groupBy("assignment_id")
    .select("assignment_id")
    .count("* as count");

  for (const row of rows ?? []) {
    const aid = Number(row.assignment_id);
    if (counts[aid] != null) {
      counts[aid] = Number(row.count) || 0;
    }
  }
  return counts;
}

async function countSolutionPeeksForStudent(userId, assignmentIds) {
  const byAssignment = await loadPeekCountsByAssignment(userId, assignmentIds);
  return Object.values(byAssignment).reduce((sum, n) => sum + n, 0);
}

async function countSolutionPeeksForAssignment(userId, assignmentId) {
  const counts = await loadPeekCountsByAssignment(userId, [assignmentId]);
  return counts[Number(assignmentId)] ?? 0;
}

module.exports = {
  reportSolutionPeekBeforeAnswer,
  loadPeekCountsByAssignment,
  countSolutionPeeksForStudent,
  countSolutionPeeksForAssignment,
};
