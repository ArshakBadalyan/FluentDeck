"use strict";

const { ACCOUNT_TYPES, normalizeAccountType } = require("./account-type");

function isLeaderboardEligibleUser(user) {
  if (!user) return false;
  if (user.is_admin === true) return false;
  return normalizeAccountType(user.account_type) !== ACCOUNT_TYPES.TEACHER;
}

function filterLeaderboardUsers(users) {
  if (!Array.isArray(users)) return [];
  return users.filter(isLeaderboardEligibleUser);
}

module.exports = {
  isLeaderboardEligibleUser,
  filterLeaderboardUsers,
};
