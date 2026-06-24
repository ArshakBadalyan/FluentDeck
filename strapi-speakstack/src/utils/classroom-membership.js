const MEMBER_UID = 'api::classroom-member.classroom-member';
const CLASSROOM_UID = 'api::classroom.classroom';

const MEMBERSHIP_STATUS = Object.freeze({
  PENDING_JOIN: 'pending_join',
  ACTIVE: 'active',
  REJECTED: 'rejected',
  LEAVE_PENDING: 'leave_pending',
  LEFT: 'left',
});

const OPEN_STATUSES = [
  MEMBERSHIP_STATUS.PENDING_JOIN,
  MEMBERSHIP_STATUS.ACTIVE,
  MEMBERSHIP_STATUS.LEAVE_PENDING,
];

const memberPopulate = {
  user: { fields: ['id', 'username', 'email'] },
  classroom: { fields: ['id', 'name'] },
};

function serializeMember(entry) {
  if (!entry) return null;
  const user = entry.user;
  return {
    id: entry.id,
    status: entry.status,
    user: user
      ? {
          id: user.id,
          username: user.username,
          email: user.email ?? null,
        }
      : null,
    createdAt: entry.createdAt,
    updatedAt: entry.updatedAt,
  };
}

async function findMembership(classroomId, userId) {
  return strapi.db.query(MEMBER_UID).findOne({
    where: {
      classroom: classroomId,
      user: userId,
      status: { $in: OPEN_STATUSES },
    },
    populate: memberPopulate,
  });
}

async function findMembershipById(memberId, classroomId) {
  return strapi.db.query(MEMBER_UID).findOne({
    where: {
      id: memberId,
      classroom: classroomId,
    },
    populate: memberPopulate,
  });
}

async function listMemberships(classroomId, statuses = null) {
  const where = { classroom: classroomId };
  if (statuses?.length) {
    where.status = { $in: statuses };
  }
  return strapi.db.query(MEMBER_UID).findMany({
    where,
    populate: memberPopulate,
    orderBy: { updatedAt: 'desc' },
  });
}

async function countActiveMembers(classroomId) {
  return strapi.db.query(MEMBER_UID).count({
    where: {
      classroom: classroomId,
      status: MEMBERSHIP_STATUS.ACTIVE,
    },
  });
}

async function connectStudentRelation(classroomId, userId) {
  await strapi.entityService.update(CLASSROOM_UID, classroomId, {
    data: {
      students: { connect: [{ id: userId }] },
    },
  });
}

async function disconnectStudentRelation(classroomId, userId) {
  await strapi.entityService.update(CLASSROOM_UID, classroomId, {
    data: {
      students: { disconnect: [{ id: userId }] },
    },
  });
}

async function loadClassroomMembersForSerialize(classroomId) {
  const members = await listMemberships(classroomId, [
    MEMBERSHIP_STATUS.ACTIVE,
    MEMBERSHIP_STATUS.PENDING_JOIN,
    MEMBERSHIP_STATUS.LEAVE_PENDING,
  ]);
  return {
    active: members.filter((m) => m.status === MEMBERSHIP_STATUS.ACTIVE),
    pending_join: members.filter(
      (m) => m.status === MEMBERSHIP_STATUS.PENDING_JOIN,
    ),
    leave_pending: members.filter(
      (m) => m.status === MEMBERSHIP_STATUS.LEAVE_PENDING,
    ),
  };
}

/** Active memberships in non-archived classrooms (student assignment scope). */
async function loadStudentActiveClassroomIds(userId) {
  const memberships = await strapi.db.query(MEMBER_UID).findMany({
    where: {
      user: userId,
      status: MEMBERSHIP_STATUS.ACTIVE,
    },
    populate: { classroom: { fields: ["id", "archived"] } },
  });

  return [
    ...new Set(
      (memberships ?? [])
        .filter((m) => m.classroom && m.classroom.archived !== true)
        .map((m) => m.classroom.id ?? m.classroom)
        .filter(Boolean),
    ),
  ];
}

module.exports = {
  MEMBER_UID,
  MEMBERSHIP_STATUS,
  OPEN_STATUSES,
  serializeMember,
  findMembership,
  findMembershipById,
  listMemberships,
  countActiveMembers,
  connectStudentRelation,
  disconnectStudentRelation,
  loadClassroomMembersForSerialize,
  loadStudentActiveClassroomIds,
};
