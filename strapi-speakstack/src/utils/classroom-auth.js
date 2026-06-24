const { ACCOUNT_TYPES, normalizeAccountType } = require("./account-type");
const { isTeacherApproved } = require("./teacher-approval");

const USER_UID = "plugin::users-permissions.user";

function getAuthUser(ctx) {
  const user = ctx.state?.user;
  if (!user?.id) return null;
  return user;
}

function isTeacherUser(user) {
  return normalizeAccountType(user?.account_type) === ACCOUNT_TYPES.TEACHER;
}

function isStudentUser(user) {
  return normalizeAccountType(user?.account_type) === ACCOUNT_TYPES.STUDENT;
}

function requireAuth(ctx) {
  const user = getAuthUser(ctx);
  if (!user) {
    ctx.unauthorized("Authentication required");
    return null;
  }
  return user;
}

function requireTeacher(ctx) {
  const user = requireAuth(ctx);
  if (!user) return null;
  if (!isTeacherUser(user)) {
    ctx.forbidden("Teachers only");
    return null;
  }
  return user;
}

async function requireApprovedTeacher(ctx) {
  const user = requireTeacher(ctx);
  if (!user) return null;

  const full = await strapi.entityService.findOne(USER_UID, user.id, {
    fields: ["id", "account_type", "teacher_approved", "blocked"],
  });

  if (full?.blocked) {
    ctx.forbidden("Account blocked");
    return null;
  }

  if (!isTeacherApproved(full)) {
    ctx.forbidden({
      message: "Teacher account pending approval",
      code: "TEACHER_NOT_APPROVED",
    });
    return null;
  }

  return { ...user, teacher_approved: true };
}

function requireStudent(ctx) {
  const user = requireAuth(ctx);
  if (!user) return null;
  if (!isStudentUser(user)) {
    ctx.forbidden("Students only");
    return null;
  }
  return user;
}

module.exports = {
  getAuthUser,
  isTeacherUser,
  isStudentUser,
  requireAuth,
  requireTeacher,
  requireApprovedTeacher,
  requireStudent,
};
