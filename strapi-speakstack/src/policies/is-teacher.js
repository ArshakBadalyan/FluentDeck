"use strict";

const { isTeacherUser } = require("../utils/classroom-auth");

module.exports = async (policyContext, _config, { strapi }) => {
  const user = policyContext.state?.user;
  if (!user?.id || !isTeacherUser(user)) {
    return false;
  }
  return true;
};
