'use strict';

const i18n = require('../i18n-helper');
const { buildClassRoster } = require('./class-roster-stats');
const { buildClassAnalytics } = require('./class-analytics');
const {
  buildAssignmentProgressReport,
  loadActiveStudentIds,
  serializeAssignment,
} = require('./assignment-progress');

const ASSIGNMENT_UID = 'api::assignment.assignment';

async function loadClassroomForReport(classroomId) {
  return strapi.entityService.findOne('api::classroom.classroom', classroomId, {
    populate: {
      teacher: { fields: ['id', 'email', 'username'] },
      institution: { fields: ['id', 'name'] },
    },
  });
}

function parseExtraEmails(raw) {
  if (!Array.isArray(raw)) return [];
  return raw
    .map((e) => (typeof e === 'string' ? e.trim() : ''))
    .filter((e) => e.includes('@'));
}

async function buildClassReportPayload(classroomId) {
  const classroom = await loadClassroomForReport(classroomId);
  const [roster, analytics, assignments] = await Promise.all([
    buildClassRoster(classroomId, { sort: 'username' }),
    buildClassAnalytics(classroomId, { range: 'week' }),
    strapi.entityService.findMany(ASSIGNMENT_UID, {
      filters: {
        classroom: { id: classroomId },
        archived: false,
      },
      sort: { due_at: 'asc' },
      limit: 50,
    }),
  ]);

  const studentIds = roster.map((r) => r.id);
  const assignmentReports = [];
  for (const a of assignments ?? []) {
    const progress = await buildAssignmentProgressReport(a, studentIds);
    assignmentReports.push({
      assignment: serializeAssignment(a),
      progress,
    });
  }

  return {
    generated_at: new Date().toISOString(),
    classroom: {
      id: classroom.id,
      name: classroom.name,
      grade: classroom.grade ?? null,
      institution: classroom.institution?.name ?? null,
    },
    roster,
    analytics,
    assignments: assignmentReports,
  };
}

function rosterToCsv(roster) {
  const header = 'username,points,topics_completed,questions_today,daily_goal_met,last_active';
  const lines = roster.map((r) => {
    const fields = [
      `"${String(r.username ?? '').replace(/"/g, '""')}"`,
      r.points ?? 0,
      r.topics_completed ?? 0,
      r.questions_answered_today ?? 0,
      r.daily_goal_met ? 'yes' : 'no',
      r.last_active ?? '',
    ];
    return fields.join(',');
  });
  return [header, ...lines].join('\n');
}

function reportToHtml(payload) {
  const title = payload.classroom?.name ?? 'Class report';
  const rows = (payload.roster ?? [])
    .map(
      (r) =>
        `<tr><td>${r.username}</td><td>${r.points}</td><td>${r.topics_completed}</td><td>${r.questions_answered_today}</td><td>${r.daily_goal_met ? '✓' : '—'}</td></tr>`,
    )
    .join('');

  const weak = (payload.analytics?.assignments_progress ?? [])
    .slice(0, 5)
    .map(
      (t) =>
        `<li>${t.assignment_title}: ${t.exercise_completion_percent ?? t.completion_rate_percent}% (${t.students_completed}/${t.students_total} students finished, ${t.exercises_completed}/${t.exercises_total} exercises done)</li>`,
    )
    .join('');

  return `
    <h2>${title}</h2>
    <p>${i18n.__('errors.class-report.generated')}: ${payload.generated_at}</p>
    <h3>${i18n.__('errors.class-report.roster')}</h3>
    <table border="1" cellpadding="6" cellspacing="0">
      <tr><th>Student</th><th>Points</th><th>Topics</th><th>Today</th><th>Goal</th></tr>
      ${rows}
    </table>
    <h3>${i18n.__('errors.class-report.weak-topics')}</h3>
    <ul>${weak || '<li>—</li>'}</ul>
  `;
}

async function sendClassReportEmail(classroomId, { extraRecipients } = {}) {
  const classroom = await loadClassroomForReport(classroomId);
  const teacherEmail = classroom.teacher?.email?.trim();
  const recipients = new Set();

  if (teacherEmail) recipients.add(teacherEmail);
  for (const e of parseExtraEmails(classroom.report_extra_emails)) {
    recipients.add(e);
  }
  for (const e of extraRecipients ?? []) {
    if (typeof e === 'string' && e.includes('@')) recipients.add(e.trim());
  }

  if (!recipients.size) {
    return { ok: false, reason: 'no_recipients' };
  }

  const payload = await buildClassReportPayload(classroomId);
  const html = reportToHtml(payload);
  const subject = `${i18n.__('errors.class-report.email-subject')}: ${classroom.name}`;

  await strapi.plugins.email.service('email').send({
    to: [...recipients].join(','),
    subject,
    html,
  });

  return { ok: true, recipients: [...recipients] };
}

module.exports = {
  buildClassReportPayload,
  rosterToCsv,
  reportToHtml,
  sendClassReportEmail,
  parseExtraEmails,
};
