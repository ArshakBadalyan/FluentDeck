'use strict';

const moment = require('moment-timezone');
const { loadActiveStudentUsers } = require('./class-roster-stats');
const {
  normalizeTargets,
  questionIdsForTarget,
  buildAssignmentProgressReport,
} = require('./assignment-progress');

const ANSWER_UID = 'api::user-answer.user-answer';
const ASSIGNMENT_UID = 'api::assignment.assignment';

function parseRange(range) {
  const r = String(range || 'week').toLowerCase();
  return r === 'month' ? 30 : 7;
}

function utcYmd(d) {
  return d.toISOString().slice(0, 10);
}

async function loadClassroomAssignmentScope(classroomId) {
  const assignments = await strapi.entityService.findMany(ASSIGNMENT_UID, {
    filters: { classroom: classroomId, archived: false },
    fields: ['id', 'title', 'targets'],
    sort: [{ due_at: 'asc' }, { createdAt: 'desc' }],
    limit: -1,
  });

  const questionIds = new Set();
  for (const assignment of assignments ?? []) {
    for (const target of normalizeTargets(assignment.targets)) {
      const qids = await questionIdsForTarget(target);
      for (const id of qids) questionIds.add(id);
    }
  }

  return { assignments: assignments ?? [], questionIds: [...questionIds] };
}

async function batchDailyActivity(userIds, questionIds, days) {
  const byDate = {};
  const start = moment.utc().startOf('day').subtract(days - 1, 'days');

  for (let i = 0; i < days; i += 1) {
    byDate[utcYmd(start.clone().add(i, 'days').toDate())] = {
      date: utcYmd(start.clone().add(i, 'days').toDate()),
      total_answers: 0,
      correct: 0,
      wrong: 0,
    };
  }

  if (!userIds.length || !questionIds.length) {
    return Object.values(byDate);
  }

  const from = start.toDate();
  const answers = await strapi.entityService.findMany(ANSWER_UID, {
    fields: ['id', 'status', 'createdAt'],
    filters: {
      users_permissions_user: { id: { $in: userIds } },
      question: { id: { $in: questionIds } },
      answer_type: { $eq: 'topic' },
      createdAt: { $gte: from },
    },
    populate: { users_permissions_user: { fields: ['id'] } },
    limit: -1,
  });

  for (const a of answers ?? []) {
    const day = utcYmd(new Date(a.createdAt));
    if (!byDate[day]) continue;
    byDate[day].total_answers += 1;
    if (a.status === 'correct') byDate[day].correct += 1;
    else if (a.status === 'wrong') byDate[day].wrong += 1;
  }

  return Object.values(byDate);
}

async function assignmentProgressInsights(assignments, studentIds) {
  if (!assignments.length || !studentIds.length) return [];

  const insights = [];
  for (const assignment of assignments) {
    const progress = await buildAssignmentProgressReport(assignment, studentIds);
    const completedStudents = progress.filter((p) => p.completed).length;
    const exercisesPerStudent = progress[0]?.questions_total ?? 0;
    const exercisesCompletedSum = progress.reduce(
      (sum, p) => sum + (p.questions_completed || 0),
      0,
    );
    const exercisesPossible = exercisesPerStudent * studentIds.length;

    const exerciseCompletionPercent =
      exercisesPossible > 0
        ? Math.round((exercisesCompletedSum / exercisesPossible) * 100)
        : 0;
    const studentCompletionPercent =
      studentIds.length > 0
        ? Math.round((completedStudents / studentIds.length) * 100)
        : 0;

    insights.push({
      assignment_id: assignment.id,
      assignment_title: assignment.title,
      completion_rate_percent: exerciseCompletionPercent,
      student_completion_percent: studentCompletionPercent,
      students_completed: completedStudents,
      students_total: studentIds.length,
      exercises_completed: exercisesCompletedSum,
      exercises_total: exercisesPossible,
      exercise_completion_percent: exerciseCompletionPercent,
    });
  }

  insights.sort(
    (a, b) => a.exercise_completion_percent - b.exercise_completion_percent,
  );
  return insights;
}

async function buildClassAnalytics(classroomId, { range } = {}) {
  const days = parseRange(range);
  const students = await loadActiveStudentUsers(classroomId);
  const userIds = students.map((u) => u.id);

  const { assignments, questionIds } = await loadClassroomAssignmentScope(
    classroomId,
  );

  const daily_activity = await batchDailyActivity(userIds, questionIds, days);
  const assignments_progress = await assignmentProgressInsights(
    assignments,
    userIds,
  );

  const totalAnswers = daily_activity.reduce(
    (sum, d) => sum + d.total_answers,
    0,
  );

  return {
    range: days === 30 ? 'month' : 'week',
    days,
    student_count: userIds.length,
    assignment_count: assignments.length,
    summary: {
      total_assignment_answers: totalAnswers,
      avg_answers_per_day:
        days > 0 ? Math.round((totalAnswers / days) * 10) / 10 : 0,
      active_students: userIds.length,
    },
    daily_activity,
    assignments_progress,
  };
}

module.exports = {
  buildClassAnalytics,
  parseRange,
  loadClassroomAssignmentScope,
};
