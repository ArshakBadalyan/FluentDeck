const ACCOUNT_TYPES = Object.freeze({
  STUDENT: "student",
  TEACHER: "teacher",
});

const VALID_ACCOUNT_TYPES = new Set(Object.values(ACCOUNT_TYPES));

function normalizeAccountType(value) {
  if (typeof value !== "string") return null;
  const normalized = value.trim().toLowerCase();
  return VALID_ACCOUNT_TYPES.has(normalized) ? normalized : null;
}

module.exports = {
  ACCOUNT_TYPES,
  VALID_ACCOUNT_TYPES,
  normalizeAccountType,
};

