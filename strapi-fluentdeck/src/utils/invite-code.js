const crypto = require("crypto");

const INVITE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

function generateInviteCode(length = 6) {
  let code = "";
  for (let i = 0; i < length; i += 1) {
    const idx = crypto.randomInt(0, INVITE_ALPHABET.length);
    code += INVITE_ALPHABET[idx];
  }
  return code;
}

async function generateUniqueInviteCode(strapi, maxAttempts = 12) {
  for (let attempt = 0; attempt < maxAttempts; attempt += 1) {
    const invite_code = generateInviteCode();
    const existing = await strapi.db.query("api::classroom.classroom").findOne({
      where: { invite_code },
      select: ["id"],
    });
    if (!existing) return invite_code;
  }
  throw new Error("invite-code-generation-failed");
}

module.exports = {
  generateInviteCode,
  generateUniqueInviteCode,
};
