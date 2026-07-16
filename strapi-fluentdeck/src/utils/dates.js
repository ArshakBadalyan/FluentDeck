const moment = require("moment-timezone");
const i18n = require("../i18n-helper");

const dateDiff = (startingDate, endingDate = new Date()) => {
  var date1 = moment(startingDate, 'DD-MM-YYYY');
  var date2 = moment(endingDate, 'DD-MM-YYYY');
  var years = date2.diff(date1, 'years');
  date1.add(years, 'years');
  var months = date2.diff(date1, 'months');
  date1.add(months, 'months');
  var days = date2.diff(date1, 'days');
  date1.add(days, 'days');
  var hours = date2.diff(date1, 'hours');
  let period = years ? i18n.__n('dates.%s year', years) : '';
  period += years === 0 ? '' : hours === 0 && days === 0 && months > 0 ? ' ' + i18n.__('helpers.and') : ',';
  period += months ? ' ' + i18n.__n('dates.%s month', months) : '';
  period += months === 0 ? '' : hours === 0 && days > 0 ? ' ' + i18n.__('helpers.and') : ',';
  period += days ? ' ' + i18n.__n('dates.%s day', days) : '';
  period += days === 0 ? '' : hours > 0 ? ' ' + i18n.__('helpers.and') : '';
  period += hours ? ' ' + i18n.__n('dates.%s hour', hours) : '';
  return period ? period : i18n.__("dates.recently");
};

const getUserDate = (timezone) => {
  return new Intl.DateTimeFormat("sv-SE", {
    dateStyle: "short",
    timeZone: timezone,
  }).format(new Date());
};

const createDateString = (date) => {
  const dateYear = date.getFullYear();
  const dateMonth = `${date.getMonth() + 1}`.padStart(2, "0");
  const dateDate = `${date.getDate()}`.padStart(2, "0");

  return `${dateYear}-${dateMonth}-${dateDate}`;
};

const createDatetimeString = (timezone) => {
  const userCurrentDate = new Intl.DateTimeFormat("sv-SE", {
    dateStyle: "short",
    timeZone: timezone,
  }).format(new Date());

  const userDateStr = new Intl.DateTimeFormat("sv-SE", {
    timeZone: timezone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hour12: false,
  }).format(new Date());

  return `${userCurrentDate}T${userDateStr.split(" ")[1]}.000Z`;
};

const getTodayAndTomorrow = (originalTimeZone) => {
  // Get the current date in the user's original time zone
  const currentDate = moment().tz(originalTimeZone);
  const startOfToday = currentDate.startOf("day").toDate();
  const startOfTomorrow = currentDate
    .clone()
    .add(1, "day")
    .startOf("day")
    .toDate();
  const today = moment(startOfToday).format("YYYY-MM-DD HH:mm:ss.SSSSSS");
  const tomorrow = moment(startOfTomorrow).format("YYYY-MM-DD HH:mm:ss.SSSSSS");
  return {
    today,
    tomorrow,
  };
};

const getServerDateFromUserDate = (date, originalTimeZone) => {
  const currentDate = moment(date).tz(originalTimeZone);
  const startDate = currentDate.startOf("day").toDate();
  return moment(startDate).format("YYYY-MM-DD HH:mm:ss.SSSSSS");
};

const getUserDateFromServerDate = (date, userTimezone) => {
  return moment(date).tz(userTimezone).toISOString(true);
};

module.exports = {
  dateDiff,
  getUserDate,
  createDateString,
  createDatetimeString,
  getTodayAndTomorrow,
  getServerDateFromUserDate,
  getUserDateFromServerDate,
};
