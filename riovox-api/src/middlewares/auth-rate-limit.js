'use strict';

const {
  checkRateLimit,
  resolveClientIp,
  isDisabled,
} = require('../utils/auth-rate-limit');

module.exports = () => {
  return async (ctx, next) => {
    if (isDisabled()) {
      return next();
    }

    if (ctx.request.method !== 'POST') {
      return next();
    }

    const path = ctx.request.path || ctx.path || '';
    if (!path.startsWith('/api/auth/')) {
      return next();
    }

    const ip = resolveClientIp(ctx);
    const result = checkRateLimit({ path, ip });

    if (!result.allowed) {
      ctx.status = 429;
      ctx.set('Retry-After', String(result.retryAfterSec ?? 60));
      ctx.body = {
        error: {
          status: 429,
          name: 'TooManyRequests',
          message: 'Too many authentication attempts. Please try again later.',
        },
      };
      return;
    }

    await next();
  };
};
