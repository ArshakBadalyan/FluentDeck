"use strict";

const crypto = require("crypto");

const INVITE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

function generateTeacherInviteCode(length = 8) {
  let out = "";
  for (let i = 0; i < length; i += 1) {
    const idx = crypto.randomInt(0, INVITE_ALPHABET.length);
    out += INVITE_ALPHABET[idx];
  }
  return out;
}

module.exports = {
  generateTeacherInviteCode,
};
