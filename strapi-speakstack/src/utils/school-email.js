const { normalizeAccountType, ACCOUNT_TYPES } = require("./account-type");

/** Common consumer mail providers — not valid school addresses. */
const PUBLIC_EMAIL_DOMAINS = new Set([
  "gmail.com",
  "googlemail.com",
  "yahoo.com",
  "yahoo.de",
  "hotmail.com",
  "hotmail.de",
  "outlook.com",
  "outlook.de",
  "live.com",
  "live.de",
  "icloud.com",
  "me.com",
  "mac.com",
  "aol.com",
  "gmx.de",
  "gmx.net",
  "web.de",
  "t-online.de",
  "mail.com",
  "proton.me",
  "protonmail.com",
  "yandex.com",
  "yandex.ru",
  "msn.com",
]);

function extractEmailDomain(email) {
  if (typeof email !== "string") return null;
  const trimmed = email.trim().toLowerCase();
  const at = trimmed.lastIndexOf("@");
  if (at < 1 || at === trimmed.length - 1) return null;
  const domain = trimmed.slice(at + 1);
  if (!domain || domain.includes("@") || !domain.includes(".")) return null;
  return domain;
}

function isPublicEmailDomain(domain) {
  return PUBLIC_EMAIL_DOMAINS.has(String(domain || "").toLowerCase());
}

function normalizeDomainList(domains) {
  if (!Array.isArray(domains)) return [];
  return domains
    .map((d) => (typeof d === "string" ? d.trim().toLowerCase() : ""))
    .filter(Boolean);
}

function institutionMatchesDomain(institution, domain) {
  const allowed = normalizeDomainList(institution?.allowed_email_domains);
  return allowed.includes(String(domain).toLowerCase());
}

async function loadInstitutions(strapi) {
  return strapi.entityService.findMany("api::institution.institution", {
    fields: ["id", "name", "place_id", "allowed_email_domains"],
    limit: -1,
  });
}

async function findInstitutionsByEmailDomain(strapi, email) {
  const domain = extractEmailDomain(email);
  if (!domain) return { domain: null, institutions: [] };
  const all = await loadInstitutions(strapi);
  const institutions = all.filter((inst) =>
    institutionMatchesDomain(inst, domain)
  );
  return { domain, institutions };
}

/**
 * @returns {{ institutionId: number } | { errorKey: string, errorArgs?: object }}
 */
async function resolveInstitutionForSchoolEmail(
  strapi,
  email,
  institutionIdHint
) {
  const { domain, institutions } = await findInstitutionsByEmailDomain(
    strapi,
    email
  );

  if (!domain) {
    return { errorKey: "errors.school-email-invalid" };
  }

  if (isPublicEmailDomain(domain)) {
    return { errorKey: "errors.school-email-public-domain" };
  }

  if (institutions.length === 0) {
    return { errorKey: "errors.school-email-domain-unknown" };
  }

  if (institutions.length === 1) {
    return { institutionId: institutions[0].id };
  }

  const hint = Number(institutionIdHint);
  if (Number.isInteger(hint) && hint > 0) {
    const picked = institutions.find((i) => i.id === hint);
    if (picked) return { institutionId: picked.id };
  }

  return { errorKey: "errors.school-email-pick-institution" };
}

function assertSchoolEmailFormat(email) {
  const domain = extractEmailDomain(email);
  if (!domain) {
    const err = new Error("school-email-invalid");
    err.code = "errors.school-email-invalid";
    throw err;
  }
  if (isPublicEmailDomain(domain)) {
    const err = new Error("school-email-public-domain");
    err.code = "errors.school-email-public-domain";
    throw err;
  }
  return domain;
}

function registrationRequiresSchoolEmail(params) {
  const explicit = normalizeAccountType(params?.account_type);
  return explicit === ACCOUNT_TYPES.TEACHER;
}

module.exports = {
  PUBLIC_EMAIL_DOMAINS,
  extractEmailDomain,
  isPublicEmailDomain,
  findInstitutionsByEmailDomain,
  resolveInstitutionForSchoolEmail,
  assertSchoolEmailFormat,
  registrationRequiresSchoolEmail,
  institutionMatchesDomain,
};
