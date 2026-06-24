'use strict';

const constants = require('../constants');
const {
  getTodayAndTomorrow,
  getServerDateFromUserDate,
  getUserDateFromServerDate,
  getUserDate,
} = require('./dates');
const { isStaleEverydayGoalPassed } = require('./everyday-goal-passed');
const { MEMBERSHIP_STATUS, listMemberships } = require('./classroom-membership');

const USER_UID = 'plugin::users-permissions.user';
const ANSWER_UID = 'api::user-answer.user-answer';
const ASSIGNMENT_UID = 'api::assignment.assignment';

async function loadActiveStudentUsers(classroomId) {
  const memberships = await listMemberships(classroomId, [
    MEMBERSHIP_STATUS.ACTIVE,
  ]);
  const users = (memberships ?? [])
    .map((m) => m.user)
    .filter((u) => u?.id);
  const unique = new Map();
  for (const u of users) {
    unique.set(u.id, u);
  }
  return [...unique.values()];
}

async function loadUsersByIds(userIds) {
  if (!userIds.length) return [];
  return strapi.entityService.findMany(USER_UID, {
    filters: { id: { $in: userIds } },
    fields: [
      'id',
      'username',
      'points',
      'everyday_goal',
      'everyday_goal_passed',
      'user_timezone',
    ],
    limit: userIds.length,
  });
}

async function loadCategoryQuestionMap() {
  const questions = await strapi.entityService.findMany('api::question.question', {
    fields: ['id'],
    populate: { category: { fields: ['id'] } },
    limit: -1,
  });
  const map = {};
  for (const q of questions ?? []) {
    const cid = q.category?.id ?? q.category;
    if (!cid) continue;
    if (!map[cid]) map[cid] = [];
    map[cid].push(q.id);
  }
  return map;
}

async function batchPastCategoryCounts(userIds, categoryQuestionMap) {
  const counts = Object.fromEntries(userIds.map((id) => [id, 0]));
  if (!userIds.length) return counts;

  const answers = await strapi.entityService.findMany(ANSWER_UID, {
    fields: ['id'],
    filters: {
      users_permissions_user: { id: { $in: userIds } },
      answer_type: { $eq: 'topic' },
      status: { $ne: 'skipped' },
    },
    populate: {
      users_permissions_user: { fields: ['id'] },
      question: { fields: ['id'] },
    },
    limit: -1,
  });

  const userQuestionSets = Object.fromEntries(
    userIds.map((id) => [id, new Set()]),
  );
  for (const answer of answers ?? []) {
    const uid =
      answer.users_permissions_user?.id ?? answer.users_permissions_user;
    const qid = answer.question?.id ?? answer.question;
    if (uid && qid) {
      userQuestionSets[uid]?.add(qid);
    }
  }

  for (const userId of userIds) {
    const answered = userQuestionSets[userId] ?? new Set();
    let past = 0;
    for (const questionIds of Object.values(categoryQuestionMap)) {
      if (
        questionIds.length > 0 &&
        questionIds.every((qid) => answered.has(qid))
      ) {
        past += 1;
      }
    }
    counts[userId] = past;
  }
  return counts;
}

async function batchLastActive(userIds) {
  const map = Object.fromEntries(userIds.map((id) => [id, null]));
  if (!userIds.length) return map;

  const knex = strapi.db.connection;
  const rows = await knex('user_answers as ua')
    .join(
      'user_answers_users_permissions_user_links as link',
      'ua.id',
      'link.user_answer_id',
    )
    .whereIn('link.user_id', userIds)
    .groupBy('link.user_id')
    .select('link.user_id')
    .max('ua.created_at as last_active');

  for (const row of rows ?? []) {
    map[row.user_id] = row.last_active
      ? new Date(row.last_active).toISOString()
      : null;
  }
  return map;
}

function groupUserIdsByTimezone(users) {
  const groups = {};
  for (const user of users) {
    const tz = user.user_timezone || constants.DEFAULT_TIMEZONE;
    if (!groups[tz]) groups[tz] = [];
    groups[tz].push(user.id);
  }
  return groups;
}

async function batchTodayAnswerStats(users) {
  const stats = {};
  for (const user of users) {
    stats[user.id] = {
      questions_answered_today: 0,
      correct_today: 0,
      wrong_today: 0,
      skipped_today: 0,
    };
  }
  if (!users.length) return stats;

  const knex = strapi.db.connection;
  const byTimezone = groupUserIdsByTimezone(users);

  for (const [timezone, userIds] of Object.entries(byTimezone)) {
    const { today, tomorrow } = getTodayAndTomorrow(timezone);
    const start = getServerDateFromUserDate(today, timezone);
    const end = getServerDateFromUserDate(tomorrow, timezone);

    const rows = await knex('user_answers as ua')
      .join(
        'user_answers_users_permissions_user_links as link',
        'ua.id',
        'link.user_answer_id',
      )
      .whereIn('link.user_id', userIds)
      .where('ua.created_at', '>=', start)
      .where('ua.created_at', '<', end)
      .groupBy('link.user_id', 'ua.status')
      .select('link.user_id', 'ua.status')
      .count('* as count');

    for (const row of rows ?? []) {
      const entry = stats[row.user_id];
      if (!entry) continue;
      const count = Number(row.count) || 0;
      entry.questions_answered_today += count;
      if (row.status === 'correct') entry.correct_today += count;
      else if (row.status === 'wrong') entry.wrong_today += count;
      else if (row.status === 'skipped') entry.skipped_today += count;
    }
  }
  return stats;
}

function isDailyGoalMet(user, correctToday) {
  const goal = user.everyday_goal;
  if (!goal || goal <= 0) return false;
  if (isStaleEverydayGoalPassed(user)) return false;
  if (user.everyday_goal_passed) {
    const tz = user.user_timezone || constants.DEFAULT_TIMEZONE;
    const todayStr = getUserDate(tz);
    const passedStr = new Intl.DateTimeFormat('sv-SE', {
      dateStyle: 'short',
      timeZone: tz,
    }).format(new Date(user.everyday_goal_passed));
    if (passedStr === todayStr) return true;
  }
  return correctToday >= goal;
}

function sortRoster(items, sort) {
  const key = sort || 'last_active';
  const sorted = [...items];
  sorted.sort((a, b) => {
    if (key === 'points') {
      return (b.points ?? 0) - (a.points ?? 0);
    }
    if (key === 'username') {
      return String(a.username ?? '').localeCompare(String(b.username ?? ''));
    }
    const aTime = a.last_active ? new Date(a.last_active).getTime() : 0;
    const bTime = b.last_active ? new Date(b.last_active).getTime() : 0;
    return bTime - aTime;
  });
  return sorted;
}

function filterInactive(items, inactiveDays) {
  if (!inactiveDays || inactiveDays <= 0) return items;
  const cutoff = Date.now() - inactiveDays * 24 * 60 * 60 * 1000;
  return items.filter((item) => {
    if (!item.last_active) return true;
    return new Date(item.last_active).getTime() < cutoff;
  });
}

function assignmentAnswerSinceMs(assignment) {
  const raw = assignment?.createdAt;
  if (!raw) return 0;
  const t = new Date(raw).getTime();
  return Number.isNaN(t) ? 0 : t;
}

function withExercisePercents(stat) {
  const total = stat.total || 0;
  if (total === 0) {
    return {
      ...stat,
      correct_percent: 0,
      wrong_percent: 0,
      unanswered_percent: 0,
    };
  }
  return {
    ...stat,
    correct_percent: Math.round((stat.correct / total) * 100),
    wrong_percent: Math.round((stat.wrong / total) * 100),
    unanswered_percent: Math.round((stat.unanswered / total) * 100),
  };
}

async function batchStudentExerciseStats(classroomId, userIds, { assignmentId } = {}) {
  const stats = Object.fromEntries(
    userIds.map((id) => [id, { correct: 0, wrong: 0, unanswered: 0, total: 0 }]),
  );
  if (!userIds.length) return stats;

  const {
    normalizeTargets,
    questionIdsForTarget,
  } = require('./assignment-progress');

  const filters = { classroom: classroomId, archived: false, published: true };
  if (assignmentId) filters.id = Number(assignmentId);

  const assignments = await strapi.entityService.findMany(ASSIGNMENT_UID, {
    filters,
    fields: ['id', 'targets', 'createdAt'],
    limit: -1,
  });

  const slots = [];
  for (const assignment of assignments ?? []) {
    for (const target of normalizeTargets(assignment.targets)) {
      const qids = await questionIdsForTarget(target);
      for (const qid of qids) {
        slots.push({ assignment, qid });
      }
    }
  }
  if (!slots.length) return stats;

  const allQids = [...new Set(slots.map((s) => s.qid))];
  const answers = await strapi.entityService.findMany(ANSWER_UID, {
    fields: ['id', 'status', 'createdAt'],
    filters: {
      users_permissions_user: { id: { $in: userIds } },
      question: { id: { $in: allQids } },
      answer_type: { $eq: 'topic' },
    },
    populate: {
      users_permissions_user: { fields: ['id'] },
      question: { fields: ['id'] },
    },
    sort: { createdAt: 'desc' },
    limit: -1,
  });

  const byUserQuestion = new Map();
  for (const answer of answers ?? []) {
    const uid = Number(answer.users_permissions_user?.id ?? answer.users_permissions_user);
    const qid = Number(answer.question?.id ?? answer.question);
    if (!uid || !qid) continue;
    const key = `${uid}:${qid}`;
    if (!byUserQuestion.has(key)) byUserQuestion.set(key, []);
    byUserQuestion.get(key).push(answer);
  }

  const resolveStatus = (uid, assignment, qid) => {
    const rows = byUserQuestion.get(`${uid}:${qid}`);
    if (!rows?.length) return 'unanswered';
    const minTime = assignmentAnswerSinceMs(assignment);
    const row = rows.find((a) => {
      if (!minTime) return true;
      return new Date(a.createdAt).getTime() >= minTime;
    });
    if (!row?.status || row.status === 'skipped') return 'unanswered';
    if (row.status === 'correct') return 'correct';
    if (row.status === 'wrong') return 'wrong';
    return 'unanswered';
  };

  for (const userId of userIds) {
    const uid = Number(userId);
    for (const { assignment, qid } of slots) {
      stats[userId].total += 1;
      const status = resolveStatus(uid, assignment, qid);
      if (status === 'correct') stats[userId].correct += 1;
      else if (status === 'wrong') stats[userId].wrong += 1;
      else stats[userId].unanswered += 1;
    }
  }

  return stats;
}

async function buildRosterItems(users) {
  if (!users.length) return [];

  const userIds = users.map((u) => u.id);
  const categoryQuestionMap = await loadCategoryQuestionMap();
  const [pastCounts, lastActiveMap, todayStats] = await Promise.all([
    batchPastCategoryCounts(userIds, categoryQuestionMap),
    batchLastActive(userIds),
    batchTodayAnswerStats(users),
  ]);

  return users.map((user) => {
    const today = todayStats[user.id] ?? {
      questions_answered_today: 0,
      correct_today: 0,
    };
    const dailyGoal = user.everyday_goal ?? 0;
    return {
      id: user.id,
      username: user.username,
      points: user.points ?? 0,
      last_active: lastActiveMap[user.id] ?? null,
      topics_completed: pastCounts[user.id] ?? 0,
      questions_answered_today: today.questions_answered_today,
      daily_goal: dailyGoal,
      daily_goal_met: isDailyGoalMet(user, today.correct_today),
    };
  });
}

async function buildClassRoster(
  classroomId,
  { sort, inactiveDays, search, assignmentId, completion } = {},
) {
  const memberUsers = await loadActiveStudentUsers(classroomId);
  const userIds = memberUsers.map((u) => u.id);
  const fullUsers = await loadUsersByIds(userIds);
  let items = await buildRosterItems(fullUsers);

  if (search) {
    const q = search.toLowerCase();
    items = items.filter((item) =>
      String(item.username ?? '').toLowerCase().includes(q),
    );
  }

  if (assignmentId) {
    const assignment = await strapi.entityService.findOne(
      'api::assignment.assignment',
      assignmentId,
      {
        fields: ['id', 'targets', 'archived', 'createdAt'],
        populate: { classroom: { fields: ['id'] } },
      },
    );
    const classroomRef = assignment?.classroom?.id ?? assignment?.classroom;
    const assignmentValid =
      assignment &&
      !assignment.archived &&
      Number(classroomRef) === Number(classroomId);
    if (assignmentValid) {
      const { userAssignmentProgress } = require('./assignment-progress');
      const withProgress = [];
      for (const item of items) {
        const progress = await userAssignmentProgress(item.id, assignment);
        withProgress.push({
          ...item,
          assignment_progress: progress,
          assignment_completed: progress.completed === true,
        });
      }
      items = withProgress;
      const mode = completion === 'complete' || completion === 'incomplete'
        ? completion
        : 'all';
      if (mode === 'complete') {
        items = items.filter((item) => item.assignment_completed);
      } else if (mode === 'incomplete') {
        items = items.filter((item) => !item.assignment_completed);
      }
    }
  }

  const statsUserIds = items.map((item) => item.id);
  const exerciseStatsMap = await batchStudentExerciseStats(
    classroomId,
    statsUserIds,
    { assignmentId },
  );
  items = items.map((item) => ({
    ...item,
    exercise_stats: withExercisePercents(
      exerciseStatsMap[item.id] ?? {
        correct: 0,
        wrong: 0,
        unanswered: 0,
        total: 0,
      },
    ),
  }));

  const filtered = filterInactive(items, inactiveDays);
  return sortRoster(filtered, sort);
}

async function assertActiveStudentInClass(classroomId, studentId) {
  const memberships = await listMemberships(classroomId, [
    MEMBERSHIP_STATUS.ACTIVE,
  ]);
  return memberships.some((m) => {
    const uid = m.user?.id ?? m.user;
    return Number(uid) === Number(studentId);
  });
}

async function buildWeeklyActivity(userId, timezone) {
  const tz = timezone || constants.DEFAULT_TIMEZONE;
  const moment = require('moment-timezone');
  const endDate = moment().tz(tz);
  const startDate = endDate.clone().subtract(6, 'days');
  const startDay = getServerDateFromUserDate(
    startDate.format('YYYY-MM-DD'),
    tz,
  );
  const endExclusive = getServerDateFromUserDate(
    endDate.clone().add(1, 'day').format('YYYY-MM-DD'),
    tz,
  );

  const knex = strapi.db.connection;
  const { rows } = await knex.raw(
    `SELECT user_answers.created_at AS date, status, COUNT(status) AS count
     FROM user_answers
     INNER JOIN user_answers_users_permissions_user_links
       ON user_answers.id = user_answers_users_permissions_user_links.user_answer_id
     WHERE user_answers_users_permissions_user_links.user_id = ?
     GROUP BY user_answers.created_at, status`,
    [userId],
  );

  const weeklyRows = (rows ?? [])
    .map((row) => ({
      ...row,
      date: getUserDateFromServerDate(row.date, tz),
    }))
    .filter((row) => {
      const t = new Date(row.date).getTime();
      return (
        t >= new Date(startDay).getTime() &&
        t < new Date(endExclusive).getTime()
      );
    });

  const groups = {};
  for (const row of weeklyRows) {
    const day = row.date.split('T')[0];
    if (!groups[day]) groups[day] = [];
    groups[day].push(row);
  }

  const activity = {};
  for (const [day, answers] of Object.entries(groups)) {
    const countByStatus = (status) =>
      answers
        .filter((a) => a.status === status)
        .reduce((acc, curr) => acc + Number(curr.count), 0);
    activity[day] = {
      correct: countByStatus('correct'),
      wrong: countByStatus('wrong'),
      skipped: countByStatus('skipped'),
    };
  }

  const days = [];
  const cursor = startDate.clone();
  while (cursor.isSameOrBefore(endDate, 'day')) {
    const key = cursor.format('YYYY-MM-DD');
    if (!activity[key]) {
      activity[key] = { correct: 0, wrong: 0, skipped: 0 };
    }
    days.push(key);
    cursor.add(1, 'day');
  }

  return { days, activity };
}

async function buildStudentSnapshot(studentId) {
  const users = await loadUsersByIds([studentId]);
  const user = users[0];
  if (!user) return null;

  const [items, weekly] = await Promise.all([
    buildRosterItems([user]),
    buildWeeklyActivity(
      studentId,
      user.user_timezone || constants.DEFAULT_TIMEZONE,
    ),
  ]);

  const summary = items[0];
  const todayRows = await batchTodayAnswerStats([user]);
  const today = todayRows[user.id] ?? {
    questions_answered_today: 0,
    correct_today: 0,
    wrong_today: 0,
    skipped_today: 0,
  };

  return {
    ...summary,
    daily_statics: {
      correct: today.correct_today,
      wrong: today.wrong_today,
      skipped: today.skipped_today,
    },
    weekly_activity: weekly.activity,
    weekly_days: weekly.days,
  };
}

async function buildStudentClassTaskSnapshot(classroomId, studentId) {
  const users = await loadUsersByIds([studentId]);
  const user = users[0];
  if (!user) return null;

  const {
    userAssignmentProgress,
    enrichAssignmentTargets,
  } = require('./assignment-progress');

  const assignments = await strapi.entityService.findMany(
    'api::assignment.assignment',
    {
      filters: { classroom: classroomId, archived: false, published: true },
      fields: ['id', 'title', 'targets'],
      sort: { createdAt: 'desc' },
      limit: 100,
    },
  );

  let exercisesTotal = 0;
  let exercisesCorrect = 0;
  let exercisesWrong = 0;
  let exercisesSkipped = 0;
  let exercisesUnanswered = 0;
  let assignmentsCompleted = 0;

  const assignmentIds = (assignments ?? []).map((a) => a.id);
  const { loadPeekCountsByAssignment, countSolutionPeeksForStudent } = require(
    './assignment-solution-peek',
  );
  const peekCountsByAssignment = await loadPeekCountsByAssignment(
    studentId,
    assignmentIds,
  );
  const solutionPeeksTotal = await countSolutionPeeksForStudent(
    studentId,
    assignmentIds,
  );

  const assignmentSummaries = [];
  for (const assignment of assignments ?? []) {
    const progress = await userAssignmentProgress(studentId, assignment);
    if (progress.completed) assignmentsCompleted += 1;

    const targetDetails = await enrichAssignmentTargets(
      studentId,
      assignment.targets,
      { assignment },
    );

    let aCorrect = 0;
    let aWrong = 0;
    let aSkipped = 0;
    let aUnanswered = 0;
    for (const target of targetDetails) {
      for (const exercise of target.exercises ?? []) {
        exercisesTotal += 1;
        const status = exercise.status ?? 'unanswered';
        if (status === 'correct') {
          exercisesCorrect += 1;
          aCorrect += 1;
        } else if (status === 'wrong') {
          exercisesWrong += 1;
          aWrong += 1;
        } else if (status === 'skipped') {
          exercisesSkipped += 1;
          aSkipped += 1;
        } else {
          exercisesUnanswered += 1;
          aUnanswered += 1;
        }
      }
    }

    assignmentSummaries.push({
      id: assignment.id,
      title: assignment.title,
      completed: progress.completed === true,
      questions_completed: progress.questions_completed,
      questions_total: progress.questions_total,
      exercises_correct: aCorrect,
      exercises_wrong: aWrong,
      exercises_skipped: aSkipped,
      exercises_unanswered: aUnanswered,
      solution_peeks_count: peekCountsByAssignment[assignment.id] ?? 0,
    });
  }

  return {
    student_id: studentId,
    username: user.username,
    class_task_stats: {
      assignments_total: (assignments ?? []).length,
      assignments_completed: assignmentsCompleted,
      exercises_total: exercisesTotal,
      exercises_correct: exercisesCorrect,
      exercises_wrong: exercisesWrong,
      exercises_skipped: exercisesSkipped,
      exercises_unanswered: exercisesUnanswered,
      solution_peeks_total: solutionPeeksTotal,
    },
    assignments: assignmentSummaries,
  };
}

module.exports = {
  buildClassRoster,
  buildStudentSnapshot,
  buildStudentClassTaskSnapshot,
  assertActiveStudentInClass,
  loadActiveStudentUsers,
  loadCategoryQuestionMap,
};
