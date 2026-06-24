'use strict';

const { MEMBERSHIP_STATUS, listMemberships, loadStudentActiveClassroomIds } = require('./classroom-membership');

const PEEK_TABLE = 'assignment_solution_peeks';

async function loadPeekQuestionIds(assignmentId, userId) {
  const knex = strapi.db.connection;
  const hasTable = await knex.schema.hasTable(PEEK_TABLE);
  if (!hasTable) return new Set();
  const rows = await knex(PEEK_TABLE)
    .where({ assignment_id: assignmentId, user_id: userId })
    .select('question_id');
  return new Set(rows.map((r) => Number(r.question_id)).filter((id) => id > 0));
}

const ANSWER_UID = 'api::user-answer.user-answer';
const USER_UID = 'plugin::users-permissions.user';

async function loadActiveStudentIds(classroomId) {
  const memberships = await listMemberships(classroomId, [
    MEMBERSHIP_STATUS.ACTIVE,
  ]);
  const ids = new Set();
  for (const m of memberships ?? []) {
    const uid = m.user?.id ?? m.user;
    if (uid) ids.add(uid);
  }
  return [...ids];
}

function normalizeTargets(raw) {
  if (!Array.isArray(raw)) return [];
  return raw
    .map((t) => {
      const categoryId = Number(t?.categoryId ?? t?.category_id);
      if (!Number.isInteger(categoryId) || categoryId < 1) return null;
      const questionIds = Array.isArray(t?.questionIds ?? t?.question_ids)
        ? (t.questionIds ?? t.question_ids)
            .map((q) => Number(q))
            .filter((q) => Number.isInteger(q) && q > 0)
        : null;
      return { categoryId, questionIds };
    })
    .filter(Boolean);
}

async function questionIdsForTarget(target) {
  if (target.questionIds?.length) {
    return target.questionIds;
  }
  const rows = await strapi.entityService.findMany('api::question.question', {
    fields: ['id'],
    filters: { category: { id: target.categoryId } },
    limit: -1,
  });
  return (rows ?? []).map((q) => q.id);
}

function assignmentAnswerSince(assignment) {
  const raw = assignment?.createdAt ?? assignment?.publishedAt;
  if (!raw) return null;
  const date = new Date(raw);
  return Number.isNaN(date.getTime()) ? null : date;
}

function buildAssignmentAnswerFilters(userId, qids, assignment, { excludeSkipped = false } = {}) {
  const filters = {
    users_permissions_user: { id: userId },
    question: { id: { $in: qids } },
    answer_type: { $eq: 'topic' },
  };
  if (excludeSkipped) {
    filters.status = { $ne: 'skipped' };
  }
  const since = assignmentAnswerSince(assignment);
  if (since) {
    filters.createdAt = { $gte: since };
  }
  return filters;
}

async function answeredQuestionIds(userId, qids, assignment, { excludeSkipped = false } = {}) {
  if (!qids.length) return new Set();

  const answered = await strapi.entityService.findMany(ANSWER_UID, {
    fields: ['id'],
    filters: buildAssignmentAnswerFilters(userId, qids, assignment, {
      excludeSkipped,
    }),
    populate: { question: { fields: ['id'] } },
    limit: -1,
  });

  const unique = new Set();
  for (const row of answered ?? []) {
    const qid = Number(row.question?.id ?? row.question);
    if (Number.isInteger(qid) && qid > 0) unique.add(qid);
  }
  return unique;
}

async function userCompletedTarget(userId, target, assignment) {
  const qids = await questionIdsForTarget(target);
  if (!qids.length) return true;

  const unique = await answeredQuestionIds(userId, qids, assignment, {
    excludeSkipped: true,
  });
  return qids.every((id) => unique.has(id));
}

async function userAssignmentProgress(userId, assignment) {
  const targets = normalizeTargets(assignment.targets);
  if (!targets.length) {
    return {
      completed: true,
      completed_targets: 0,
      total_targets: 0,
      questions_completed: 0,
      questions_total: 0,
    };
  }

  let done = 0;
  let questionsCompleted = 0;
  let questionsTotal = 0;

  for (const target of targets) {
    const qids = await questionIdsForTarget(target);
    if (!qids.length) {
      done += 1;
      continue;
    }
    questionsTotal += qids.length;
    const unique = await answeredQuestionIds(userId, qids, assignment, {
      excludeSkipped: true,
    });
    const answeredCount = qids.filter((id) => unique.has(id)).length;
    questionsCompleted += answeredCount;
    if (answeredCount >= qids.length) {
      done += 1;
    }
  }

  return {
    completed:
      targets.length === 0 ||
      (done === targets.length &&
        (questionsTotal === 0 || questionsCompleted >= questionsTotal)),
    completed_targets: done,
    total_targets: targets.length,
    questions_completed: questionsCompleted,
    questions_total: questionsTotal,
  };
}

async function validateQuestionsInCategory(categoryId, questionIds) {
  if (!questionIds?.length) return true;
  const rows = await strapi.entityService.findMany("api::question.question", {
    fields: ["id"],
    filters: {
      id: { $in: questionIds },
      category: { id: categoryId },
    },
    limit: questionIds.length,
  });
  return (rows ?? []).length === questionIds.length;
}

function stripRichText(html) {
  if (typeof html !== "string") return "";
  return html.replace(/<[^>]+>/g, " ").replace(/\s+/g, " ").trim();
}

function formatUserAnswerRow(row) {
  if (!row) return null;
  const parts = [
    row.answer,
    row.answer_1,
    row.answer_2,
    row.answer_3,
    row.answer_4,
    row.second_answer,
  ]
    .map((v) => (typeof v === "string" ? v.trim() : ""))
    .filter(Boolean);
  return parts.length ? parts.join(" · ") : null;
}

async function enrichAssignmentTargets(
  userId,
  rawTargets,
  { includeCorrectAnswer = false, assignment = null } = {},
) {
  const targets = normalizeTargets(rawTargets);
  const enriched = [];
  const peekQuestionIds =
    userId && assignment?.id
      ? await loadPeekQuestionIds(assignment.id, userId)
      : new Set();

  for (const target of targets) {
    const category = await strapi.entityService.findOne(
      "api::category.category",
      target.categoryId,
      {
        fields: ["id", "name"],
        populate: { category_class: { fields: ["id"] } },
      },
    );
    const qids = await questionIdsForTarget(target);
    const rows = qids.length
      ? await strapi.entityService.findMany("api::question.question", {
          filters: { id: { $in: qids } },
          fields: includeCorrectAnswer
            ? ["id", "question", "answer", "answer_1", "answer_2", "answer_3", "answer_4", "second_answer"]
            : ["id", "question"],
          sort: { id: "asc" },
          limit: qids.length,
        })
      : [];

    const answered = userId
      ? await strapi.entityService.findMany(ANSWER_UID, {
          fields: [
            "id",
            "status",
            "answer",
            "answer_1",
            "answer_2",
            "answer_3",
            "answer_4",
            "second_answer",
          ],
          filters: buildAssignmentAnswerFilters(userId, qids, assignment),
          populate: { question: { fields: ["id"] } },
          limit: qids.length,
        })
      : [];
    const answerByQuestion = new Map();
    for (const a of answered ?? []) {
      const qid = a.question?.id ?? a.question;
      if (qid) answerByQuestion.set(qid, a);
    }

    const questionMap = new Map((rows ?? []).map((q) => [q.id, q]));
    const exercises = qids.map((id, index) => {
      const q = questionMap.get(id);
      const plain = stripRichText(q?.question);
      const ans = answerByQuestion.get(id);
      const status =
        !ans || !ans.status
          ? "unanswered"
          : ans.status === "skipped"
            ? "skipped"
            : ans.status;
      const exercise = {
        id,
        label:
          plain.length > 0
            ? plain.slice(0, 120)
            : `Exercise ${index + 1} (#${id})`,
        completed: status === "correct" || status === "wrong",
        status,
        user_answer: formatUserAnswerRow(ans),
        solution_viewed_before_answer: peekQuestionIds.has(id),
      };
      if (includeCorrectAnswer && q) {
        exercise.correct_answer = formatUserAnswerRow(q);
      }
      return exercise;
    });

    enriched.push({
      categoryId: target.categoryId,
      categoryName: category?.name ?? null,
      categoryClassId: category?.category_class?.id ?? category?.category_class ?? null,
      questionIds: target.questionIds ?? null,
      exercises,
    });
  }

  return enriched;
}

async function buildAssignmentProgressReport(assignment, studentIds) {
  const students = studentIds.length
    ? await strapi.entityService.findMany(USER_UID, {
        filters: { id: { $in: studentIds } },
        fields: ['id', 'username'],
        limit: studentIds.length,
      })
    : [];

  const rows = [];
  for (const student of students ?? []) {
    const progress = await userAssignmentProgress(student.id, assignment);
    rows.push({
      student_id: student.id,
      username: student.username,
      ...progress,
    });
  }
  return rows;
}

function isAssignmentOverdue(assignment) {
  if (!assignment.due_at) return false;
  return new Date(assignment.due_at).getTime() < Date.now();
}

async function getEnforcedBlockedCategoryIds(userId) {
  const classroomIds = await loadStudentActiveClassroomIds(userId);

  if (!classroomIds.length) return [];

  const assignments = await strapi.entityService.findMany(
    'api::assignment.assignment',
    {
      filters: {
        classroom: { id: { $in: classroomIds } },
        archived: false,
        published: true,
        enforcement: 'enforced',
      },
      limit: -1,
    },
  );

  const blocked = new Set();
  for (const assignment of assignments ?? []) {
    if (isAssignmentOverdue(assignment)) continue;
    const progress = await userAssignmentProgress(userId, assignment);
    if (progress.completed) continue;
    for (const target of normalizeTargets(assignment.targets)) {
      blocked.add(target.categoryId);
    }
  }
  return [...blocked];
}

function serializeAssignment(assignment, extra = {}) {
  return {
    id: assignment.id,
    title: assignment.title,
    assignment_type: assignment.assignment_type,
    enforcement: assignment.enforcement,
    due_at: assignment.due_at ?? null,
    published: assignment.published === true,
    archived: assignment.archived === true,
    targets: normalizeTargets(assignment.targets),
    classroom_id: assignment.classroom?.id ?? assignment.classroom ?? null,
    createdAt: assignment.createdAt,
    updatedAt: assignment.updatedAt,
    ...extra,
  };
}

module.exports = {
  normalizeTargets,
  loadActiveStudentIds,
  userAssignmentProgress,
  buildAssignmentProgressReport,
  getEnforcedBlockedCategoryIds,
  isAssignmentOverdue,
  serializeAssignment,
  validateQuestionsInCategory,
  questionIdsForTarget,
  enrichAssignmentTargets,
  formatUserAnswerRow,
  buildAssignmentAnswerFilters,
};
