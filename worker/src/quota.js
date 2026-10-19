// Daily per-device quota backed by Cloudflare KV (optional; see wrangler.toml).
// The per-minute rate limiter stops bursts; this cap stops a single device from
// slowly draining the Gemini quota over a whole day.

import { ApiError, ErrorCode } from "./http.js";

const SECONDS_PER_DAY = 86_400;

/**
 * Throws 429 when the client has used up its daily allowance for [action].
 * KV counters are eventually consistent, so this is a soft cap by design;
 * a missing binding (local dev, or KV not set up yet) is logged and skipped.
 *
 * @param {object} args
 * @param {object|undefined} args.kv KV namespace binding (QUOTA_KV).
 * @param {string} args.action Route name used in the counter key, e.g. "scan".
 * @param {string} args.clientKey Stable per-device key from auth.clientKey.
 * @param {number} args.limit Allowed requests per UTC day; 0 disables the cap.
 * @param {Date} args.now Current time (injected for tests).
 * @param {ReturnType<import("./http.js").createLogger>} args.logger
 */
export async function enforceDailyQuota({ kv, action, clientKey, limit, now, logger }) {
  if (!kv || !(limit > 0)) return;

  const day = now.toISOString().slice(0, 10);
  const key = `quota:${action}:${clientKey}:${day}`;
  const used = Number(await kv.get(key)) || 0;

  if (used >= limit) {
    logger.warn("Daily quota exceeded.", { action, clientKey, used, limit });
    throw new ApiError(429, ErrorCode.QUOTA_EXCEEDED, "Daily limit reached. Try again tomorrow.", {
      retryable: true,
      retryAfterSeconds: secondsUntilNextUtcDay(now),
    });
  }

  // Counters expire on their own; two days covers clock skew around midnight.
  await kv.put(key, String(used + 1), { expirationTtl: 2 * SECONDS_PER_DAY });
}

/** Seconds from [now] until the next UTC midnight, when the counter resets. */
export function secondsUntilNextUtcDay(now) {
  const nextMidnight = Date.UTC(
    now.getUTCFullYear(),
    now.getUTCMonth(),
    now.getUTCDate() + 1,
  );
  return Math.max(1, Math.ceil((nextMidnight - now.getTime()) / 1000));
}
