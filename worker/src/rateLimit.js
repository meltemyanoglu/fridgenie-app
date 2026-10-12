// Per-client rate limiting backed by Cloudflare's Rate Limiting bindings (see wrangler.toml).

import { ApiError, ErrorCode } from "./http.js";

/**
 * Throws 429 when the client exceeded the limiter's quota.
 * A missing binding (e.g. local dev without config) is logged and allowed through.
 */
export async function enforceRateLimit(limiter, key, logger) {
  if (!limiter) {
    logger.warn("Rate limiter binding missing; skipping check.");
    return;
  }
  const { success } = await limiter.limit({ key });
  if (!success) {
    logger.warn("Rate limit exceeded.", { key });
    throw new ApiError(429, ErrorCode.RATE_LIMITED, "Too many requests. Please wait a minute.", {
      retryable: true,
    });
  }
}
