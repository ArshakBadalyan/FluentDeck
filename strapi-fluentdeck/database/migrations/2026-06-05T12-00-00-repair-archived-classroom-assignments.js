"use strict";

/**
 * Repair orphaned assignments/memberships for classes archived before
 * finalizeClassroomArchive existed.
 */
module.exports = {
  async up(knex) {
    const hasClassrooms = await knex.schema.hasTable("classrooms");
    if (!hasClassrooms) return;

    const archivedClassroomIds = await knex("classrooms")
      .where({ archived: true })
      .pluck("id");

    if (!archivedClassroomIds.length) return;

    const hasAssignments = await knex.schema.hasTable("assignments");
    const hasAssignmentLinks = await knex.schema.hasTable(
      "assignments_classroom_links",
    );
    if (hasAssignments && hasAssignmentLinks) {
      const assignmentIds = await knex("assignments_classroom_links")
        .whereIn("classroom_id", archivedClassroomIds)
        .pluck("assignment_id");

      if (assignmentIds.length) {
        await knex("assignments")
          .whereIn("id", assignmentIds)
          .where({ archived: false })
          .update({ archived: true });
      }
    }

    const hasMembers = await knex.schema.hasTable("classroom_members");
    if (!hasMembers) return;

    const memberLinkTable = "classroom_members_classroom_links";
    const hasMemberLinks = await knex.schema.hasTable(memberLinkTable);

    if (hasMemberLinks) {
      const memberIds = await knex(memberLinkTable)
        .whereIn("classroom_id", archivedClassroomIds)
        .pluck("classroom_member_id");

      if (memberIds.length) {
        await knex("classroom_members")
          .whereIn("id", memberIds)
          .whereIn("status", ["active", "pending_join", "leave_pending"])
          .update({ status: "left" });
      }
      return;
    }

    // Fallback if relations are stored as columns on classroom_members.
    const hasClassroomCol = await knex.schema.hasColumn(
      "classroom_members",
      "classroom_id",
    );
    if (hasClassroomCol) {
      await knex("classroom_members")
        .whereIn("classroom_id", archivedClassroomIds)
        .whereIn("status", ["active", "pending_join", "leave_pending"])
        .update({ status: "left" });
    }
  },
};
