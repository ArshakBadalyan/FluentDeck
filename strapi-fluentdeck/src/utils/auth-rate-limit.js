'use strict';

const DEFAULT_RULES = {
  '/api/auth/local': { max: 10, windowMs: 15 * 60 * 1000 },
  '/api/auth/local/register': { max: 5, windowMs: 60 * 60 * 1000 },
  '/api/auth/forgot-password': { max: 5, windowMs: 60 * 60 * 1000 },
  '/api/auth/reset-password': { max: 10, windowMs: 60 * 60 * 1000 },
  '/api/auth/apple/mobile': { max: 20, windowMs: 15 * 60 * 1000 },
  '/api/auth/google/mobile': { max: 20, windowMs: 15 * 60 * 1000 },
};

/** @type {Map<string, { count: number, resetAt: number }>} */
const buckets = new Map();

function envPositiveInt(name, fallback) {
  const raw = process.env[name];
  if (raw == null || String(raw).trim() === '') return fallback;
  const n = parseInt(String(raw).trim(), 10);
  return Number.isFinite(n) && n > 0 ? n : fallback;
}

function isDisabled() {
  const raw = String(process.env.DISABLE_AUTH_RATE_LIMIT ?? '').trim().toLowerCase();
  return ['1', 'true', 'yes', 'on'].includes(raw);
}

function resolveClientIp(ctx) {
  const forwarded = ctx.request?.headers?.['x-forwarded-for'];
  if (typeof forwarded === 'string' && forwarded.trim()) {
    return forwarded.split(',')[0].trim();
  }
  return ctx.request?.ip || ctx.ip || 'unknown';
}

function ruleForPath(path) {
  if (DEFAULT_RULES[path]) {
    const base = DEFAULT_RULES[path];
    if (path === '/api/auth/local') {
      return {
        ...base,
        max: envPositiveInt('AUTH_RATE_LIMIT_LOGIN', base.max),
      };
    }
    if (path === '/api/auth/forgot-password') {
      return {
        ...base,
        max: envPositiveInt('AUTH_RATE_LIMIT_FORGOT', base.max),
      };
    }
    if (path.startsWith('/api/auth/') && (path.includes('apple') || path.includes('google'))) {
      return {
        ...base,
        max: envPositiveInt('AUTH_RATE_LIMIT_SSO', base.max),
      };
    }
    return base;
  }
  return null;
}

function checkRateLimit({ path, ip }) {
  const rule = ruleForPath(path);
  if (!rule) return { allowed: true };

  const key = `${path}:${ip}`;
  const now = Date.now();
  const current = buckets.get(key);

  if (!current || now >= current.resetAt) {
    buckets.set(key, { count: 1, resetAt: now + rule.windowMs });
    return { allowed: true, remaining: rule.max - 1 };
  }

  if (current.count >= rule.max) {
    return {
      allowed: false,
      retryAfterSec: Math.max(1, Math.ceil((current.resetAt - now) / 1000)),
    };
  }

  current.count += 1;
  buckets.set(key, current);
  return { allowed: true, remaining: rule.max - current.count };
}

function resetBucketsForTests() {
  buckets.clear();
}

module.exports = {
  DEFAULT_RULES,
  checkRateLimit,
  resolveClientIp,
  isDisabled,
  resetBucketsForTests,
};
