// Fridgenie API Worker entry point: routing, auth, rate limiting and error handling.

import { API_VERSION, DAILY_QUOTA_DEFAULTS } from "./config.js";
import { assertAppToken, clientKey } from "./auth.js";
import { enforceDailyQuota } from "./quota.js";
import { handleRecipes } from "./handlers/recipes.js";
import { handleScan } from "./handlers/scan.js";
import {
  ApiError,
  ErrorCode,
  corsHeaders,
  createLogger,
  errorResponse,
  jsonResponse,
} from "./http.js";
import { enforceRateLimit } from "./rateLimit.js";

/**
 * Route table; `limiter` names the env binding used to rate-limit the route,
 * `quota` the action whose daily per-device cap applies (see quota.js).
 */
const ROUTES = Object.freeze({
  [`/${API_VERSION}/health`]: { method: "GET", isPublic: true, handler: () => ({ status: "ok" }) },
  [`/${API_VERSION}/scan`]: {
    method: "POST",
    limiter: "SCAN_RATE_LIMITER",
    quota: "scan",
    handler: handleScan,
  },
  [`/${API_VERSION}/recipes`]: {
    method: "POST",
    limiter: "RECIPE_RATE_LIMITER",
    quota: "recipes",
    handler: handleRecipes,
  },
});

/** Daily cap for a route: env var (DAILY_SCAN_QUOTA / DAILY_RECIPES_QUOTA) or default. */
function dailyLimitFor(env, action) {
  const override = Number(env[`DAILY_${action.toUpperCase()}_QUOTA`]);
  return Number.isFinite(override) ? override : DAILY_QUOTA_DEFAULTS[action];
}

export default {
  async fetch(request, env) {
    const requestId = request.headers.get("CF-Ray") ?? crypto.randomUUID();
    const logger = createLogger(requestId);
    const cors = corsHeaders(request, env);
    const path = new URL(request.url).pathname.replace(/\/+$/, "");
    const startedAt = Date.now();

    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: cors });
    }

    try {
      const route = ROUTES[path];
      if (!route) throw new ApiError(404, ErrorCode.NOT_FOUND, "Unknown endpoint.");
      if (request.method !== route.method) {
        throw new ApiError(405, ErrorCode.METHOD_NOT_ALLOWED, `Use ${route.method} for this endpoint.`);
      }

      if (!route.isPublic) {
        assertAppToken(request, env);
        const client = clientKey(request);
        await enforceRateLimit(env[route.limiter], client, logger);
        await enforceDailyQuota({
          kv: env.QUOTA_KV,
          action: route.quota,
          clientKey: client,
          limit: dailyLimitFor(env, route.quota),
          now: new Date(),
          logger,
        });
      }

      const body = await route.handler({ request, env, logger });
      logger.info("Request succeeded.", { path, ms: Date.now() - startedAt });
      return jsonResponse(body, { requestId, cors });
    } catch (error) {
      logRequestError(logger, error, path, startedAt);
      return errorResponse(error, { requestId, cors });
    }
  },
};

/** Client errors are warnings; server and upstream failures are errors with internal detail. */
function logRequestError(logger, error, path, startedAt) {
  const fields = { path, ms: Date.now() - startedAt };
  if (error instanceof ApiError) {
    const log = error.status >= 500 ? logger.error : logger.warn;
    log("Request failed.", { ...fields, status: error.status, code: error.code, detail: error.logDetail });
    return;
  }
  logger.error("Unhandled error.", { ...fields, error: String(error), stack: error?.stack });
}
