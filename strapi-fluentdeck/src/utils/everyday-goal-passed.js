const { getUserDate } = require("./dates");
const constants = require("../constants");

/**
 * True when the user has a daily goal and everyday_goal_passed is set, but that
 * timestamp's calendar day in the user's timezone is not "today" there.
 * Used to clear stale flags (e.g. clients that never reset on a new day).
 */
function isStaleEverydayGoalPassed(user) {
  if (!user?.everyday_goal || !user?.everyday_goal_passed) {
    return false;
  }
  const timezone = user.user_timezone || constants.DEFAULT_TIMEZONE;
  const todayStr = getUserDate(timezone);
  const passedStr = new Intl.DateTimeFormat("sv-SE", {
    dateStyle: "short",
    timeZone: timezone,
  }).format(new Date(user.everyday_goal_passed));
  return passedStr !== todayStr;
}

module.exports = { isStaleEverydayGoalPassed };
