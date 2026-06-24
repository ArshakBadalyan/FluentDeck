"use strict";

const ASSIGNMENT_UID = "api::assignment.assignment";
const {
  MEMBER_UID,
  MEMBERSHIP_STATUS,
  listMemberships,
  disconnectStudentRelation,
} = require("./classroom-membership");
const {
  purgeClassroomAssignmentProgress,
} = require("./classroom-assignment-purge");

/**
 * When a class is archived ("deleted"), stop assignments and memberships
 * from affecting students.
 */
async function finalizeClassroomArchive(classroomId) {
  const assignments = await strapi.entityService.findMany(ASSIGNMENT_UID, {
    filters: { classroom: classroomId, archived: false },
    fields: ["id"],
    limit: -1,
  });

  for (const assignment of assignments ?? []) {
    await strapi.entityService.update(ASSIGNMENT_UID, assignment.id, {
      data: { archived: true },
    });
  }

  const members = await listMemberships(classroomId, [
    MEMBERSHIP_STATUS.ACTIVE,
    MEMBERSHIP_STATUS.PENDING_JOIN,
    MEMBERSHIP_STATUS.LEAVE_PENDING,
  ]);

  for (const membership of members ?? []) {
    const userId = membership.user?.id ?? membership.user;
    if (membership.status === MEMBERSHIP_STATUS.ACTIVE && userId) {
      await disconnectStudentRelation(classroomId, userId);
    }
    await strapi.entityService.update(MEMBER_UID, membership.id, {
      data: { status: MEMBERSHIP_STATUS.LEFT },
    });
  }

  const purge = await purgeClassroomAssignmentProgress(classroomId);

  strapi.log.info(
    `[classroom-archive] classroom ${classroomId}: archived ${assignments?.length ?? 0} assignment(s), closed ${members?.length ?? 0} membership(s), removed ${purge.answersRemoved} topic answer(s) for ${purge.students} student(s)`,
  );
}

module.exports = { finalizeClassroomArchive };
