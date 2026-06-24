"use strict";

const { ACCOUNT_TYPES, normalizeAccountType } = require("./account-type");

const USER_UID = "plugin::users-permissions.user";

function isTeacherAccount(user) {
  return normalizeAccountType(user?.account_type) === ACCOUNT_TYPES.TEACHER;
}

function isTeacherApproved(user) {
  return isTeacherAccount(user) && user?.teacher_approved === true;
}

function currentCalendarYear() {
  return new Date().getFullYear();
}

function normalizeInviteCode(code) {
  if (typeof code !== "string") return "";
  return code.trim().toUpperCase();
}

function institutionInviteMatches(institution, code) {
  const normalized = normalizeInviteCode(code);
  if (!normalized || !institution) return false;
  const year = Number(institution.teacher_invite_code_year);
  const stored = normalizeInviteCode(institution.teacher_invite_code);
  if (!stored || !Number.isInteger(year)) return false;
  return year === currentCalendarYear() && stored === normalized;
}

async function loadUserForApproval(userId) {
  return strapi.entityService.findOne(USER_UID, userId, {
    fields: [
      "id",
      "username",
      "email",
      "account_type",
      "teacher_approved",
      "blocked",
      "is_institution_admin",
      "is_admin",
    ],
    populate: { institution: { fields: ["id", "name", "place_id"] } },
  });
}

async function loadRequesterForApproval(userId) {
  return strapi.entityService.findOne(USER_UID, userId, {
    fields: [
      "id",
      "account_type",
      "teacher_approved",
      "is_institution_admin",
      "is_admin",
    ],
    populate: { institution: { fields: ["id"] } },
  });
}

function institutionIdOf(user) {
  const inst = user?.institution;
  if (!inst) return null;
  return typeof inst === "object" ? inst.id : inst;
}

function canManageTeacherApprovals(requester) {
  if (!requester?.id) return false;
  if (requester.is_admin === true) return true;
  return requester.is_institution_admin === true;
}

function canApproveTargetTeacher(requester, target) {
  if (!canManageTeacherApprovals(requester)) return false;
  if (!isTeacherAccount(target)) return false;
  if (target.teacher_approved === true) return false;
  if (requester.is_admin === true) return true;
  const reqInst = institutionIdOf(requester);
  const tgtInst = institutionIdOf(target);
  return (
    requester.is_institution_admin === true &&
    reqInst != null &&
    tgtInst != null &&
    Number(reqInst) === Number(tgtInst)
  );
}

module.exports = {
  USER_UID,
  isTeacherAccount,
  isTeacherApproved,
  currentCalendarYear,
  normalizeInviteCode,
  institutionInviteMatches,
  loadUserForApproval,
  loadRequesterForApproval,
  institutionIdOf,
  canManageTeacherApprovals,
  canApproveTargetTeacher,
};
